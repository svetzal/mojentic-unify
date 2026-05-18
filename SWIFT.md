# Mojentic Swift Port — Plan

Status: **📝 Planned** (not yet started)
Target sub-project directory: `mojentic-sw/`
Last updated: 2026-05-17 (rev 2: parity-gap fixes + Swift 6.1 toolchain decision)

This document plans a fifth Mojentic port: a Swift implementation distributed via Swift Package Manager. It is a planning artifact for review, not a commitment to scope or schedule.

The Python implementation (`mojentic-py/`) remains the source of truth for API design and feature behaviour. PARITY.md will gain a Swift column once work begins.

---

## 1. Purpose & Goals

Bring Mojentic's "simple, flexible LLM interaction" library to Swift developers building Apple-platform apps (macOS, iOS, iPadOS, watchOS, tvOS, visionOS) and server-side Swift services (Linux).

**Goals**

- Provide a unified async API for OpenAI, Ollama, and (later) Anthropic, through a single broker, mirroring the Python reference design.
- Be **distinctly Swift-idiomatic**: Swift Concurrency end to end (`async/await`, `AsyncSequence`, structured tasks, actor isolation, `Sendable`), not a transliteration of any other port.
- Ship as a first-class Swift Package: `Package.swift` with library product `Mojentic`, semantic versioning, and tagged releases consumable directly from a Git URL.
- Achieve feature parity with the Python/TS/Elixir/Rust ports across Layer 1 (LLM), Layer 2 (Tracer), Layer 3 (Agents), and Layer 4 (Realtime Voice).
- Maintain the same mandatory quality gates the other ports do: format, lint, tests, security audit — all green before any commit.

**Non-goals**

- Apple-only. Linux server support is a requirement, not an afterthought.
- Synchronous/blocking API surface. The library is async-first.
- A SwiftUI showcase app. Mojentic is a library; example clients ship under `Examples/`, not as a packaged binary product.
- Reimplementing provider SDKs feature-by-feature. We expose what the common abstraction needs; raw escape hatches stay narrow.

**Target users**

Swift developers integrating LLMs into Apple-platform apps, command-line tools, server-side Swift services, or cross-platform Swift code. Especially those who already use Mojentic on another stack and want consistent semantics.

---

## 2. Swift-Idiomatic Translation Choices

The "feel right to Swift developers" bar drives these decisions. Each is a deliberate divergence from how the Python reference encodes the same concept.

| Concept (Python ref) | Swift translation | Rationale |
|---|---|---|
| `BaseModel` (Pydantic) | `Codable` `struct` (value types, `Sendable`) | Native serialization; cheap copies; safe to pass across actors. |
| `async def` + asyncio | `async throws` + Structured Concurrency | First-class language feature, no event-loop assumptions. |
| Streaming iterator | `AsyncThrowingStream<StreamEvent, Error>` / `AsyncSequence` | Composes with `for try await`, cancellation, `swift-async-algorithms`. |
| `asyncio.Event` for tool cancellation | Cooperative `Task` cancellation (`Task.isCancelled`, `withTaskCancellationHandler`) | Idiomatic Swift; no extra primitive needed for parity with AbortSignal/CancellationToken. |
| Abstract base class | `protocol` (with primary associated types where useful) + `actor` for stateful coordinators | Composition over inheritance; aligns with the shared engineering principle. |
| Pydantic schema generation | Generate JSON Schema from `Codable` types via a small `JSONSchemaGenerator` helper (or adopt `swift-json-schema`) | Avoids a heavyweight macro; keeps tool authoring approachable. |
| `Dispatcher` + `Router` shared state | Implement as `actor`s | Memory safety + Sendable correctness, no manual locks. |
| `SharedWorkingMemory` | `actor SharedWorkingMemory` | Same reason; concurrent-safe by construction. |
| `EventStore` | `actor EventStore` | Mutable event log read by many consumers. |
| Tracer null object | Protocol with default no-op extension implementations + `NullTracer` struct | Matches Swift's "protocol + default impl" pattern. |
| Provider feature gates (Rust Cargo features) | **Swift Package Traits** (SwiftPM 6.1+, released 2025-03-31) for `ollama` / `openai` / `anthropic` opt-ins. | Direct analogue; keeps binary size and dependency surface controllable. Requires Swift 6.1 minimum (see §10). |
| `tiktoken-rs` | `tiktoken-swift` (or equivalent maintained port); ship a `TokenizerGateway` protocol so consumers can substitute. | Same gateway pattern as the other ports. |
| `reqwest` | `URLSession` for client code (zero dep, Linux-supported via swift-corelibs-foundation); evaluate `async-http-client` only if streaming gaps appear on Linux. | Prefer stdlib-adjacent for portability. |
| `tokio-tungstenite` (Rust realtime WS) | `URLSessionWebSocketTask` | Apple-supported, available on Linux via SCF. |
| Manual builder pattern | Result builders (`@resultBuilder`) for fluent constructs (tools, prompts) where they add real clarity; otherwise plain init + `with()` style. | Use the language; don't over-DSL. |
| `unwrap`/`expect` style | `throws` with typed errors (`MojenticError`) at every boundary; force-unwraps banned in library code. | Mirrors the Rust port's "no `unwrap()` in lib code" rule. |
| Logging | `swift-log` (`Logger`) | Standard for the Swift server ecosystem; the consumer wires up a backend. |

