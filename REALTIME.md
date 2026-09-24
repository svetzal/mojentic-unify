# Realtime Voice — Design Plan

**Status:** Draft / collaboration document
**Target:** Mojentic 2.0 (next major)
**Primary port:** TypeScript (`mojentic-ts`), then port to py/ex/ru
**Last updated:** 2026-05-17

This document plans out a new top-level capability in Mojentic: **realtime
voice interaction with parallel tool calling**, exposed through a
`RealtimeVoiceBroker` that sits beside `LlmBroker`. The first implementation
targets OpenAI's Realtime API. The work also surfaces a base-library gap —
**parallel tool execution** — which we will address along the way.

---

## 1. Background: What OpenAI Realtime Actually Is

OpenAI's Realtime API is **not** request/response. It is a **persistent,
bidirectional, event-driven session** carrying audio + text + tool calls,
typically over **WebSocket** (server-to-server / Node) or **WebRTC**
(browser, mic/speaker direct). For Mojentic-ts our home is Node, so we plan
on **WebSocket as the primary transport**.

### 1.1 Mental model

- One **session** = one open socket. The session is configured once with
  voice, instructions, tools, turn detection, audio formats.
- Inside the session there is one rolling **conversation** of *items*
  (messages, function calls, function outputs).
- The model produces **responses**. A response can contain multiple
  **output items** — text, audio, AND function_call items — *in parallel*,
  in a single response turn. This is the native parallel-tool model.
- The client and server exchange typed **events**.

### 1.2 Event vocabulary (the slice we care about)

**Client → Server**

| Event | Purpose |
|---|---|
| `session.update` | Set/replace session config (voice, tools, turn detection, formats, instructions). |
| `input_audio_buffer.append` | Stream microphone audio (base64 pcm16) into the server VAD buffer. |
| `input_audio_buffer.commit` | Manually end a user turn (only when `turn_detection: none`). |
| `conversation.item.create` | Insert an item — used for text user messages, and crucially for `function_call_output` (tool results). |
| `response.create` | Ask the model to produce the next response. May be omitted under server VAD. |
| `response.cancel` | Cancel an in-flight response (used for interruption / barge-in). |

**Server → Client (the ones we actually consume)**

| Event | Purpose |
|---|---|
| `session.created` / `session.updated` | Lifecycle. |
| `input_audio_buffer.speech_started` / `speech_stopped` | Server VAD detected user start/stop — used to drive interruption. |
| `conversation.item.input_audio_transcription.completed` | Final transcript of what the user said. |
| `response.created` | A new response turn has begun. |
| `response.output_item.added` / `response.output_item.done` | A specific output item (text, audio, function_call) starts/ends. **A single response can add several function_call items — this is parallel tool calling.** |
| `response.audio.delta` | Streaming base64 pcm16 audio chunks for playback. |
| `response.audio_transcript.delta` | Streaming transcript of the assistant's voice. |
| `response.text.delta` | Streaming text (when modality includes text). |
| `response.function_call_arguments.delta` | Streaming JSON arguments for an in-progress function call. |
| `response.done` | Response turn ended; full set of output items is now known. |
| `rate_limits.updated` | Backpressure signal. |
| `error` | Anything went wrong. |

### 1.3 Audio + turn detection

- Default audio format: **pcm16 mono @ 24 kHz**, base64-framed. (g711 ulaw/alaw available for telephony.)
- Two turn-detection modes:
  - `server_vad` — server decides when the user stopped talking and auto-fires a `response.create`. This is the natural "phone call" mode.
  - `none` — client decides when to commit the buffer and request a response. Useful for push-to-talk and tests.
- **Interruption / barge-in:** when the server fires `speech_started` mid-assistant-response, we cancel the in-flight response (`response.cancel`) and truncate locally played audio to keep the conversation honest.

### 1.4 Function calling, and the parallel part

The Realtime function-calling flow:

1. Server emits one or more `response.output_item.added` events of type `function_call` *during a single response*. Each gets `response.function_call_arguments.delta` chunks, then `response.output_item.done`.
2. We may have **N concurrent in-flight function calls** by the time `response.done` lands.
3. For each, the client must send a `conversation.item.create` with type `function_call_output`, carrying that call's `call_id` and the JSON result.
4. After all N outputs are submitted, the client sends `response.create` to let the model continue (often producing the spoken summary).

