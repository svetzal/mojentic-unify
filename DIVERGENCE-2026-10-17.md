# Port divergence report, 2026-10-17

How the six ports map reasoning controls to providers at the end of 3.0.0
work, and the rule 3.1 aligns them on. This is a dated audit and is not updated
after today. `PARITY.md` tracks the fix.

Method: a read-only survey of each port's `origin/main` (ex 491d1f6, py
27a2dbc, ru 2d17022, ts e784669, sw 63cf064, kt 2293710), checked against
OpenAI's and Anthropic's API documentation on 2026-10-17. TypeScript was
mid-cycle on part 2, so its row may change before 3.0.0 ships.

## Decision

Stacey, 2026-10-17: every port must behave the same way, because that is the
point of having ports. 3.0.0 is blocking other work, so it ships with the
divergences below, and 3.1 aligns every port on the rule in the last section.

For the two questions that were open in 3.0:

- **OpenAI and Disabled (TypeScript).** Follow the majority of ports: fail
  before dispatch for Disabled, Enabled and XHigh on OpenAI. Rust's silent
  omission stays a known divergence until 3.1.
- **Anthropic `tool_use` timing (Swift).** Follow Kotlin, the only port that
  times Anthropic streams. The `input: {}` in `content_block_start` is not a
  token. The first non-empty `input_json_delta` fragment starts the `tool_call`
  clock. A zero-argument tool that sends no fragment leaves the first-token
  fields absent. That zero-argument gap is a 3.1 item.

## Divergences shipped in 3.0.0

### OpenAI

| Port | Disabled | Enabled | Low, Medium, High | XHigh |
| ---- | -------- | ------- | ----------------- | ----- |
| Elixir, Python, Swift, Kotlin | error | error | sent | error |
| Rust | omitted without error | error | sent | `xhigh` |
| TypeScript | error (decided above) | error | sent | error |

Rust's omission means a caller who asks for no reasoning gets the model's
default, which is `medium` on current OpenAI models.

Every port sends `reasoning_effort` only when its model registry marks the
model as a reasoning model, and drops it with a warning otherwise. For unknown
models the registries guess from the name: `o1`, `o3` and `o4` prefixes, plus
`gpt-5` in Rust and a substring table in Kotlin.

Elixir, Python and Swift reject a reasoning profile on OpenAI. Rust and Kotlin
validate the effort against the profile and continue.

### Anthropic

Elixir, Rust and TypeScript have no Anthropic gateway.

| Port | Disabled, Enabled, XHigh | Low, Medium, High |
| ---- | ------------------------ | ----------------- |
| Python | warns and omits (silently on the recovery path) | warns and omits |
| Swift | error | `thinking: {type: "enabled", budget_tokens: max(1024, max_tokens/4)}`, the same for all three levels |
| Kotlin | error | warns and omits |

Swift's `budget_tokens` mode is deprecated on Claude 4.6 models and rejected
with a 400 by Claude 4.7 and later.

First-token timing for Anthropic streams exists only in Kotlin (and in Swift
once its 3.0 cycle lands, following the rule above). Python does not stream
Anthropic.

### Ollama and oMLX

All ports map Ollama and oMLX as `REASONING-PROTOTYPE-2026-10.md` specifies,
except:

- **Swift, oMLX:** `enable_thinking` goes inside `chat_template_kwargs`. The
  other ports put it at the top level of the request.
- **TypeScript:** on main before its part 2 cycle, Ollama sent `think: true`
  for every level and oMLX never sent `enable_thinking`. Its 3.0 part 2 work
  replaces both; confirm when it lands.

## The 3.1 rule: native or nothing

1. Each control maps to the provider's native equivalent.
   - OpenAI: Disabled sends `reasoning_effort: "none"`; Low, Medium, High and
     XHigh send `low`, `medium`, `high` and `xhigh`.
   - Anthropic: Disabled sends `thinking: {type: "disabled"}`; Enabled sends
     `thinking: {type: "adaptive"}`; the named levels send
     `output_config.effort` with the same name.
   - Ollama and oMLX: as `REASONING-PROTOTYPE-2026-10.md` specifies, with
     `enable_thinking` at the top level for oMLX.
2. When a provider has no native equivalent, the gateway fails before
   dispatch. OpenAI has no plain Enabled.
3. A gateway never omits a control, substitutes another, or guesses support
   from a model name. Whether a model supports a value is the provider's to
   enforce; its HTTP 400 returns as the gateway's typed error. This removes the
   name-based reasoning-model fallback in every OpenAI registry.

Why: support varies by model and changes monthly. OpenAI accepts `none` on the
GPT-5.2 and later families but not on GPT-5, the o-series, GPT-6 Astra or
GPT-6.1 Sol. Anthropic's Haiku 5.5 accepts `thinking: {type: "disabled"}` at
`high` effort or below, Sonnet 5.5 uses `between_tools` instead, and Opus 5.5
cannot disable thinking at all. A per-model table in six ports would be wrong
within a quarter. The rule also matches part 3 of 3.0 (send only what the
caller set) and the reasoning contract (profiles are never guessed from a
model-name fragment).

3.1 also settles Anthropic timing for a zero-argument tool call. The proposal:
the call counts as the first token when its block completes, so a stream that
produced a tool call always reports a first token.

## 3.1 work by port

| Port | Work |
| ---- | ---- |
| Elixir | OpenAI Disabled and XHigh to native; drop name guessing |
| Python | OpenAI Disabled and XHigh to native; drop name guessing; Anthropic mapping and streaming timing |
| Rust | OpenAI Disabled to `none` instead of omission; drop name guessing |
| TypeScript | OpenAI Disabled and XHigh to native; drop name guessing |
| Swift | OpenAI Disabled and XHigh to native; drop name guessing; Anthropic mapping off `budget_tokens`; oMLX `enable_thinking` to the top level |
| Kotlin | OpenAI Disabled and XHigh to native; drop name guessing; Anthropic mapping |

Elixir has no Anthropic gateway. Adding one is a separate parity question, not
part of this alignment.