### Naming conventions

Follow the Swift API Design Guidelines, not the Rust/Python casing:

- `LLMBroker`, `LLMGateway`, `LLMMessage`, `LLMTool` — `LLM` is a recognized initialism and stays uppercase.
- `CompletionConfig`, `ReasoningEffort` (cases: `.low`, `.medium`, `.high`) — matches Swift enum convention.
- `ChatSession`, `Tracer`, `Router`, `Dispatcher`, `SharedWorkingMemory` — unprefixed; the module name is the namespace.
- File tools: `FileReader`, `FileWriter`, etc. — not `file_reader_tool.swift`.
- Async functions read as sentences: `try await broker.complete(messages:tools:config:)`.
- Message composers are static factories on the message type: `LLMMessage.system(_:)`, `LLMMessage.user(_:)`, `LLMMessage.assistant(_:)`, `LLMMessage.tool(callId:content:)`, plus multimodal variants like `LLMMessage.user(text:images:)`. Mirrors the per-port "Message Composers" parity row without needing a separate builder type.

### Concurrency model

- Library is **Swift 6 strict-concurrency clean**. Every public type is `Sendable` or `@unchecked Sendable` with documented justification.
- Cancellation is cooperative `Task` cancellation throughout. Tools that perform I/O honour `Task.checkCancellation()` and clean up via `withTaskCancellationHandler`.
- Parallel tool execution uses `TaskGroup` / `ThrowingTaskGroup`. The serial-default-for-chat-broker semantics from the other ports are preserved; `ParallelToolRunner` is opt-in.
- No `DispatchQueue`, no `OperationQueue`, no `@MainActor` in the library surface — those are concerns of the *consuming* app.

---

## 3. Project Layout & SwiftPM

Sub-project root: `mojentic-sw/` (`-sw` mirrors `-py`/`-ts`/`-ex`/`-ru` two-letter style).