The key shift versus chat completions: **the model doesn't wait** to batch tool calls into one assistant turn. It can begin speaking while still emitting tool calls, and we can be executing tools while it speaks. This is what we want to model first-class.

---

## 2. Where this fits in Mojentic

Today (Layer 1):

```
LlmBroker  ── uses ──>  LlmGateway  ── implements ──>  OpenAIGateway / OllamaGateway
   │
   └── tools: LlmTool[]   (recursive, serial execution)
```

Proposed addition:

```
RealtimeVoiceBroker  ── uses ──>  RealtimeVoiceGateway  ── implements ──>  OpenAIRealtimeGateway
   │
   ├── tools: LlmTool[]            (parallel execution — reuses existing LlmTool!)
   ├── audio I/O (AsyncIterables of PCM frames)
   ├── event stream (typed RealtimeEvent union)
   └── session config (voice, vad, instructions, modalities)
```

**Deliberate reuses:**

- `LlmTool` interface stays as-is. Tools written for `LlmBroker` work in `RealtimeVoiceBroker` unchanged.
- `TracerSystem` stays as-is; we add new event kinds (audio in/out durations, voice turn, parallel-tool batch). Correlation IDs propagate.
- `Result<T, E>` error pattern stays as-is.
- `LlmMessage` is **not** the right shape for a realtime session (no "items" concept, no audio). We introduce a small `RealtimeItem` model so we don't bend `LlmMessage` out of shape.

**Deliberate separations:**

- `RealtimeVoiceBroker` is **not** a subclass of `LlmBroker`. It has different lifecycles (long-lived session vs one-shot generate), different I/O (audio streams vs strings), and different concurrency (parallel vs serial). Composition + a sibling, not inheritance.
- Realtime is **not** exposed via `LlmGateway`. Forcing a sync-call interface around a duplex session creates leaky abstractions. We make a sibling gateway protocol.

---

## 3. Developer-facing API (TypeScript, proposed)

### 3.1 The 30-second example

```typescript
import {
  OpenAIRealtimeGateway,
  RealtimeVoiceBroker,
  CurrentDateTimeTool,
  WebSearchTool,
} from 'mojentic';
import { micStream, speakerSink } from './audio-helpers'; // user-provided

const gateway = new OpenAIRealtimeGateway({ apiKey: process.env.OPENAI_API_KEY! });

const broker = new RealtimeVoiceBroker('gpt-realtime', gateway, {
  instructions: 'You are a helpful, concise assistant.',
  voice: 'verse',
  turnDetection: 'server_vad',
  tools: [new CurrentDateTimeTool(), new WebSearchTool()],
});

await using session = await broker.connect();   // <- ergonomic, see §3.4

// Pipe mic in, speaker out.
session.sendAudio(micStream());
for await (const audio of session.audioOutput()) {
  speakerSink.write(audio);   // raw pcm16 24kHz
}
```

Notes:

- `connect()` returns a `RealtimeSession` handle. The broker is reusable across sessions; the session owns the socket.
- `sendAudio` takes an `AsyncIterable<Int16Array>` (or `Uint8Array` PCM frames). The gateway handles base64 framing.
- `audioOutput()` is an async generator yielding PCM frames as they arrive from the server.
- Tools fire automatically and **in parallel**. The user code doesn't have to think about it.

### 3.2 Observing events (when you want more control)

```typescript
for await (const event of session.events()) {
  switch (event.kind) {
    case 'user_transcript':       console.log('🧑', event.text); break;
    case 'assistant_transcript':  process.stdout.write(event.delta); break;
    case 'tool_call_started':     console.log('🔧', event.name, event.args); break;
    case 'tool_call_completed':   console.log('✅', event.name, event.result); break;
    case 'response_completed':    /* turn ended */ break;
    case 'interrupted':           /* barge-in */ break;
    case 'error':                 console.error(event.error); break;
  }
}
```

We expose a **Mojentic-shaped event union**, not the raw OpenAI event stream. The raw stream is still available via `session.rawEvents()` for power users / debugging, but our normalized events are what travel through ports.

