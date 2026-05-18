# Mojentic Kotlin Port — Plan

Status: **📝 Planned** (not yet started)
Target sub-project directory: `mojentic-kt/`
Last updated: 2026-05-17

This document plans a sixth Mojentic port: a **Kotlin Multiplatform (KMP)** implementation targeting JVM/Android, iOS, and (later) other Kotlin/Native targets. Distributed via Maven Central for JVM/Android and as an XCFramework (consumable from Swift Package Manager or CocoaPods) for iOS.

The Python implementation (`mojentic-py/`) remains the source of truth for API design and feature behaviour.

This plan is a sibling to `SWIFT.md`. Where they overlap (e.g. tokenizer story, JSON schema generation), the choices intentionally diverge along language-idiomatic lines — see §2.

---

## 1. Purpose & Goals

Give Kotlin developers — particularly mobile teams shipping the *same* product to Android and iOS — a single Mojentic library that runs on both platforms and on the JVM server.

**Goals**

- Provide a unified `suspend`-based API for OpenAI, Ollama, and (later) Anthropic, through a single broker, matching the Python reference design. Surface thinking traces (model reasoning output) on gateway responses where the provider supplies them.
- Be **distinctly Kotlin-idiomatic**: coroutines + `Flow` throughout, sealed hierarchies for closed sums, data classes for value types, builder DSLs via lambda-with-receiver where they pay for themselves.
- Be **multiplatform-first**: one `commonMain` API surface, platform-specific code only where unavoidable (HTTP client engine, WebSocket transport, file I/O, secure random).
- Ship as a first-class Kotlin Multiplatform library:
  - **JVM/Android** → Maven Central (`com.mojentic:mojentic-kotlin:<version>`)
  - **iOS** → XCFramework + Swift Package Manager (preferred) and CocoaPods (fallback)
  - **macOS / Linux / JS / wasmJs** → opportunistic, post-MVP
- Achieve feature parity with the four existing ports across Layer 1 (LLM), Layer 2 (Tracer), Layer 3 (Agents), and Layer 4 (Realtime Voice).
- Maintain the same mandatory quality gates the other ports do: lint, tests, security audit — all green before any commit.

**Non-goals**

- Android-only or JVM-only. iOS support is a requirement, not "we'll figure it out later." If a feature can't go in `commonMain`, it goes behind an `expect/actual` boundary, not into a separate JVM-only library.
- Compose/Android UI helpers. Mojentic is a library. UI concerns stay in consumer apps.
- Bundling provider SDKs. We talk to provider HTTP APIs directly through Ktor; no `openai-java`, no `aws-bedrock-sdk` transitively pulled in.
- A blocking/synchronous API surface. The library is `suspend`/coroutine-first.

**Target users**

Kotlin developers building:
- Cross-platform mobile apps (KMP) that need LLM features identical on Android and iOS.
- Android-only apps wanting an idiomatic Kotlin LLM library.
- Kotlin server-side (Ktor, Spring Boot, Micronaut) services.
- Desktop apps (Compose Multiplatform, JavaFX).

---

## 2. Kotlin-Idiomatic Translation Choices

These are the deliberate divergences from how the Python reference (and other ports) encode the same concept. Each is grounded in standard Kotlin idiom and KMP constraints.