```
mojentic-sw/
├── Package.swift                  # swift-tools-version: 6.1 (Package Traits)
├── Package.resolved
├── README.md
├── CHARTER.md
├── AGENTS.md
├── CLAUDE.md                      # @AGENTS.md
├── CHANGELOG.md
├── LICENSE
├── .swift-format                  # swift-format config
├── .swiftlint.yml                 # SwiftLint config
├── Sources/
│   └── Mojentic/
│       ├── LLM/
│       │   ├── Broker.swift
│       │   ├── ChatSession.swift
│       │   ├── CompletionConfig.swift
│       │   ├── Gateway.swift              # protocol LLMGateway
│       │   ├── Messages.swift
│       │   ├── ResponseFormat.swift
│       │   ├── Gateways/
│       │   │   ├── OllamaGateway.swift
│       │   │   ├── OpenAIGateway.swift
│       │   │   ├── OpenAIMessageAdapter.swift
│       │   │   ├── OpenAIModelRegistry.swift
│       │   │   ├── TokenizerGateway.swift
│       │   │   └── EmbeddingsGateway.swift
│       │   └── Tools/
│       │       ├── Tool.swift              # protocol LLMTool + descriptor types
│       │       ├── ToolRunner.swift        # serial + parallel runners
│       │       ├── DateResolverTool.swift
│       │       ├── CurrentDateTimeTool.swift
│       │       ├── FileTools.swift
│       │       ├── EphemeralTaskManager.swift
│       │       ├── AskUserTool.swift
│       │       ├── TellUserTool.swift
│       │       ├── WebSearchTool.swift
│       │       └── ToolWrapper.swift
│       ├── Tracer/
│       │   ├── Tracer.swift                # protocol
│       │   ├── NullTracer.swift
│       │   ├── EventStore.swift            # actor
│       │   ├── TracerSystem.swift
│       │   └── TracerEvents.swift
│       ├── Agents/
│       │   ├── BaseAgent.swift             # protocol
│       │   ├── BaseAsyncAgent.swift
│       │   ├── AsyncLLMAgent.swift
│       │   ├── AsyncAggregatorAgent.swift
│       │   ├── IterativeProblemSolver.swift
│       │   ├── SimpleRecursiveAgent.swift
│       │   └── ReActAgent.swift
│       ├── Realtime/
│       │   ├── RealtimeVoiceBroker.swift
│       │   ├── RealtimeGateway.swift       # protocol
│       │   ├── OpenAIRealtimeGateway.swift
│       │   ├── RealtimeEvents.swift
│       │   ├── RealtimeSession.swift
│       │   ├── AudioCodec.swift
│       │   └── Transport.swift             # URLSessionWebSocketTask wrapper
│       ├── Context/
│       │   └── SharedWorkingMemory.swift   # actor
│       ├── Dispatch/
│       │   ├── Event.swift
│       │   ├── Router.swift                # actor
│       │   └── AsyncDispatcher.swift       # actor
│       ├── Errors/
│       │   └── MojenticError.swift
│       ├── Internal/
│       │   ├── JSONSchemaGenerator.swift
│       │   └── HTTPClient.swift            # thin URLSession wrapper
│       └── Mojentic.swift                  # umbrella, doc comments, public re-exports
├── Tests/
│   └── MojenticTests/
│       ├── LLM/
│       ├── Tracer/
│       ├── Agents/
│       ├── Realtime/
│       └── Fixtures/
├── Examples/                       # executable products, one per example
│   ├── SimpleLLM/
│   ├── Streaming/
│   ├── ChatSession/
│   ├── ImageAnalysis/
│   ├── ... (26 shared examples, see §7)
├── docs/                           # DocC catalog source + tutorials
│   └── Mojentic.docc/
└── scripts/
    ├── lint.sh
    ├── test.sh
    └── audit.sh
```

**Package products**

- `library "Mojentic"` (single library, multi-folder internal layout). Reasoning: keeps imports trivial (`import Mojentic`) and lets us evolve internal modularization without breaking consumers. Provider-specific code is conditionally compiled via Package Traits (see below).
- One `executable` product per example under `Examples/`. Each example imports `Mojentic` and is independently runnable: `swift run SimpleLLM`.

**Package Traits (preferred) or fallback feature flags**

```swift
// Package.swift sketch — requires swift-tools-version: 6.1 (Package Traits shipped 2025-03-31)
let package = Package(
    name: "Mojentic",
    platforms: [
        .macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)
    ],
    products: [
        .library(name: "Mojentic", targets: ["Mojentic"]),
        // executable example products listed below…
    ],
    traits: [
        .default(enabledTraits: ["ollama"]),
        .trait(name: "ollama"),
        .trait(name: "openai"),
        .trait(name: "anthropic"),
        .trait(name: "full", enabledTraits: ["ollama", "openai", "anthropic"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        // tokenizer + json schema TBD per §10
    ],
    targets: [
        .target(
            name: "Mojentic",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny"),
            ]
        ),
        .testTarget(name: "MojenticTests", dependencies: ["Mojentic"]),
        // example executables
    ]
)
```

Package Traits are a first-class SwiftPM feature as of Swift 6.1 (released 2025-03-31) — see §10 for the toolchain decision. No `#if canImport` fallback path is planned; consumers needing older toolchains can use a prior tagged release that ships everything always-on.