### 3.3 Text-mode realtime (no audio)

```typescript
const session = await broker.connect({ modalities: ['text'] });
await session.sendText('Find me a recipe for sourdough and convert the flour to grams.');
for await (const e of session.events()) { /* ... */ }
```

This is useful because it lets us write deterministic tests that exercise the parallel-tool path without an audio pipeline. (See §6.)

### 3.4 Lifecycle & resource safety

We will use TypeScript's `using` / `Symbol.asyncDispose` for `RealtimeSession`. Connection state lives in the session, not the broker; closing the session closes the socket and drains generators. This is consistent with our trunk-based "no hidden lifecycles" preference.

Sessions also expose:
- `session.interrupt()` — manual barge-in.
- `session.updateInstructions(text)` — hot-update during a session.
- `session.close()` / `session[Symbol.asyncDispose]()`.

### 3.5 Configuration object

```typescript
interface RealtimeVoiceConfig {
  instructions?: string;
  voice?: 'alloy' | 'verse' | 'shimmer' | string;
  modalities?: ('audio' | 'text')[];   // default: ['audio', 'text']
  inputAudioFormat?: 'pcm16' | 'g711_ulaw' | 'g711_alaw';   // default: pcm16
  outputAudioFormat?: 'pcm16' | 'g711_ulaw' | 'g711_alaw';
  turnDetection?: 'server_vad' | 'none' | ServerVadConfig;
  inputAudioTranscription?: { model: 'whisper-1' } | false;
  tools?: LlmTool[];
  toolChoice?: 'auto' | 'none' | 'required' | { name: string };
  temperature?: number;
  maxResponseOutputTokens?: number;
}
```

We deliberately surface a **subset** of OpenAI's realtime config — what crosses cleanly to other ports. Provider-specific knobs go through an escape hatch (`providerExtras`).

---

## 4. The Gateway

```typescript
export interface RealtimeVoiceGateway {
  /** Open a duplex session. The returned handle is the only stateful surface. */
  open(
    model: string,
    config: RealtimeVoiceConfig,
    correlationId?: string,
  ): Promise<Result<RealtimeGatewaySession, Error>>;
}

export interface RealtimeGatewaySession extends AsyncDisposable {
  sendEvent(event: ClientRealtimeEvent): Promise<Result<void, Error>>;
  events(): AsyncGenerator<ServerRealtimeEvent>;
  close(): Promise<void>;
}
```

The gateway is intentionally **thin**:
- It owns the WebSocket and base64 framing.
- It validates events at the boundary using Zod (TS), Pydantic (py), structs+pattern-match (ex), serde (ru).
- It does **no** orchestration, no parallel-tool logic, no audio decoding.

`RealtimeVoiceBroker` is the imperative shell that:
1. Sends `session.update` derived from `RealtimeVoiceConfig`.
2. Pumps user audio in.
3. Demultiplexes server events into the normalized event union AND into per-call tool execution.
4. Executes tools (potentially in parallel), and sends `function_call_output` items back.
5. Issues `response.create` once all outputs for a batch are submitted.

---

## 5. Parallel tool calling — the bigger payoff

Implementing realtime forces us to confront parallel tools properly. We should not invent a one-off parallel scheduler buried inside `RealtimeVoiceBroker`; we should lift the abstraction so `LlmBroker` benefits too.

### 5.1 Where the base library is today

`LlmBroker.generate()` (broker.ts:138) iterates tool calls **serially** with `for (const toolCall of response.toolCalls) { ... await tool.run(args) ... }`. The Chat Completions API already returns multiple tool calls in a single assistant turn — we're just executing them one after another. That's an unforced limitation.

### 5.2 Proposed `ToolRunner` abstraction

Introduce a small new module:

```typescript
// src/llm/tools/runner.ts

export interface ToolRunner {
  /**
   * Execute a batch of tool calls. Implementations decide
   * concurrency / ordering / cancellation semantics.
   * Output order matches input order so the caller can pair
   * results with calls deterministically.
   */
  runBatch(
    calls: ToolCallExecution[],
    tools: LlmTool[],
    correlationId?: string,
  ): Promise<ToolCallOutcome[]>;
}

export interface ToolCallExecution {
  id: string;
  name: string;
  args: ToolArgs;
}

export type ToolCallOutcome =
  | { id: string; name: string; ok: true;  result: ToolResult }
  | { id: string; name: string; ok: false; error: Error };
```

