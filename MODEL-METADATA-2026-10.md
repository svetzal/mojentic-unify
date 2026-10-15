# Model metadata and first-token timing, October 2026

Status: draft for Stacey's review. Not yet scheduled for a release.

The contract every port implements for two gateway capabilities:

1. Ask the provider how large a model's context window is.
2. Report time to first token, and what that token was, for every streamed
   completion.

Elixir implements it first and is the reference where this document is silent.
The other ports follow in the same minor release, so the same version means the
same features everywhere. The latest coordinated release is 2.1.0; this
belongs in the next minor.

Both capabilities are primitives in the sense of
`ADAPTIVE-HARNESS-ENHANCEMENTS.md`: Mojentic reports what the provider says
and what the stream did. What an application does with a window size or a
latency (budgets, pressure bands, ejection, retries) stays policy and stays in
the application.

## Origin and evidence

Microgentic, the small-model coding agent built on `mojentic-ru`, needed both
for its context residency work. It built them as two local modules shaped like
gateway methods, so that they can be deleted once Mojentic provides them:

- `src/model_metadata.rs`: the provider query for a model's context window.
- `src/first_token.rs`: the clock around a stream.

Microgentic commit `746bebe` (2026-10-15) has both, with unit tests and a live
check recorded in its `RESIDENCY-MEASUREMENT-2026-10.md`. The behaviour below
is what the servers did on that date, not what their documentation says:

- oMLX: `fixtures/omlx/models.json` (captured 2026-09-29) already carries
  `max_model_len`. A capture on 2026-10-15 from the same server returned
  `max_model_len: 262144` for `Qwen3.8-27B-MLX-8bit` and `Qwen3.8-27B-oQ4e-mtp`.
- Ollama 0.40.5: `fixtures/ollama/` (captured 2026-10-15) has `/api/show`
  responses for a model without a `num_ctx` parameter, a model with one, and
  an unknown model.

## 1. Context window from the provider

### Interface

Add one gateway operation that returns the context window a provider
advertises for a model, without changing anything about later requests.

| Port | Name |
| ---- | ---- |
| Elixir | optional callback `get_model_context_window(model)` on `Mojentic.LLM.Gateway` |
| Python | `get_model_context_window(model)` |
| Rust | `async fn get_model_context_window(&self, model: &str)` on the gateway trait |
| TypeScript | `getModelContextWindow(model)` |
| Swift, Kotlin | `modelContextWindow(model:)`, `modelContextWindow(model)` |

The result has three shapes:

- **A window:** `max_context_tokens` (a positive integer) and `field`, the
  provider field it came from, for example `"max_model_len"` or
  `"model_info.qwen3_5.context_length"`. The name `max_context_tokens` matches
  the existing OpenAI model registry.
- **Not advertised:** the provider answered but gives no window for this model
  (Elixir `{:ok, nil}`, Rust `Ok(None)`, and so on).
- **An error:** the provider could not be asked, answered with a non-2xx
  status, or answered with a malformed body. Use the port's existing error
  idiom.

A gateway that has no way to know returns "not advertised". It does not guess.
In Elixir the callback is optional; a gateway that does not implement it is
treated as returning `{:ok, nil}`.

### Per provider

**oMLX.** `GET /v1/models`, with the gateway's configured host and API key.
Find the entry whose `id` equals the model. Its `max_model_len` is the window,
with `field` `"max_model_len"`. No entry, or an entry without the field, is "not
advertised". A field that is not a positive integer is an error.

**Ollama.** `POST /api/show` with `{"model": model}`. Read
`model_info.<arch>.context_length`, matching any key that ends in
`.context_length`, because the architecture prefix varies (`qwen3_5`,
`qwen4_exp` in the fixtures). `field` is `"model_info."` plus the matched key.
A missing `model_info`, or no matching key, is "not advertised". A value that
is not a positive integer is an error. HTTP 404 (unknown model) is an error.

The `parameters` text can also hold a `num_ctx` line
(`show_num_ctx_parameter.json`). Mojentic ignores it here: every Mojentic
Ollama request sends `options.num_ctx` from `CompletionConfig` (32,768 by
default), which overrides the model's parameter. The line only matters to
clients that omit `num_ctx`.

**OpenAI.** Return the model registry's `max_context_tokens` with `field`
`"registry"`, without a request. A model the registry does not know is "not
advertised".

**Other gateways.** Return "not advertised" until a provider capture shows
where the value lives.

### The window a request runs at (Ollama)

The advertised window is not always the window a request runs at. Ollama runs
a request at the `num_ctx` it receives. Through Mojentic that is always
`config.num_ctx`. In microgentic's live check, Ollama advertised 262,144 while
every request ran at 32,768. An application that accounted against the
advertised figure understated context pressure eightfold.