---

## 4. Module-by-Module Mapping

### Layer 1 — LLM Integration

**Broker** (`LLM/Broker.swift`)

```swift
public actor LLMBroker {
    public init(gateway: any LLMGateway, tracer: any Tracer = NullTracer())

    public func complete(
        model: String,
        messages: [LLMMessage],
        tools: [any LLMTool] = [],
        config: CompletionConfig = .init()
    ) async throws -> LLMResponse

    public func completeJSON<T: Codable & Sendable>(
        model: String,
        messages: [LLMMessage],
        responseType: T.Type,
        config: CompletionConfig = .init()
    ) async throws -> T

    public func stream(
        model: String,
        messages: [LLMMessage],
        tools: [any LLMTool] = [],
        config: CompletionConfig = .init()
    ) -> AsyncThrowingStream<StreamEvent, Error>
}
```

- `actor` because the broker owns conversation-adjacent caches and the tracer write path.
- `completeJSON<T>` uses generics + `Codable` for structured output; schema is derived via `JSONSchemaGenerator` (see §10).
- `stream` returns an `AsyncThrowingStream` of `StreamEvent` (text chunks, tool-call requests, tool-call results, thinking traces, done).

**Gateway protocol** (`LLM/Gateway.swift`)

```swift
public protocol LLMGateway: Sendable {
    func complete(model: String,
                  messages: [LLMMessage],
                  tools: [any LLMTool]?,
                  config: CompletionConfig) async throws -> LLMGatewayResponse

    func completeJSON(model: String,
                      messages: [LLMMessage],
                      schema: JSONValue,
                      config: CompletionConfig) async throws -> JSONValue

    func availableModels() async throws -> [String]

    func stream(model: String,
                messages: [LLMMessage],
                tools: [any LLMTool]?,
                config: CompletionConfig) -> AsyncThrowingStream<GatewayStreamEvent, Error>
}
```

- One protocol; two production implementations to start: `OllamaGateway`, `OpenAIGateway`. Anthropic follows.
- Each gateway is a thin wrapper over `URLSession` request/response shaping — *no* business logic, mirroring the Gateway Pattern principle from `AGENTS.md`.

**Tool protocol** (`LLM/Tools/Tool.swift`)

```swift
public protocol LLMTool: Sendable {
    var descriptor: ToolDescriptor { get }
    func execute(arguments: JSONValue) async throws -> JSONValue
}

public struct ToolDescriptor: Sendable, Codable {
    public let name: String
    public let description: String
    public let parameters: JSONValue   // JSON Schema
}
```

- `ToolRunner` has two implementations: `SerialToolRunner` (default for the chat broker) and `ParallelToolRunner` (uses `ThrowingTaskGroup`).
- Cancellation: each `execute` is run inside a task that cooperates with cancellation; an interrupted realtime turn cancels in-flight tools via the parent `Task`.

**ChatSession** (`LLM/ChatSession.swift`)

- `actor ChatSession` owning message history, an optional `ContextWindowManager`, an optional tool set, and an optional system prompt.
- `func send(_ text: String) async throws -> LLMResponse` — appends user turn, runs the broker, appends assistant turn to history.
- `func stream(_ text: String) -> AsyncThrowingStream<StreamEvent, Error>` — the parity-tracked **Streaming Send** feature. Auto-manages history: appends the user turn before streaming, accumulates assistant deltas, appends the finalised assistant turn (with any tool-call/tool-result pairs) once the stream completes.
- `ContextWindowManager` is a small protocol with a default token-budget implementation that pages out oldest non-system turns when the running token estimate exceeds the model's context. Token estimates come from `TokenizerGateway`. Mirrors the per-port "Context Window" parity row.

### Layer 2 — Tracer System

