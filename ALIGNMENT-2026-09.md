# Cross-port alignment, September 2026

The contract every port implements for three capabilities that first
appeared in mojentic-ex for Bedrock. Elixir is the reference where this
document is silent. Where Elixir falls short of this document, Elixir changes
too.

Background: `DIVERGENCE-2026-09-24.md`.

## Principle

Truncated or unfinished output is an error, never a result. The library
reports evidence and does not decide application policy: no automatic
continuation, no retry, no estimated usage.

The same rule already applies to `generate` in mojentic-ex (commit 12a2495):
any finish reason other than `stop` returns an incomplete-completion error.
Porting that to other ports' `generate` is **out of scope here**. It is a
separate, breaking decision tied to the next release version.

## 1. Structured output in streaming requests

`CompletionConfig` carries an optional response format:

| Value | Meaning |
| ----- | ------- |
| absent / null | Provider default. Request unchanged |
| text | Plain text |
| json object, no schema | JSON object mode |
| json object with schema | JSON schema mode with that schema |

Use the port's idiom for the type (Rust `Option<ResponseFormat>`, a sealed
type in Kotlin, an enum with an associated value in Swift, a Pydantic model or
union in Python, the existing `responseFormat` in TypeScript). Ports that
already have the field keep its shape.

Every gateway forwards the configured format in its **streaming** requests the
same way it does in non-streaming requests:

- OpenAI-compatible: `response_format: {type: "json_object"}`, or
  `{type: "json_schema", json_schema: {name: "response", schema: <schema>}}`,
  or `{type: "text"}`.
- Ollama: `format: "json"`, or `format: <schema>`. Omit it for text.

This records what was requested. It is not proof that the provider enforced
it. Document that callers still validate content.

Tests: for each gateway, a streaming request with each format value produces
the expected request body; absent config leaves the body unchanged.

## 2. Provider evidence in response traces

The LLM response tracer event gains four optional fields:

| Field | Source | When absent |
| ----- | ------ | ----------- |
| usage | gateway response usage exactly as reported | null |
| provider_model | model name the provider reported | null |
| finish_reason | provider finish reason | null |
| metadata | gateway response metadata map | null or empty |

Rules:

- The existing `model` field stays the configured request model.
- Populate the fields for ordinary, structured, and streaming responses,
  including the single-turn events API in section 3.
- Never estimate usage from text length or a tokenizer. Unknown stays unknown.
- Gateway response types must carry these fields. Add any that are missing,
  and have each gateway fill what its provider reports. OpenAI streaming
  requests set `stream_options: {include_usage: true}` so usage is reported.

Tests: a broker call records a response event that carries gateway-reported
usage, provider model, finish reason and metadata unchanged; a gateway that
reports no usage produces an event with null usage.

## 3. Single-turn streaming with terminal completion evidence

A broker method yielding a stream of events for one turn:

| Port | Name |
| ---- | ---- |
| Elixir | `Broker.generate_stream_events/3` (exists) |
| Python | `generate_stream_events` |
| Rust | `generate_stream_events` |
| TypeScript | `generateStreamEvents` |
| Swift | `generateStreamEvents` |
| Kotlin | `generateStreamEvents` |

Inputs: messages and an optional config. No tools parameter.

Events, in the port's idiom (tagged tuple, enum, sealed type, discriminated
union):

- `content(text)`: visible assistant content, in order.
- `completed(metadata)`: terminal success. Metadata holds finish reason,
  usage (nullable), and provider model (nullable).
- `error(reason)`: terminal failure.

Exactly one terminal event ends every stream. Nothing follows it.

Completion rules:

- OpenAI-compatible: success requires a `finish_reason` of `stop` **and** the
  `data: [DONE]` marker. `[DONE]` with any other finish reason is an
  incomplete-completion error carrying finish reason, usage and model.
- Ollama: success requires a final frame with `done: true` and a
  `done_reason` of `stop`. Any other `done_reason` is an incomplete-completion
  error with the same evidence.
- End of stream without a terminal marker is an incomplete-stream error.
- A provider error frame is a provider error.
- A native tool call in the stream is an unexpected-tool-calls error. The API
  supplies no tools and executes none.
- Malformed frames are an invalid-stream-event error.
- Content already yielded before an error is evidence, not a result. Say so in
  the docs.

Behaviour rules:

- Force tool iterations to zero. No retry. No recursion.
- One HTTP request. Stopping consumption (dropping the stream, breaking the
  loop, cancelling the task or coroutine) cancels that request.
- A gateway that does not support this API fails with a
  stream-events-unsupported error before sending any request.
- Record the LLM call in the tracer when the request starts. Record the
  response (content so far, plus the section 2 evidence fields) when the
  stream reaches its terminal event, success or failure.
- Supported gateways: OpenAI and Ollama in every port, **including Elixir**,
  which today has OpenAI only. Other gateways (Anthropic) report unsupported.

Existing streaming APIs keep their current behaviour. Rust's
`StreamChunk::Progress`, `Metrics` and thinking chunks stay as they are; the
adaptive-harness schema pass will reconcile them later.

Tests: at minimum, per supported gateway, with a fake transport:

1. Content then stop then terminal marker yields content events then completed.
2. Terminal marker with finish reason `length` yields an incomplete-completion
   error carrying finish reason and usage.
3. End of stream without a terminal marker yields an incomplete-stream error.
4. A tool-call delta yields an unexpected-tool-calls error.
5. A provider error frame yields a provider error.
6. Stopping consumption early cancels the request.
7. An unsupported gateway errors without a request.
8. The tracer records call and response, with usage when reported.

## Done means

- Full quality gate green for the port (format, lint, tests, type checks,
  security audit as the port defines it).
- CHANGELOG `Unreleased` entries for each capability.
- Docs: a section for each capability in the port's broker or streaming guide,
  using the names in this document.
- Commits on `main`, pushed. One commit per capability is preferred.

## Clarifications, 2026-09-24

Raised by the Elixir alignment pass. These bind every port.

1. **"Streaming" in section 2 means the section 3 events API.** Legacy
   streaming APIs keep their current behaviour, including whether they trace
   at all. Do not add `include_usage` to a legacy stream that cannot hand
   usage back.
2. **Terminal event metadata carries provider metadata.** `completed` and the
   incomplete-completion error hold finish reason, usage, provider model,
   **and** a nullable provider metadata map (for example Ollama's
   `total_duration`, `load_duration`, `prompt_eval_duration`,
   `eval_duration`). The stream trace records that map as its `metadata`.
3. **Usage shape.** The trace carries the usage value the port's gateway
   response already holds, unchanged. Do not introduce a new normalization in
   this pass. A cross-port usage shape is deferred to the adaptive-harness
   schema work, where it belongs.
4. **Error naming.** Ports keep their own idiom. The incomplete-completion
   error from the events API carries the evidence (finish reason, usage,
   model, metadata). Aligning `generate`'s incomplete-completion shape with it
   is part of the deferred release decision.
5. **Invalid content.** A content delta that is not a string may use a finer
   `invalid_stream_content` reason where the port already distinguishes it.
   Otherwise use `invalid_stream_event`.
6. **Structured output truncation** (`generate_object` accepting a truncated
   response that happens to parse) is out of scope here. It goes with the
   `generate` finish-reason decision.