| Concept (Python ref) | Kotlin translation | Rationale |
|---|---|---|
| `BaseModel` (Pydantic) | `@Serializable data class` (kotlinx.serialization) | Native multiplatform serialization; value equality; immutability by default. |
| `async def` + asyncio | `suspend fun` + structured concurrency (`coroutineScope`, `supervisorScope`) | First-class language feature; no event-loop assumption. |
| Streaming iterator | `Flow<StreamEvent>` (cold, cancellable) | Composes with operators, integrates with structured concurrency, idiomatic for any Kotlin developer. |
| `asyncio.Event` for tool cancellation | Cooperative `Job` cancellation (`ensureActive()`, `isActive`, `CancellationException`) | Kotlin's built-in cooperative cancellation; no extra primitive needed for parity with AbortSignal/CancellationToken. |
| Abstract base class | `interface` (with default methods) + `class`/`object` implementors. Stateful coordinators wrap a `Mutex` or use single-thread `Dispatchers`. | Composition over inheritance, per the monorepo's shared engineering principles. |
| Closed sum types (RealtimeEvent, TracerEvent, errors) | `sealed interface` / `sealed class` with `data class` / `data object` variants; exhaustive `when` enforced. | Kotlin's signature pattern for "one of N shapes." |
| Pydantic schema generation | JSON Schema generated from `@Serializable` types via **kotlinx.serialization's `Json.schema` extension** (or a small in-repo `JsonSchemaGenerator` walking the `SerialDescriptor` if the ecosystem option is unsuitable). No KSP/codegen pipeline in v1. | Avoids forcing consumers onto KSP. The `SerialDescriptor` already encodes everything we need. |
| `Dispatcher` / `Router` / `SharedWorkingMemory` shared state | Plain classes that protect mutable state with `Mutex.withLock { … }`, exposing `suspend` accessors. We do **not** use Java `synchronized` (won't work on Native) or actor builders (deprecated). | Standard multiplatform-safe Kotlin pattern. |
| `EventStore` | `class EventStore` backed by a `MutableSharedFlow<TracerEvent>` (hot stream) + an internal append-only buffer. Consumers read via `events: Flow<TracerEvent>` or `snapshot(): List<TracerEvent>`. | Idiomatic for both real-time consumers and post-hoc queries. |
| Tracer null object | Top-level `object NullTracer : Tracer` with default no-op methods on the interface. | Zero allocation, exactly the Kotlin null-object pattern. |
| Provider feature gates (Rust Cargo features) | **Gradle module structure**: `mojentic-core`, `mojentic-ollama`, `mojentic-openai`, `mojentic-anthropic`, `mojentic-realtime-openai`, plus an umbrella `mojentic-bom`. Apps depend on `core` plus the providers they need. | Direct analogue of Cargo features; idiomatic to JVM/Gradle dependency management; lets ProGuard/R8 strip more. |
| `reqwest` / `URLSession` | **Ktor Client** with platform-specific engines (`OkHttp` on JVM/Android, `Darwin` on iOS, `Curl`/`CIO` on others). Wrapped by an `HttpGateway` interface. | The standard multiplatform HTTP choice; Ktor is maintained by JetBrains, ships with WebSocket + SSE support. |
| `tokio-tungstenite` (Rust realtime WS) | Ktor Client WebSocket support; platform-specific engines handle the underlying transport. | Multiplatform; same dependency we already pull in. |
| `tiktoken-rs` | Pluggable `TokenizerGateway` interface. On JVM/Android: **jtokkit** (Kotlin/Java). On Native: bring-your-own or a Kotlin/Native port if/when one matures. Tokenization is non-essential for MVP. | Lets the library ship without blocking on a Kotlin-Native tokenizer port. |
| Logging | **kotlin-logging** (multiplatform façade over SLF4J on JVM, `os.Logger` / println-based on Native). | Multiplatform-clean; consumer wires up a backend. |
| Builder DSL | Lambda-with-receiver DSLs (`@DslMarker`-annotated) for tool descriptors, prompts, chat sessions where they add real clarity; otherwise constructor + named/default args. | Use the language; don't over-DSL. |
| `unwrap`/`expect`/`!!` | Banned in library code. Use `requireNotNull` / `checkNotNull` / explicit `throws` of `MojenticException` at boundaries. | Mirrors the "no unwrap in library code" rule from the Rust port. |

### Naming conventions

Follow the official Kotlin style guide. Acronyms longer than two letters are treated as a single word (per JetBrains' guidance):

- `LlmBroker`, `LlmGateway`, `LlmMessage`, `LlmTool` — "Llm" not "LLM" (parallels `Http`, `Url`, `Json`).
- `CompletionConfig`, `ReasoningEffort` (enum: `LOW`, `MEDIUM`, `HIGH` — Kotlin enums use SCREAMING_SNAKE).
- `ChatSession`, `Tracer`, `Router`, `Dispatcher`, `SharedWorkingMemory`.
- Suspending functions read as sentences: `broker.complete(messages = …, tools = …, config = …)`.
- File tools: `FileReader`, `FileWriter`, etc.

### Concurrency & threading model

- Every public async API is a `suspend fun` or returns a `Flow<T>`. Nothing returns a `CompletableFuture`, `Deferred`, or `Job` from the public surface.
- The library does **not** dictate a `CoroutineScope`. Callers supply one, or use `suspend` calls inline. Internally we use `coroutineScope { … }` / `supervisorScope { … }` for fan-out.
- **No `runBlocking`** anywhere in library code (not even examples that aren't `main`).
- Cancellation is cooperative `Job` cancellation. Tools that perform I/O honour `ensureActive()` and clean up in `try { … } finally { … }` blocks.
- Parallel tool execution uses `coroutineScope { tools.map { async { it.execute(...) } }.awaitAll() }`. The chat broker default stays serial; `ParallelToolRunner` is opt-in.
- Concurrency-safe state via `Mutex` (multiplatform-safe) or `MutableStateFlow` / `MutableSharedFlow` where reactive semantics fit.
- All public types in `commonMain` that cross coroutine/thread boundaries are immutable `data class`es or are `@Suppress`-justified holders of `Mutex`-protected state.

---

## 3. Project Layout & Gradle

Sub-project root: `mojentic-kt/` (matches the existing two-letter sub-project pattern).

```
mojentic-kt/
├── settings.gradle.kts
├── build.gradle.kts                    # root
├── gradle/
│   └── libs.versions.toml              # version catalog
├── README.md
├── CHARTER.md
├── AGENTS.md
├── CLAUDE.md                           # @AGENTS.md
├── CHANGELOG.md
├── LICENSE
├── detekt.yml
├── .editorconfig                       # ktlint config
├── mojentic-core/                      # library module — Layer 1 core, no gateways
│   ├── build.gradle.kts
│   └── src/
│       ├── commonMain/kotlin/com/mojentic/
│       │   ├── llm/
│       │   │   ├── Broker.kt
│       │   │   ├── ChatSession.kt
│       │   │   ├── CompletionConfig.kt
│       │   │   ├── Gateway.kt          # interface LlmGateway
│       │   │   ├── Messages.kt
│       │   │   ├── ResponseFormat.kt
│       │   │   └── tools/
│       │   │       ├── Tool.kt
│       │   │       ├── ToolRunner.kt
│       │   │       ├── DateResolverTool.kt
│       │   │       ├── CurrentDateTimeTool.kt
│       │   │       ├── FileTools.kt    # expect declarations
│       │   │       ├── EphemeralTaskManager.kt
│       │   │       ├── AskUserTool.kt
│       │   │       ├── TellUserTool.kt
│       │   │       ├── WebSearchTool.kt
│       │   │       └── ToolWrapper.kt
│       │   ├── tracer/
│       │   ├── agents/
│       │   ├── dispatch/
│       │   ├── context/
│       │   ├── errors/
│       │   └── internal/
│       │       ├── HttpGateway.kt      # Ktor-based, common
│       │       └── JsonSchemaGenerator.kt
│       ├── commonTest/kotlin/…
│       ├── jvmMain/kotlin/…            # actual: FileTools, default logging backend
│       ├── jvmTest/kotlin/…
│       ├── androidMain/kotlin/…        # actual: FileTools (Android scoped storage)
│       ├── iosMain/kotlin/…            # actual: FileTools (NSFileManager)
│       └── iosTest/kotlin/…
├── mojentic-ollama/                    # OllamaGateway
├── mojentic-openai/                    # OpenAIGateway + adapters + model registry
├── mojentic-anthropic/                 # AnthropicGateway (Phase 6)
├── mojentic-realtime-openai/           # OpenAI Realtime voice gateway
├── mojentic-bom/                       # Bill of Materials (BOM) for version alignment
├── examples/                           # one Gradle subproject per example
│   ├── simple-llm/
│   ├── streaming/
│   ├── chat-session/
│   ├── … (26 shared examples, see §7)
├── samples/                            # Platform-specific sample apps (NOT part of distribution)
│   └── android-compose-chat/           # Reserved for Phase 7 Android Compose sample
├── docs/                               # Dokka-rendered docs + handwritten guides
└── scripts/
    ├── quality.sh
    └── audit.sh
```

**Gradle setup highlights**

- Kotlin **2.0+** (K2 compiler stable; required for the latest KMP ergonomics).
- Kotlin Multiplatform plugin (`org.jetbrains.kotlin.multiplatform`).
- `kotlinx.serialization` plugin.
- Dokka v2.
- **Version catalog** (`libs.versions.toml`) for all dependency versions — no scattered version literals.
- **No** `org.jetbrains.kotlin.android` plugin in any module — we want pure JVM consumers (Spring, Ktor server) to work too. Android support comes via the standard `androidTarget()` declaration in KMP, which produces an AAR consumable from Android projects without forcing Android compilation on JVM consumers.

**Target declarations (`mojentic-core/build.gradle.kts` sketch)**

```kotlin
kotlin {
    jvmToolchain(17)
    jvm()
    androidTarget {
        publishLibraryVariants("release")
    }
    iosX64()
    iosArm64()
    iosSimulatorArm64()
    // Post-MVP: macosArm64(), macosX64(), linuxX64(), js(IR), wasmJs()

    sourceSets {
        commonMain.dependencies {
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.ktor.client.core)
            implementation(libs.ktor.client.content.negotiation)
            implementation(libs.ktor.serialization.kotlinx.json)
            implementation(libs.kotlin.logging)
            implementation(libs.okio)
        }
        commonTest.dependencies {
            implementation(libs.kotlin.test)
            implementation(libs.kotlinx.coroutines.test)
            implementation(libs.turbine)
            implementation(libs.ktor.client.mock)
        }
        jvmMain.dependencies   { implementation(libs.ktor.client.okhttp) }
        androidMain.dependencies { implementation(libs.ktor.client.okhttp) }
        iosMain.dependencies   { implementation(libs.ktor.client.darwin) }
    }
}
```

**Distribution products**

| Target | Artifact | Consumed how |
|---|---|---|
| JVM / Android | Maven Central (`com.mojentic:mojentic-core:<v>`, plus per-gateway modules) | `implementation("com.mojentic:mojentic-core:1.4.0")` in Gradle |
| iOS | XCFramework + Swift Package Manager manifest | Add as SPM dependency in Xcode |
| iOS (fallback) | CocoaPods | `pod 'Mojentic'` |
| Cross-version coordination | `mojentic-bom` | `implementation(platform("com.mojentic:mojentic-bom:1.4.0"))` |

iOS distribution uses Kotlin's **KMP-NMC (Native Multiplatform Cocoa)** publishing pipeline: Gradle builds an XCFramework and either (a) generates a `Package.swift` for direct SPM consumption from a Git URL, or (b) pushes to a CocoaPods specs repo. Path (a) is the modern preference and aligns with the Swift port's distribution model.

---

## 4. Module-by-Module Mapping

### Layer 1 — LLM Integration

**Broker** (`mojentic-core` → `llm/Broker.kt`)

```kotlin
public class LlmBroker(
    private val gateway: LlmGateway,
    private val tracer: Tracer = NullTracer,
) {
    public suspend fun complete(
        model: String,
        messages: List<LlmMessage>,
        tools: List<LlmTool> = emptyList(),
        config: CompletionConfig = CompletionConfig(),
    ): LlmResponse

    public suspend inline fun <reified T : Any> completeJson(
        model: String,
        messages: List<LlmMessage>,
        config: CompletionConfig = CompletionConfig(),
    ): T

    public fun stream(
        model: String,
        messages: List<LlmMessage>,
        tools: List<LlmTool> = emptyList(),
        config: CompletionConfig = CompletionConfig(),
    ): Flow<StreamEvent>
}
```

- `completeJson<T>` uses an `inline reified` generic so callers don't pass a class token; schema derived from `T`'s `SerialDescriptor`.
- `stream` returns a **cold** `Flow`. Cancellation just works — caller cancels the collecting coroutine, the broker tears down the HTTP request.
- Recursive tool execution lives inside both `complete` and `stream` paths (parity with all other ports).
- `CompletionConfig` carries an optional `correlationId: Uuid?` for request tracing; the broker generates one if absent and threads it through gateway calls and tracer events.
- `LlmResponse` (and the underlying `LlmGatewayResponse`) exposes an optional `thinking: String?` field surfacing provider-supplied reasoning traces (Ollama `think`, OpenAI o-series reasoning summary, Anthropic extended thinking).

**Gateway interface** (`mojentic-core` → `llm/Gateway.kt`)

```kotlin
public interface LlmGateway {
    public suspend fun complete(
        model: String,
        messages: List<LlmMessage>,
        tools: List<LlmTool>?,
        config: CompletionConfig,
    ): LlmGatewayResponse

    public suspend fun completeJson(
        model: String,
        messages: List<LlmMessage>,
        schema: JsonElement,
        config: CompletionConfig,
    ): JsonElement

    public suspend fun availableModels(): List<String>

    public fun stream(
        model: String,
        messages: List<LlmMessage>,
        tools: List<LlmTool>?,
        config: CompletionConfig,
    ): Flow<GatewayStreamEvent>
}
```

- One interface; concrete implementations live in their own Gradle modules (`mojentic-ollama`, `mojentic-openai`, `mojentic-anthropic`). Apps pull only what they use.
- Each gateway is a thin Ktor-Client wrapper. **No business logic in gateways** — strict adherence to the Gateway Pattern from the shared engineering principles.

**Tool interface** (`mojentic-core` → `llm/tools/Tool.kt`)

```kotlin
public interface LlmTool {
    public val descriptor: ToolDescriptor
    public suspend fun execute(arguments: JsonElement): JsonElement
}

@Serializable
public data class ToolDescriptor(
    val name: String,
    val description: String,
    val parameters: JsonElement,  // JSON Schema
)
```

- `ToolRunner` has two implementations: `SerialToolRunner` (default for chat broker) and `ParallelToolRunner` (uses `coroutineScope { ... awaitAll() }`).
- Tool cancellation: each `execute` runs inside the caller's coroutine context, so cancelling the parent (e.g. on realtime barge-in) cancels in-flight tools — identical semantics to AbortSignal/CancellationToken in the other ports, achieved with zero extra API surface.

**Message construction helpers** (`mojentic-core` → `llm/Messages.kt`)

- Companion factory functions on `LlmMessage` cover the common shapes: `LlmMessage.system(...)`, `LlmMessage.user(...)`, `LlmMessage.assistant(...)`, `LlmMessage.tool(...)`, plus multimodal variants accepting image parts. These are the Kotlin analogue of the message composers shipped by all four reference ports — no DSL, just discoverable named constructors.

**ChatSession** (`mojentic-core` → `llm/ChatSession.kt`)

- `class ChatSession` owning message history, optional context-window manager, optional tool set, optional system prompt.
- Mutable state protected by `Mutex`. Exposes `suspend send(message: String): LlmResponse` and `fun stream(message: String): Flow<StreamEvent>` plus auto history management on streaming completion.

### Layer 2 — Tracer System

- `interface Tracer` with default no-op methods.
- `object NullTracer : Tracer`.
- `class EventStore` backed by `MutableSharedFlow<TracerEvent>(replay = …)` for live consumers + `Mutex`-protected list for snapshot queries.
- `sealed interface TracerEvent` with `data class` variants: `LlmCallEvent`, `LlmResponseEvent`, `ToolCallEvent`, `ToolBatchEvent`, `AgentEvent`. Correlation IDs are `kotlin.uuid.Uuid` (Kotlin 2.0+ has standard-library UUIDs).
- `ParallelToolRunner` emits a single `ToolBatchEvent` summarising the batch (per-call durations, success/failure counts, aggregate latency) in addition to the per-call `ToolCallEvent`s; `SerialToolRunner` emits only `ToolCallEvent`s. Parity with the Rust and TypeScript ports.

### Layer 3 — Agents

- `interface BaseAgent` / `BaseAsyncAgent` with `suspend fun handle(event: Event): List<Event>`.
- `AsyncLlmAgent`, `AsyncAggregatorAgent`, `IterativeProblemSolver`, `SimpleRecursiveAgent`, `ReActAgent` sit on top of the broker.
- `AsyncDispatcher` and `Router` are plain classes with `Mutex`-protected handler registries; event delivery happens via `launch`-ed child coroutines under a caller-supplied `CoroutineScope`.
- `SharedWorkingMemory` is a plain class with `Mutex`-protected map; reads return immutable snapshots.
- Python-only features (`AgentEventAdapter`, audience routing, priority) are explicitly **out of v1 scope** — matches the other non-Python ports.

### Layer 4 — Realtime Voice

- `mojentic-realtime-openai` module so apps don't pull WebSocket code if they don't need voice.
- `class RealtimeVoiceBroker` mirrors `LlmBroker` shape: a coordinator above a `RealtimeGateway` interface.
- `OpenAiRealtimeGateway` uses Ktor's `WebSockets` plugin.
- Audio: `Short`-array PCM frames (16-bit) via `Flow<AudioFrame>` ingress + egress. The library does **not** ship audio capture/playback — those are platform concerns (AudioRecord on Android, AVAudioEngine on iOS).
- VAD modes: `Server`, `Manual` (push-to-talk) modelled as a sealed type.
- Interruption / barge-in: cancelling the turn coroutine cancels in-flight tools — same as every other layer.
- `sealed interface RealtimeEvent` for the vendor-neutral union; `rawEvents: Flow<JsonElement>` is the escape hatch.

---

## 5. Quality Gates

All gates must pass before any commit, matching the other ports.

| Concern | Tool | Command |
|---|---|---|
| Lint (style) | **ktlint** (via `org.jlleitschuh.gradle.ktlint`) | `./gradlew ktlintCheck` |
| Lint (smells) | **Detekt** (with `detekt.yml`) | `./gradlew detekt` |
| Build | Gradle | `./gradlew build` |
| Tests | `kotlin.test` (multiplatform) + `kotlinx-coroutines-test` + **Turbine** for Flow + **Ktor MockEngine** for HTTP + **MockK** (JVM tests only) | `./gradlew allTests` |
| Coverage | **Kover** (Kotlin's multiplatform-friendly coverage tool, not JaCoCo) | `./gradlew koverHtmlReport koverVerify` |
| Security audit | **OWASP Dependency-Check** plugin | `./gradlew dependencyCheckAggregate` |
| API surface review | Binary-compatibility-validator (JetBrains plugin) | `./gradlew apiCheck` |
| Docs build (CI gate) | Dokka | `./gradlew dokkaHtmlMultiModule` |

`mojentic-kt/AGENTS.md` will codify the equivalent of the Rust port's mandatory pre-commit block:

```bash
./gradlew ktlintCheck detekt build allTests koverVerify dependencyCheckAggregate apiCheck
```

CI (GitHub Actions) runs on:
- `ubuntu-latest` for JVM + Android targets (Android SDK installed).
- `macos-latest` for iOS targets (Xcode + iOS simulators).
- Single Kotlin toolchain version, pinned via `gradle.properties`.

---

## 6. Documentation

| Library | Tool | Location |
|---|---|---|
| Kotlin | **Dokka v2** (HTML output) + handwritten Markdown guides | `mojentic-kt/docs/` (rendered to GitHub Pages) |

Dokka is the obvious choice — it's Kotlin's official documentation tool, supports KDoc, has multi-module aggregation, and ships an HTML format suitable for GitHub Pages.

Three-section layout mirroring the other ports:

- **Use Cases** (handwritten Markdown under `docs/use-cases/`): Building Chatbots, Structured Output, Building Agents, Image Analysis. Dokka v2 supports including arbitrary Markdown files in the rendered output via the `includes` configuration.
- **Examples**: one article per provided tool with extension guidance, emphasising "reference implementation, not core feature."
- **Core Concepts**: API reference auto-generated from KDoc comments on public symbols.

Deployment: GitHub Actions job runs `./gradlew dokkaHtmlMultiModule` and publishes the output to GitHub Pages on every `v*` tag.

---

## 7. Examples

All 26 shared examples (per PARITY.md §"Examples by Complexity Level") ported as individual Gradle subprojects under `examples/`. Each is independently runnable via `./gradlew :examples:simple-llm:run` and serves as integration coverage:

- Level 1: `simple-llm`, `list-models`, `simple-structured`, `simple-tool`
- Level 2: `broker-examples`, `streaming`, `chat-session`, `chat-session-with-tool`, `image-analysis`, `embeddings`, `current-datetime-tool`
- Level 3: `file-tool`, `coding-file-tool`, `broker-as-tool`, `ephemeral-task-manager`, `tell-user`, `ask-user`, `web-search`
- Level 4: `tracer-demo`
- Level 5: `async-llm`, `async-dispatcher`
- Level 6: `iterative-solver`, `recursive-agent`, `solver-chat-session`
- Level 7: `react`, `working-memory`

Each example targets JVM only by default (CLI executable via `application` plugin). Where an example demonstrates a feature that's meaningfully different on Android or iOS (e.g. file tools using scoped storage on Android), we add a small companion section in the matching Use Case guide rather than maintaining N copies of the example.

CI builds **all** examples on every commit — an example that doesn't compile is broken documentation.

---

## 8. Versioning & Release

- Major and minor versions stay synchronized with the other ports (per `mojentic-ru/AGENTS.md` Version Synchronization). Patch versions move independently.
- Initial release: `1.4.0` (current monorepo minor).
- Tagged releases (`v1.4.0`) trigger CI to (a) build all targets, (b) run gates, (c) sign and publish to Maven Central via `gradle-maven-publish-plugin` / Sonatype OSSRH, (d) generate XCFramework + push SPM manifest, (e) publish Dokka to GitHub Pages.
- A **BOM artifact** (`mojentic-bom`) is published alongside the modules so consumers can pin a single version line and get aligned per-module versions for free.
- The Swift Package Manager manifest for iOS consumption is committed to the same repo (or a small `mojentic-kt-spm` mirror) with versioned tags matching Maven releases.

**Required CI secrets**

- `MAVEN_CENTRAL_USERNAME` / `MAVEN_CENTRAL_PASSWORD` — Sonatype credentials.
- `SIGNING_KEY` / `SIGNING_PASSWORD` — PGP key for Maven Central signing.
- (Future) `COCOAPODS_TRUNK_TOKEN` if we publish to CocoaPods trunk.

---

## 9. Roadmap (Phased)

Each phase ends with a passing quality gate, tagged release, and an updated PARITY.md row.

### Phase 0 — Skeleton (1–2 days)
- Create `mojentic-kt/` with `settings.gradle.kts`, `build.gradle.kts`, `libs.versions.toml`, `AGENTS.md`, `CHARTER.md`, `README.md`, `CHANGELOG.md`, license, `detekt.yml`, `.editorconfig`.
- Empty `mojentic-core` module with JVM + Android + iOS targets configured; `Hello`-level test passing on all three.
- CI workflows (Linux for JVM/Android, macOS for iOS) running ktlint + detekt + build + tests.
- Maven Central publishing job wired (publishing to a `-SNAPSHOT` channel until first real release).
- Add Kotlin row to PARITY.md.

### Phase 1 — Core LLM (Ollama only)
- `LlmMessage`, `CompletionConfig`, `ReasoningEffort`, `MojenticException`.
- `LlmGateway` interface in core; `OllamaGateway` in `mojentic-ollama` module (complete, completeJson, streaming, tools).
- `LlmBroker` with non-streaming + streaming + recursive tool execution.
- `LlmTool` interface, `ToolDescriptor`, `SerialToolRunner`; `CurrentDateTimeTool`, `DateResolverTool`.
- `JsonSchemaGenerator` from `SerialDescriptor`.
- Examples: `simple-llm`, `list-models`, `simple-structured`, `simple-tool`, `streaming`.

### Phase 2 — OpenAI Gateway + ChatSession + Image Analysis
- `mojentic-openai` module: `OpenAIGateway`, `OpenAIMessageAdapter`, `OpenAIModelRegistry`.
- `ChatSession`.
- Multimodal `LlmMessage` content (image parts).
- `TokenizerGateway` + `EmbeddingsGateway` (JVM-first; bring-your-own on Native).
- Examples: `broker-examples`, `chat-session`, `chat-session-with-tool`, `image-analysis`, `embeddings`.

### Phase 3 — Tracer + Provided Tools
- `Tracer`, `NullTracer`, `EventStore`, full sealed-event union.
- Broker + tool runner integration with tracer.
- File tools (8) with `expect/actual` for platform-specific file I/O via okio.
- Task manager, AskUser, TellUser, WebSearch, ToolWrapper.
- `ParallelToolRunner`.
- Examples: `file-tool`, `coding-file-tool`, `broker-as-tool`, `ephemeral-task-manager`, `tell-user`, `ask-user`, `web-search`, `tracer-demo`.

### Phase 4 — Agent System
- `BaseAgent`, `BaseAsyncAgent`, `AsyncLlmAgent`, `AsyncAggregatorAgent`.
- `AsyncDispatcher`, `Router`, event types.
- `SharedWorkingMemory`.
- `IterativeProblemSolver`, `SimpleRecursiveAgent`, `ReActAgent`.
- Examples: `async-llm`, `async-dispatcher`, `iterative-solver`, `recursive-agent`, `solver-chat-session`, `react`, `working-memory`.

### Phase 5 — Realtime Voice
- `mojentic-realtime-openai` module.
- `RealtimeGateway` interface; `OpenAiRealtimeGateway` over Ktor WebSockets.
- `RealtimeVoiceBroker`, session, audio codec types.
- Server VAD + manual VAD; interruption / barge-in via coroutine cancellation; parallel tool calls in voice turns.
- Vendor-neutral `RealtimeEvent` union + raw-events escape hatch.

### Phase 6 — Anthropic Gateway
- `mojentic-anthropic` module: `AnthropicGateway` matching the Python feature set.

### Phase 7 — Documentation polish & 1.x stabilization
- Dokka tutorials for all four Use Cases.
- iOS XCFramework + SPM consumption verified end-to-end via a small sample iOS Xcode project (not shipped, used in CI smoke tests).
- Sample Android Compose app under `samples/` (NOT under `examples/`) showing a chat UI consuming the library — exists for documentation purposes only, not part of the library distribution.
- Binary-compatibility validator baselined.
- Release-candidate audit pass before bumping to a synchronized minor with the other ports.

---

## 10. Open Questions / Decisions Needed

These need a call before or during Phase 0:

1. **iOS distribution path.** SPM via XCFramework is the modern choice; CocoaPods is still common but declining. **Recommendation:** ship SPM as primary, evaluate CocoaPods demand post-MVP.
2. **JSON Schema generation source.** kotlinx.serialization's `SerialDescriptor` exposes everything needed but there isn't a single de-facto "schema generator" library in the ecosystem. **Recommendation:** implement a small `JsonSchemaGenerator` in `mojentic-core/internal/`. ~150–250 LOC, no external dep, walks the descriptor tree. Reassess if a community library matures.
3. **Tokenizer on Kotlin/Native (iOS).** `jtokkit` is JVM-only. Options: (a) ship JVM tokenizer only, iOS callers use server-side tokenization or skip token counting; (b) port the BPE algorithm to common Kotlin (substantial work). **Recommendation:** (a) for v1; expose `TokenizerGateway` so consumers can plug in their own iOS implementation if needed.
4. **Minimum Kotlin toolchain.** Proposed: **Kotlin 2.0+** for K2 compiler stability, standard-library UUIDs, and the latest KMP target shape. Anyone on 1.9.x stays on TS/Python/Rust until they upgrade.
5. **Minimum Android API level.** Proposed: **API 24 (Android 7.0)**. Driven by Ktor and coroutines' practical floor; covers >97% of devices in 2026.
6. **Minimum iOS deployment target.** Proposed: **iOS 14**. Driven by what current Kotlin/Native targets support comfortably.
7. **Logging facade.** `kotlin-logging` (Oshai's library) vs `KermitLog` vs a thin in-house facade. **Recommendation:** `kotlin-logging` — most adopted, JetBrains-friendly, SLF4J bridge on JVM.
8. **Repo location.** Mirrors current convention — likely `svetzal/mojentic-kt` to match `mojentic-ru` naming. Monorepo references it as `mojentic-kt/` submodule.
9. **Submodule vs vendored.** The other ports are git submodules of the monorepo. Kotlin port follows the same model.
10. **Dependency-update automation.** Renovate or Dependabot? Both work for Gradle. **Recommendation:** Renovate — better at multi-module catalog updates.
11. **Multiplatform realtime audio in examples.** The realtime examples need *some* audio source to be runnable. Options: (a) examples are JVM-only and use a `.wav` file → speaker via Java Sound API; (b) write platform-specific example sub-projects for Android (AudioRecord) and iOS (AVAudioEngine). **Recommendation:** (a) for the in-repo example; document the platform-specific capture story in the realtime Use Case guide.

---

## 11. Cross-Port Coordination Impact

Adopting this plan will require updates to:

- **`PARITY.md`** — add a Kotlin column to every table; status all `📝 Planned` initially. Coordinate with the Swift port plan if both go ahead in parallel. Note the Kotlin-specific deltas to flag once shipped:
  - **Tokenizer Gateway** will be ⚠️ partial after Phase 2 (JVM/Android only via jtokkit; Kotlin/Native consumers must inject their own implementation through the `TokenizerGateway` interface). All other shipping ports are ✅.
  - **Gateway packaging** is split across separate Gradle modules (`mojentic-core`, `mojentic-ollama`, `mojentic-openai`, `mojentic-anthropic`, `mojentic-realtime-openai`) rather than a single artifact. PARITY.md tracks features, not artifacts — no per-module column needed, but reviewers should know to look across modules when validating a row.
  - **`mojentic-bom`** is a Kotlin-ecosystem-only artifact for cross-module version alignment; no analogue exists in other ports and PARITY.md should not track it.
- **`AGENTS.md` (monorepo root)** — add `mojentic-kt/` row to the sub-project table, alongside `mojentic-sw/`.
- **`mojentic-py/CHARTER.md`** and friends — no change required; Kotlin is downstream of the Python reference.
- A new `mojentic-kt/AGENTS.md` codifying the Kotlin quality gates and patterns above, modelled on `mojentic-ru/AGENTS.md` and the `kotlin-craftsperson` agent's quality philosophy.

No code changes to the four existing ports are anticipated unless this planning surfaces an API inconsistency in the reference implementation worth resolving across the board.

---

## 12. Why Kotlin Multiplatform (vs JVM-only or Android-only)

The user's stated requirement is *Android / iOS parity*. The two viable strategies were:

| Strategy | Pro | Con |
|---|---|---|
| **JVM library** consumed via Kotlin/Native interop or duplicated in Swift | Simpler build | Doesn't actually solve iOS — you'd still need a Swift port for iOS code. Defeats the purpose. |
| **Kotlin Multiplatform (KMP)** with `commonMain` + platform actuals | One codebase, one set of semantics, one set of tests covering both platforms. Lets Android and iOS teams share business logic. | More complex Gradle setup; iOS distribution is XCFramework + SPM rather than a single jar. |

KMP wins because it directly addresses the stated requirement. The "platform actuals" surface in Mojentic is genuinely small — file I/O (handled by okio), HTTP transport (handled by Ktor engines), WebSocket transport (handled by Ktor engines), logging (handled by kotlin-logging). Everything else is pure `commonMain` Kotlin.

If a consumer team only ever wants JVM, the KMP library still works — they just depend on the `mojentic-core-jvm` artifact, same as any other JVM library. KMP doesn't penalise single-platform consumers.

If a Swift port (`SWIFT.md`) also goes ahead, there's some duplication of effort. The decision matrix is:

- **Pure Swift port (SWIFT.md)** is the right choice for Apple-platform-native developers who write Swift, value SwiftUI/Combine integration, and prefer the Swift idiom.
- **Kotlin Multiplatform port (this doc)** is the right choice for cross-platform mobile teams sharing business logic between Android and iOS, where iOS app code consumes Kotlin via SPM.

Both can coexist; they serve different consumer profiles. PARITY.md will track both independently.

---

*This document is a planning artifact. Once Phase 0 ships, day-to-day Kotlin work tracks under `mojentic-kt/AGENTS.md` and PARITY.md, and this file becomes a historical reference.*