- `protocol Tracer: Sendable` with default no-op methods for every event; `NullTracer` is the default.
- `actor EventStore` holds the in-memory event log; query methods (`events(matching:)`, `events(correlatedTo:)`) return `[TracerEvent]`.
- `enum TracerEvent` (a `Codable & Sendable` enum-with-associated-values) covers LLM call/response, tool call/result/batch, agent lifecycle.
- **Correlation IDs**: each broker invocation generates a root `correlationId: UUID`. The broker passes a `TracerContext` value (carrying root + optional parent IDs) through to the `ToolRunner`, which threads it into every per-tool execution and into nested broker calls made by tool wrappers (`broker-as-tool`). All `TracerEvent` cases carry `correlationId` and optional `parentId`, matching the per-port "Correlation Tracking" parity row.
- **Performance metrics**: every `TracerEvent` case carries `timestamp: Date` and, for paired call/response and call/result events, `duration: Duration` (Swift's first-class `Duration` type). Computed by the broker and tool runner using `ContinuousClock.measure`. Mirrors the per-port "Performance Metrics" parity row.

### Layer 3 — Agents

- `protocol BaseAgent: Sendable` / `BaseAsyncAgent` with an `async func handle(_ event: Event) async throws -> [Event]` contract.
- `AsyncLLMAgent`, `AsyncAggregatorAgent`, `IterativeProblemSolver`, `SimpleRecursiveAgent`, `ReActAgent` all sit on top of the broker.
- `AsyncDispatcher` and `Router` are `actor`s; `SharedWorkingMemory` is an `actor` with read-only snapshots returned as value types.
- The Python-only `AgentEventAdapter` and message-priority/audience features are explicitly **out of v1 scope** to match the other ports.
- **Async-first subsumption.** Two PARITY.md rows have no separate Swift type because the language is async-first: the **Base LLM Agent** row is covered by `AsyncLLMAgent` (there is no synchronous `LLMAgent`), and the synchronous **Dispatcher** row is covered by `AsyncDispatcher` (no separate sync dispatcher). PARITY.md's Swift column should mark both rows ✅ with a footnote pointing here, not ❌.

### Layer 4 — Realtime Voice

- `actor RealtimeVoiceBroker` mirrors `LLMBroker` shape: a coordinator above a `protocol RealtimeGateway`.
- `OpenAIRealtimeGateway` uses `URLSessionWebSocketTask`; the transport is a small `actor` so reads/writes serialize correctly.
- Audio: `Int16` PCM frames passed via `AsyncStream<AudioFrame>` on both ingress and egress. **Format contract** matches the OpenAI Realtime API: little-endian signed 16-bit PCM, **mono, 24 kHz sample rate**, base64-encoded over the wire (decoded/encoded inside the gateway, never exposed to consumers). `AudioFrame` is a `struct { let samples: [Int16]; let sampleRate: Int = 24_000 }` carrying ~20–40 ms chunks. We do **not** ship audio capture/playback — those are app concerns (AVFoundation on Apple, ALSA/etc. on Linux).
- VAD modes: `.server`, `.manual` (push-to-talk). Interruption / barge-in works via cooperative `Task` cancellation of in-flight tools, matching the other ports.
- `enum RealtimeEvent` is the vendor-neutral union; `rawEvents` `AsyncStream` is the escape hatch.

---

## 5. Quality Gates

All gates must pass before any commit, matching the other ports.

| Concern | Tool | Command |
|---|---|---|
| Format check | swift-format | `swift format lint --strict -r Sources Tests Examples` |
| Format apply | swift-format | `swift format -i -r Sources Tests Examples` |
| Lint | SwiftLint (with `--strict`) | `swiftlint --strict` |
| Build | SwiftPM | `swift build -c release` |
| Tests | Swift Testing (preferred) + XCTest where needed | `swift test --parallel` |
| Coverage | llvm-cov via SwiftPM | `swift test --enable-code-coverage` then `xcrun llvm-cov export …` |
| Security audit | (1) GitHub Dependabot for SwiftPM; (2) manual review of `Package.resolved` deltas; (3) consider [`swift-security-scanner`](https://github.com/) once vetted | scripted in `scripts/audit.sh` |
| API surface review | `swift package diagnose-api-breaking-changes` against last released tag | run pre-release |

**Strict concurrency**: `-strict-concurrency=complete` (or upcoming feature flag); zero warnings tolerated.

The `mojentic-sw/AGENTS.md` will codify the equivalent of the Rust port's mandatory pre-commit block:

```bash
swift format lint --strict -r Sources Tests Examples && \
swiftlint --strict && \
swift build -c release && \
swift test --parallel
```

CI (GitHub Actions) runs on macOS-latest and ubuntu-latest with the current stable Swift toolchain, plus a job pinned to the minimum supported toolchain (Swift 6.1).

**PARITY.md snapshot row.** Every phase that ships a release also updates the "Test & Quality Snapshot" table in PARITY.md with a Swift row (tests count, coverage %, lint warnings, security tool status) so the cross-port view stays consistent.

---

## 6. Documentation

| Library | Tool | Location |
|---|---|---|
| Swift | **DocC** | `mojentic-sw/Sources/Mojentic/Mojentic.docc/` + GitHub Pages |

DocC is the right pick: it's the native Swift documentation tool, supports tutorials with step-by-step code reveals (mapping cleanly to Mojentic's Use Cases model), and renders consumable docs for both API reference and narrative guides from one source.

Structure mirrors the other ports' three-section layout and the per-port "Documentation Philosophy" guarantees in PARITY.md (Use Cases / Examples / Core Concepts; tools framed as reference implementations, not core features):

- **Use Cases** (DocC `@Tutorials`, self-contained, Why/When/How structure): Building Chatbots, Structured Output, Building Agents, Image Analysis.
- **Examples** (one DocC article per provided tool): each opens with an explicit "this is a reference implementation, not a core library feature" framing, then walks through usage and customisation/extension guidance — matching the per-port "Example Tool Documentation" table (File Tools, Task Management, Web Search at minimum).
- **Core Concepts**: API reference auto-generated from doc comments on public symbols.

Deployment: `swift package --disable-sandbox preview-documentation --target Mojentic` for local; a GitHub Actions job publishes `swift package generate-documentation` output to GitHub Pages on every `v*` tag.

PARITY.md's documentation table will gain a Swift row once `mojentic-sw/Mojentic.docc/` ships its initial Use Cases.

---

## 7. Examples

All 26 shared examples (per PARITY.md §"Examples by Complexity Level") ported as individual SwiftPM executable products under `Examples/`. Each is independently runnable and serves as integration coverage:

- Level 1: `SimpleLLM`, `ListModels`, `SimpleStructured`, `SimpleTool`
- Level 2: `BrokerExamples`, `Streaming`, `ChatSession`, `ChatSessionWithTool`, `ImageAnalysis`, `Embeddings`, `CurrentDateTimeTool`
- Level 3: `FileTool`, `CodingFileTool`, `BrokerAsTool`, `EphemeralTaskManager`, `TellUser`, `AskUser`, `WebSearch`
- Level 4: `TracerDemo`
- Level 5: `AsyncLLM`, `AsyncDispatcher`
- Level 6: `IterativeSolver`, `RecursiveAgent`, `SolverChatSession`
- Level 7: `ReAct`, `WorkingMemory`

CI builds **all** examples on every commit — like the Rust port's `--all-targets` rationale, an example that doesn't compile is broken documentation.

---

## 8. Versioning & Release

- Major and minor versions stay synchronized with the other four ports (per `mojentic-ru/AGENTS.md` Version Synchronization). Patch versions move independently.
- Initial release: `1.4.0` (current monorepo minor), so cross-port version reads consistent on day one.
- Tagged releases (`v1.4.0`, etc.) trigger CI to (a) build, (b) run gates, (c) publish DocC to GitHub Pages.
- **No registry publish step** — Swift Package Manager consumes directly from a Git URL + tag. The Swift Package Index will surface the package automatically once a `Package.swift` + tag are present on a public GitHub repo with the right metadata.
- Add Swift Package Index manifest hints (`.spi.yml`) for documentation generation and supported-platform display.

---

## 9. Roadmap (Phased)

Each phase ends with a passing quality gate, tagged release, and an updated PARITY.md row.

### Phase 0 — Skeleton + de-risking spike (2–4 days)
- Create `mojentic-sw/` with `Package.swift` (`swift-tools-version: 6.1`), `AGENTS.md`, `CHARTER.md`, `README.md`, `CHANGELOG.md`, license, lint/format configs, empty DocC catalog.
- CI workflow running format + lint + build + test on macOS and Linux against the Swift 6.1 minimum.
- Add Swift column to PARITY.md (all rows `📝 Planned` initially) and a Swift row to the Test & Quality Snapshot table.
- **JSON Schema spike** (de-risks open question §10.1): build two throwaway prototypes — one using the candidate community package, one using a `@LLMToolArguments` macro — and pick the winner by end of Phase 0 before any Phase 1 tool work begins.

### Phase 1 — Core LLM (Ollama only)
- `LLMMessage` (with static composers: `.system`, `.user`, `.assistant`, `.tool`), `CompletionConfig`, `ReasoningEffort`, `MojenticError`.
- `LLMGateway` protocol; `OllamaGateway` implementation (complete, completeJSON, streaming, tools, thinking traces).
- `LLMBroker` with non-streaming + streaming + recursive tool execution.
- `Tool` protocol, `ToolDescriptor`, `SerialToolRunner`; `CurrentDateTimeTool`, `DateResolverTool`.
- Examples: `SimpleLLM`, `ListModels`, `SimpleStructured`, `SimpleTool`, `Streaming`.

### Phase 2 — OpenAI Gateway + ChatSession + Image Analysis
- `OpenAIGateway` + `OpenAIMessageAdapter` + `OpenAIModelRegistry`.
- `ChatSession` actor with both `send(_:)` and `stream(_:)` (the parity-tracked "Streaming Send", with auto history management for streamed assistant turns and any intermediate tool exchanges).
- `ContextWindowManager` protocol + default token-budget implementation that pages out oldest non-system turns.
- Multimodal `LLMMessage` content (image parts) + `LLMMessage.user(text:images:)` composer.
- `TokenizerGateway` + `EmbeddingsGateway`.
- Examples: `BrokerExamples`, `ChatSession`, `ChatSessionWithTool`, `ImageAnalysis`, `Embeddings`.

### Phase 3 — Tracer + Provided Tools
- `Tracer` protocol, `NullTracer`, `EventStore` (actor), full `TracerEvent` enum union.
- `TracerContext` value type carrying `correlationId` (root) and optional `parentId`; broker generates the root and threads it through the `ToolRunner` into per-tool executions and into nested broker calls made by `ToolWrapper` (broker-as-tool).
- Every event carries `timestamp: Date` and, for call/response and call/result pairs, `duration: Duration` measured via `ContinuousClock.measure`. Covers the per-port "Correlation Tracking" and "Performance Metrics" parity rows.
- File tools (8), Task manager, AskUser, TellUser, WebSearch, ToolWrapper.
- `ParallelToolRunner` (uses `ThrowingTaskGroup`) — emits per-batch `toolBatch` tracer events.
- Examples: `FileTool`, `CodingFileTool`, `BrokerAsTool`, `EphemeralTaskManager`, `TellUser`, `AskUser`, `WebSearch`, `TracerDemo`.

### Phase 4 — Agent System
- `BaseAgent`, `BaseAsyncAgent`, `AsyncLLMAgent`, `AsyncAggregatorAgent`.
- `AsyncDispatcher`, `Router`, `Event` types.
- `SharedWorkingMemory` actor.
- `IterativeProblemSolver`, `SimpleRecursiveAgent`, `ReActAgent`.
- Examples: `AsyncLLM`, `AsyncDispatcher`, `IterativeSolver`, `RecursiveAgent`, `SolverChatSession`, `ReAct`, `WorkingMemory`.

### Phase 5 — Realtime Voice
- `RealtimeGateway` protocol; `OpenAIRealtimeGateway` over `URLSessionWebSocketTask`.
- `RealtimeVoiceBroker`, session, audio codec types.
- Server VAD + manual VAD; interruption / barge-in via task cancellation; parallel tool calls in voice turns.
- Vendor-neutral `RealtimeEvent` union + raw-events escape hatch.

### Phase 6 — Anthropic Gateway
- `AnthropicGateway` behind the `anthropic` package trait. Matches the Python feature set the other ports also lack today.

### Phase 7 — Documentation polish & 1.x stabilization
- DocC tutorials for all four Use Cases.
- Swift Package Index hints.
- Release-candidate audit pass before bumping to a synchronized minor with the other ports.

---

## 10. Open Questions / Decisions Needed

### Decided

- **Minimum Swift toolchain: Swift 6.1** (released 2025-03-31). Package Traits ship in 6.1, not 6.0 — and traits are load-bearing for the provider gating strategy in §3. Strict concurrency, typed throws, and `Duration` are already available in 6.0; 6.1 also extends `nonisolated` to types/extensions and improves task-group result inference, both of which clean up the actor-heavy core. Anyone on Swift 5.x or 6.0 stays on TS/Python/Rust/Elixir.
- **Minimum platform versions.** macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1. Driven by `URLSession` async APIs and `AsyncSequence` ergonomics.
- **Logging adapter.** Depend on `swift-log`; consumers bridge to `os.Logger` themselves (standard pattern for cross-platform Swift libraries).
- **Repo hosting & layout.** `svetzal/mojentic-sw` on GitHub, referenced from the monorepo as a `mojentic-sw/` git submodule. Matches the convention used by the other four ports.

### Open — need a call before or during Phase 0

1. **JSON Schema generation source.** Three options:
   - **(a) Hand-rolled `JSONSchemaGenerator` over `Mirror`** — *not recommended.* `Mirror` reflects *instance* values, not declared type structure, and `Codable`'s synthesized containers aren't introspectable at runtime. To make (a) work we'd need a sample-instance protocol or an explicit `static var jsonSchema: JSONValue { get }` requirement on every tool argument type, neither of which is ergonomic.
   - **(b) Adopt a community package** (`swift-json-schema` or equivalent). Needs vetting for maintenance, license, and Swift 6.1 strict-concurrency cleanliness.
   - **(c) A Swift macro `@LLMToolArguments`** that emits the schema at compile time from a `Codable` struct. Most ergonomic for tool authors; Swift macros are stable in 6.1 (no extra toolchain burden given our minimum is already 6.1).
   - **Recommendation: prototype (c) and (b) side-by-side in Phase 0.** Pick whichever has the cleaner authoring story by the end of the spike. Do not start (a).
2. **Tokenizer port.** `tiktoken-rs` analogue — check `tiktoken-swift` maintenance status. Either way, expose `TokenizerGateway` protocol so consumers can substitute; ship a default implementation if `tiktoken-swift` is viable, otherwise document the "bring your own" path in v1.
3. **Audit tooling.** Swift has no `cargo deny` equivalent. Plan: rely on Dependabot for CVE notifications + commit a manual lockfile review checklist to `mojentic-sw/AGENTS.md`. Re-evaluate as the Swift security tooling ecosystem matures.
4. **Advanced Features stance.** PARITY.md's "Advanced Features" table tracks Configuration Files, Builder Pattern, Connection Pooling, and Retry Logic — Python is ✅/⚠️ on these and the other ports are mostly ❌/📝. Proposal: Swift v1 ships **❌ for all four**, matching the existing port consensus rather than expanding the parity surface unilaterally. Revisit if a real consumer asks.

---

## 11. Cross-Port Coordination Impact

Adopting this plan will require updates to:

- **`PARITY.md`** — add a Swift column to every feature table (status `📝 Planned` initially); add a Swift row to the "Test & Quality Snapshot" table; add Swift entries to the "Documentation Tooling" and "Library-Specific Documentation Adherence" tables once Phase 7 ships. In the "Advanced Features" table, mark Swift as ❌ for Configuration Files, Builder Pattern, Connection Pooling, and Retry Logic — matching the existing port consensus rather than expanding the parity surface (see §10 decision #4).
- **`AGENTS.md` (monorepo root)** — add `mojentic-sw/` row to the sub-project table and a Swift row to the per-language quality gates and documentation tables.
- **`mojentic-py/CHARTER.md`** and friends — no change required; Swift is downstream of the Python reference.
- A new `mojentic-sw/AGENTS.md` codifying the Swift quality gates and patterns above, modelled on `mojentic-ru/AGENTS.md`.

No code changes to the four existing ports are anticipated unless this planning surfaces an API inconsistency in the reference implementation worth resolving across the board.

---

*This document is a planning artifact. Once Phase 0 ships, day-to-day Swift work tracks under `mojentic-sw/AGENTS.md` and PARITY.md, and this file becomes a historical reference.*