Two stock implementations ship in 2.0:

| Runner | Behaviour | Use case |
|---|---|---|
| `SerialToolRunner` | Awaits each call in order. | Default for `LlmBroker` for backward-compat; debugging. |
| `ParallelToolRunner` | `Promise.allSettled` with optional `maxConcurrency`. | Default for `RealtimeVoiceBroker`; opt-in for `LlmBroker`. |

`LlmBroker` and `RealtimeVoiceBroker` both take an optional `toolRunner` constructor arg. The broker's job becomes "given this batch of calls, hand to the runner, then handle the outcomes" — independent of where the calls came from.

### 5.3 Why this is the right shape

- It pulls knowledge duplication (Simple Design heuristic #3) out of two brokers that would otherwise both grow concurrency code.
- It keeps tools themselves pure of concurrency concerns — `LlmTool.run` stays unchanged.
- It composes: a future `RateLimitedParallelRunner` or `TracingRunner` decorator costs nothing extra.
- It ports cleanly: Elixir gets `Task.async_stream`-backed runner, Rust gets `tokio::join_all`-backed runner, Python gets `asyncio.gather`-backed runner.

### 5.4 Tracer impact

A new tracer event type:

```typescript
recordToolBatch(
  batchId: string,
  calls: ToolCallExecution[],
  outcomes: ToolCallOutcome[],
  durationMs: number,
  correlationId: string,
  source: string,
)
```

Per-call `recordToolCall` events are still emitted by the runner so we don't lose granular visibility. The batch event lets us measure parallelism gains.

---

## 6. Testing strategy

We don't want test runs to require a real OpenAI socket. Three layers:

1. **Unit tests for the gateway** — Mock `WebSocket`. Verify event framing/parsing round-trips. Validate Zod schemas reject malformed events.
2. **Unit tests for the broker** — Mock `RealtimeVoiceGateway` with a hand-rolled `RealtimeGatewaySession` that replays a scripted event sequence. Verify:
   - Parallel tool calls are dispatched concurrently (assert tool `run` start times overlap).
   - All `function_call_output` items are sent before `response.create`.
   - Interruption: `speech_started` mid-response triggers `response.cancel`.
   - Normalized events fire in the right order.
3. **Live smoke example** (under `examples/realtime/`, gated by `OPENAI_API_KEY`) — connects, plays a short prompt, exercises a single tool. Not in CI quality gate; documented as a manual gate.

A `FileRealtimeGateway` (analog to the Python File Gateway) can replay a recorded event log. This is the **gold path for porting** — same fixture file feeds tests in py/ex/ru once written.

---

## 7. Examples we'll ship in 2.0

Under `mojentic-ts/examples/realtime/`:

| Example | Demonstrates |
|---|---|
| `realtime_simple_voice.ts` | Mic-in, speaker-out, no tools. The hello world. |
| `realtime_text_mode.ts` | Text-only realtime — no audio device required, runs anywhere. |
| `realtime_with_tools.ts` | One tool (DateResolver). The "tool calling works" example. |
| `realtime_parallel_tools.ts` | A prompt that triggers 3+ concurrent tool calls. Shows the speed-up vs serial. |
| `realtime_interruption.ts` | Barge-in: user starts speaking while assistant is mid-sentence. |
| `realtime_push_to_talk.ts` | `turn_detection: none`, manual commit. Good for CLI demos. |

Plus, **non-realtime** in the same release:

| Example | Demonstrates |
|---|---|
| `parallel_tool_calls.ts` | `LlmBroker` with `ParallelToolRunner` on chat completions — the base-library payoff from §5. |

---

## 8. Implementation phases (TS first)

Each phase is shippable on `main` (trunk-based).

**Phase 0 — Foundations (2.0-shaped, behaviour-preserving where it must be)**
- Evolve `ToolDescriptor` to a discriminated union (see §9.4). Gateway adapters translate at the boundary. Existing tool subclasses get a one-time mechanical update.
- Evolve `LlmTool.run(args, ctx?: { signal?: AbortSignal })`. Default `ctx` is `{}` — tools that ignore the signal continue to work.
- Add `ToolRunner` interface + `SerialToolRunner` + `ParallelToolRunner(maxConcurrency = 4)`. Both honour `AbortSignal`.
- Refactor `LlmBroker.generate` / `generateStream` to delegate batch execution to `toolRunner ?? new SerialToolRunner()`. Default remains serial — zero behaviour change for non-opt-in callers.
- Add `recordToolBatch` to `TracerSystem`.
- Ship `parallel_tool_calls.ts` example.
- **Quality gate passes; PARITY.md gains a "Parallel Tool Execution" row and a "Tool Cancellation (AbortSignal)" row.**

**Phase 1 — Realtime gateway skeleton**
- New module `src/realtime/`.
- `RealtimeVoiceConfig`, `RealtimeItem`, normalized `RealtimeEvent` union, Zod schemas for OpenAI client+server events.
- `OpenAIRealtimeGateway` with WebSocket, framing, event in/out — no broker yet.
- Unit tests against a mock WebSocket.

**Phase 2 — Broker, text modality**
- `RealtimeVoiceBroker` + `RealtimeSession`.
- Text in, text/transcript out. Parallel tools via the runner from Phase 0.
- Ship `realtime_text_mode.ts` + `realtime_with_tools.ts` + `realtime_parallel_tools.ts`.

**Phase 3 — Audio modality**
- Audio in (`AsyncIterable<Int16Array>`), audio out (async generator).
- Server VAD + manual VAD paths.
- Interruption handling.
- Ship `realtime_simple_voice.ts`, `realtime_interruption.ts`, `realtime_push_to_talk.ts`.

**Phase 4 — Docs + parity prep**
- VitePress use-case guide: "Building a voice assistant".
- VitePress reference for `RealtimeVoiceBroker` / `OpenAIRealtimeGateway` / `ToolRunner`.
- Update PARITY.md with Realtime row across the four ports (all but TS marked 📝).

**Phase 5 — Port outward**
- Python: replicate using `websockets`, `asyncio.gather`-backed runner.
- Elixir: replicate using `:gun` or `Mint.WebSocket`, `Task.async_stream` runner.
- Rust: replicate using `tokio-tungstenite`, `futures::join_all` runner.

---

## 9. Resolved decisions

These were open questions in earlier drafts; recorded here so future readers see the call and the reason.

1. **Node version floor: Node 20+.** Adopt `await using` / `Symbol.asyncDispose` for `RealtimeSession`. Explicit `await session.close()` continues to work as a fallback. *Reason:* realtime is a 2.0 feature; setting a modern Node floor is fair, and the ergonomics for socket lifetimes are worth it.
2. **Audio I/O: document, don't ship.** No `node-speaker` / `node-mic` adapters in the library. Mojentic-ts stays hardware-free. Examples include a portable `wav-in / wav-out` demo plus pointers to common device libraries. *Reason:* device libraries are platform-fragile and tie us to native bindings.
3. **No WebRTC / no browser.** Realtime requires an OpenAI API key at the transport layer, which cannot safely live in a browser. Mojentic-ts remains Node-only per CHARTER.md. If a browser story is wanted later it goes through a separate proxy package, not this library.
4. **Evolve `ToolDescriptor` to a discriminated union.** This is a 2.0 major-version cleanup. The current shape `{type:"function", function:{name,...}}` is OpenAI-chat-completions-shaped and leaks. New shape (sketch):
   ```typescript
   export type ToolDescriptor =
     | { kind: 'function'; name: string; description: string; parameters: JsonSchema };
   //  future:
   //  | { kind: 'computer_use'; ... }
   //  | { kind: 'retrieval'; ... }
   ```
   Each gateway adapter (chat completions, realtime, future Anthropic) maps `ToolDescriptor` to its own wire format. `LlmTool.descriptor()` returns the union; the chat-completions and realtime gateways each translate at the boundary.
5. **Event normalization: vendor-neutral, with raw escape hatch.** See §9b below for the redesigned event union — we keep fidelity higher than the original draft suggested, so users don't reach for `rawEvents()` for ordinary work. `session.rawEvents()` stays as the power-user / debugging surface.
6. **`ParallelToolRunner` default `maxConcurrency`: 4.** Configurable. *Reason:* high enough to win meaningfully on typical realtime turns (2–3 concurrent function calls), low enough that unbounded fan-out into rate-limited APIs (web search, embeddings) doesn't punish users.
7. **Cancellation semantics: see §9a.** This needed its own section once we looked at it closely.

## 9a. Cancellation, in detail

**What OpenAI documents:** `response.cancel` "immediately ceases generation" and `conversation.item.truncate` removes audio after a sample count. They do **not** document what to do about `function_call` items that were emitted *before* the cancel — neither the official platform docs nor the realtime-api-beta SDK README address it. There is no AbortSignal-style cancellation for tool execution; that surface is entirely the client's.

**Practical implications observed in the wild:**

- A `response.done` (or implicit termination from `response.cancel`) can land with `function_call` items that the client never sent outputs for. The server will not error if outputs are missing — those calls effectively become orphans in the conversation history.
- If we *do* send `function_call_output` items for a cancelled response, the model accepts them and may reference them in the next turn. This is sometimes wanted (the tool did real work and we want the model to see it next time), sometimes harmful (the user changed topic — stale answers pollute context).

**Our contract for 2.0:**

1. **Tool execution gets an `AbortSignal`.** We evolve `LlmTool.run` to `run(args, ctx?: { signal?: AbortSignal })`. Backwards-compatible default — existing tools that ignore the signal still work; they just can't be hard-cancelled.
2. **`session.interrupt()` and barge-in cancel the response AND abort in-flight tools.** `ParallelToolRunner` wires a single `AbortController` per batch; cancellation aborts the controller, which signals every tool.
3. **Tool outputs from cancelled batches are dropped by default**, not sent. Rationale: the user interrupted because they wanted a different direction; sending stale outputs muddies the next turn.
4. **Opt-in retention** via `RealtimeVoiceConfig.onInterrupt: 'drop' | 'submit' | 'submit-completed-only'`. Default `'drop'`. `'submit-completed-only'` is the pragmatic middle: tools that finished before the abort signal landed get submitted; the in-flight ones get dropped.
5. **`LlmBroker` gets the same `AbortSignal` contract** for free via the shared `ToolRunner` abstraction. Useful for caller-driven timeouts on long tool chains.

This is bigger than "a follow-up minor" — it's a 2.0-shaped change because it touches `LlmTool`, the runner, and both brokers. Phased into the rollout (see §8 update).

## 9b. Vendor-neutral event union (revised)

The original draft proposed ~10 events. Per the decision to preserve more fidelity, the union below covers ~20, keeping vendor-neutral names. None of these names mention "OpenAI", "response", or any wire-protocol jargon — they're framed in terms of the conversation a developer is observing.

```typescript
export type RealtimeEvent =
  // Session lifecycle
  | { kind: 'session_opened';    sessionId: string }
  | { kind: 'session_updated';   config: Partial<RealtimeVoiceConfig> }
  | { kind: 'session_closed';    reason: 'client' | 'server' | 'error' }

  // User turn (what the human said / is saying)
  | { kind: 'user_speech_started';   atMs: number }
  | { kind: 'user_speech_stopped';   atMs: number }
  | { kind: 'user_transcript_delta'; itemId: string; delta: string }
  | { kind: 'user_transcript';       itemId: string; text: string }

  // Assistant turn (what the model is producing)
  | { kind: 'assistant_turn_started';   turnId: string }
  | { kind: 'assistant_text_delta';     turnId: string; delta: string }
  | { kind: 'assistant_text';           turnId: string; text: string }
  | { kind: 'assistant_transcript_delta'; turnId: string; delta: string }
  | { kind: 'assistant_transcript';       turnId: string; text: string }
  | { kind: 'assistant_audio_delta';    turnId: string; pcm: Int16Array }
  | { kind: 'assistant_turn_completed'; turnId: string; usage?: TokenUsage }

  // Tool calls (parallel-aware)
  | { kind: 'tool_call_started';        turnId: string; callId: string; name: string }
  | { kind: 'tool_call_args_delta';     callId: string; delta: string }
  | { kind: 'tool_call_dispatched';     callId: string; name: string; args: ToolArgs }
  | { kind: 'tool_call_completed';      callId: string; name: string; result: ToolResult }
  | { kind: 'tool_call_failed';         callId: string; name: string; error: Error }
  | { kind: 'tool_batch_submitted';     turnId: string; callIds: string[] }

  // Control
  | { kind: 'interrupted';   turnId: string; reason: 'barge_in' | 'manual' | 'error' }
  | { kind: 'rate_limited';  resetMs: number; details: Record<string, unknown> }
  | { kind: 'error';         error: Error; recoverable: boolean };
```

Design choices:

- **`turnId` vs `callId`** make parallel turns and parallel tool calls observable without leaking OpenAI's internal IDs.
- **Delta events stay separate from final events.** Users wiring up a UI subscribe to deltas; users writing logs subscribe to the final `assistant_text` / `assistant_transcript` / `user_transcript`. Both fire — we don't make consumers reassemble.
- **`tool_call_started` fires when the model begins emitting the call; `tool_call_dispatched` fires when *we* start executing it.** This split exists because, with the parallel runner, dispatching can be deferred (concurrency cap reached) — and you want both signals.
- **`assistant_audio_delta` carries `Int16Array`, not base64.** Decoding happens at the gateway boundary so consumer code never touches base64.
- **No `kind: 'function_call_arguments.delta'` etc.** The OpenAI event names stay in the gateway adapter; consumers see vendor-neutral names. `rawEvents()` is still there if needed.

This union ports cleanly to ex/py/ru as a tagged union / sum type / enum.

---

---

## 10. Risks

- **Maintenance surface** doubles for OpenAI: we now track both chat-completions API drift and realtime API drift. Mitigation: thin gateway, fixture-recorded tests, version-pin event schemas.
- **Audio is platform-y.** Even with us staying hardware-free, our examples need to work on macOS/Linux/Windows. Mitigation: ship one OS-portable example using a file-based audio source/sink (read a wav, write a wav).
- **Beta API churn.** OpenAI's realtime API is moving. Mitigation: lock event Zod schemas to a snapshotted version; expose `providerExtras`/`rawEvents` for forward compat.
- **Parallel tools change developer mental model.** Existing users may write tools that share state assuming serial execution. Mitigation: default `LlmBroker` to serial; require opt-in `ParallelToolRunner`. Document the contract.

---

## 11. What lands in PARITY.md

Once Phase 0 ships, add a row under "Tool System":

| Feature | Python | Elixir | Rust | TypeScript | Notes |
|---|---|---|---|---|---|
| **Parallel Tool Execution** | 📝 | 📝 | 📝 | ✅ | `ToolRunner` abstraction; serial default. |

Once Phase 3 ships, add a new top-level section "Realtime Voice":

| Feature | Python | Elixir | Rust | TypeScript | Notes |
|---|---|---|---|---|---|
| **RealtimeVoiceBroker** | 📝 | 📝 | 📝 | ✅ | |
| **OpenAI Realtime Gateway** | 📝 | 📝 | 📝 | ✅ | WebSocket transport. |
| **Server VAD turn detection** | 📝 | 📝 | 📝 | ✅ | |
| **Manual VAD / push-to-talk** | 📝 | 📝 | 📝 | ✅ | |
| **Interruption / barge-in** | 📝 | 📝 | 📝 | ✅ | |
| **Parallel tool calls in voice turn** | 📝 | 📝 | 📝 | ✅ | Inherits `ParallelToolRunner`. |

---

## 12. Asks of the reader

- Sanity-check §2 (broker-as-sibling vs subclass).
- Sanity-check §5 (`ToolRunner` abstraction shape — is `runBatch` the right cut?).
- Sanity-check §9a contract — especially `onInterrupt: 'drop'` as the default. The alternative ("submit completed tools, drop in-flight") is also defensible.
- Sanity-check §9b event union — is the level of fidelity right, or do you want to push it further (e.g., expose `content_part` boundaries for streaming UI fidelity)?
- Confirm trunk-based phasing in §8 is acceptable as the rollout shape, or push back on phase boundaries.