So the Ollama gateway also exposes a pure helper with no request:

- `effective_context_window(advertised, config)` returns
  `min(advertised, config.num_ctx)`, or `config.num_ctx` when nothing is
  advertised.

Other gateways' requests do not set a context size, so their effective window
is the advertised one. Ports may expose the helper on every gateway with that
behaviour, so applications call it without a provider check.

### Rules

- **Report, never adjust.** Asking for the window changes no later request.
  It never sets `num_ctx`, `max_tokens`, or any other parameter. A larger
  `num_ctx` makes Ollama allocate a larger cache, so applications must choose
  that deliberately.
- **No caching in the gateway.** Each call asks the provider. Whether and how
  long to cache is the application's choice.
- **Timeouts.** Use the gateway's configured timeout unless the caller passes a
  shorter one through the port's usual mechanism. Applications usually want a
  short bound (microgentic uses 2 seconds) so that discovery never delays a run.
- **Authentication** follows the gateway's existing configuration (oMLX sends
  `Authorization: Bearer <key>` only when a key is configured).

## 2. First-token timing in stream metrics

This amends section 4 of `ADAPTIVE-HARNESS-ENHANCEMENTS.md`, "Provider stream
progress and metrics". Provider-reported durations (Ollama's
`prompt_eval_duration` and the others listed there) stay as they are. The
fields below are measured by the client, so they exist for every provider,
including ones that report no timing at all.

For every streamed completion, the terminal evidence carries:

| Field | Meaning |
| ----- | ------- |
| `time_to_first_token_ms` | Milliseconds from sending the request to the first streamed token of any kind. Absent or null when the stream produced no token. |
| `first_token_kind` | `content`, `thinking`, or `tool_call`: the kind of that first token. Absent or null with the field above. |
| `request_duration_ms` | Milliseconds from sending the request to the terminal event, on success and on failure. |

In Elixir these go in the `metadata` of `{:completed, evidence}`, and in the
error evidence where a stream ends with an error after tokens arrived. Other
ports put them wherever their terminal stream event or response metadata
already carries provider metrics.

Rules:

- **The clock starts when the request is sent**, not when the stream is
  constructed. Use a monotonic clock.
- **Only the first token counts.** Keep-alive frames (oMLX's first frame with
  `model: "keepalive"`) and frames with no content, thinking, or tool-call delta
  are not tokens.
- **Thinking counts.** A reasoning model's first token is usually thinking; the
  live check saw thinking first in every trial. Applications that want time to
  visible output can measure it themselves from the content events.
- **Tool-call arguments count** from the first argument fragment, not from the
  completed call.
- **Non-streamed completions** may report `request_duration_ms` alone.

Observed in microgentic's live check, for scale: oMLX `Qwen3.8-27B-oQ4e-mtp`
took 8.9 to 14.3 seconds to its first (thinking) token; Ollama
`qwen3.8:27b-mlx` took 80 to 108 ms on a warm model. Four trials are not a
measurement; they show the field is worth having.

## 3. Acceptance criteria, per port

- **Context window:** tests from the fixtures for an oMLX window, an oMLX model
  missing from the list, an oMLX entry without the field, a non-numeric value,
  an Ollama window under each architecture prefix, an Ollama answer with no
  `model_info`, an Ollama 404, and the OpenAI registry path.
- **No side effects:** a test shows that asking for the window leaves the next
  completion request byte-identical to one made without asking.
- **Effective window:** tests for Ollama with advertised above, below, and
  equal to `config.num_ctx`, and with nothing advertised.
- **First-token timing:** tests for content-first, thinking-first, and
  tool-call-first streams, a keep-alive frame before the first token, an empty
  stream, and a stream that fails after its first token. Use an injectable or
  fake clock rather than sleeps.
- **Docs:** a section for each capability in the port's gateway or streaming
  guide.
- **Records:** CHANGELOG `Unreleased` entries for each capability, and a
  `PARITY.md` row for each.
- **Commits:** on `main`, pushed, one commit per capability preferred, and no
  commit that touches more than one port.

## 4. After it ships

Microgentic moves its pinned `mojentic-ru` revision to the release, switches to
these operations, and deletes `src/model_metadata.rs` and `src/first_token.rs`
in a commit of its own. Its fallback order, accounting, and tracing stay where
they are.

## Open questions

1. **Name and shape.** Is a single-purpose `get_model_context_window` right, or
   should this be the first field of a broader `get_model_info` that can later
   carry tool, vision, and reasoning capabilities? I lean towards the
   single-purpose call: the reasoning work in `REASONING-PROTOTYPE-2026-10.md`
   already has its own model profiles, and a broad struct invites guessing at
   fields no provider reports.
2. **Release.** Does this go into the next minor on its own, or wait for other
   work planned for that minor?
