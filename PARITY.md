# Mojentic Feature Parity Matrix

This document tracks **differences and incomplete work** across the four Mojentic implementations.

**Legend:**
- ✅ Complete
- ⚠️ Partial
- ❌ Not Started
- 📝 Planned

Last Updated: May 18, 2026 (mojentic-kt: **Phase 4 ✅ shipped — slice C added `ReActAgent` (single-class reasoning loop) plus seven new examples: `async-llm`, `recursive-agent`, `solver-chat-session`, `react`, `working-memory`, `coding-file-tool`, `broker-as-tool`**). Previously: mojentic-kt Phase 4 slices A + B (`Event` / `Agent` / `Router` / `AsyncDispatcher`, `BaseAsyncLlmAgent`, `ToolWrapper`, `SharedWorkingMemory`, `AsyncAggregatorAgent`, `IterativeProblemSolver`, `SimpleRecursiveAgent`, `agent-dispatcher`, `iterative-solver`); Phase 3-C (FilesystemGateway + 8 file tools + WebSearch + SerpApi); Phase 3-B (AskUser / TellUser tools + EphemeralTaskList + task tools); Phase 3-A (TracerSystem + ParallelToolRunner); Phase 2 (OpenAI gateway, ChatSession, Tokenizer/Embeddings); mojentic-sw Phase 7 (Swift port complete at v1.4.0).

---

## What's Complete (Uniform Across All Ports)

These features are **fully implemented in Python, Elixir, Rust, TypeScript, and Swift** (Kotlin port: Phase 2 shipped — see KOTLIN.md for remaining phases):

- **Layer 1 (LLM Integration)**: Broker, CompletionConfig, reasoning effort control, OpenAI + Ollama gateways, structured output, tool calling, streaming with recursive tool execution, streaming chat sessions, image analysis, tokenizer, embeddings
- **Layer 2 (Tracer System)**: Event recording, correlation tracking, event filtering, broker/tool integration
- **Layer 3 (Agent System - Core)**: Base agents, async agents, event system, dispatcher, router, aggregators, iterative solver, recursive agent, ReAct pattern, shared working memory
- **Tools**: DateResolver, File tools (8 tools), Task manager, Tell user, Ask user, Web search, Current datetime, Tool wrapper (broker as tool)
- **Examples**: 26 shared examples implemented across all ports (Python, Elixir, Rust, TypeScript)
- **Infrastructure**: Full test suites, zero lint warnings, CI/CD pipelines, documentation

---

## Detailed Feature Reference

This section provides comprehensive feature tables for implementing new ports (e.g., Swift).

### Layer 1: LLM Integration

#### Core Broker & Gateway

| Feature | Python | Elixir | Rust | TypeScript | Swift | Kotlin | Notes |
| --------- | -------- | -------- | ------ | ------------ | ------- | ------- | ------- |
| **LLM Broker** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Core interface for LLM interactions |
| **Gateway Trait/Behaviour** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Abstract interface for providers |
| **Text Generation** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Basic completion API |
| **Structured Output** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | JSON schema-based responses |
| **Streaming Responses** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Ollama with full recursive tool execution |
| **Tool Calling** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Recursive tool execution |
| **Message History** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Conversation context |
| **Correlation IDs** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Request tracing (Kotlin: opaque `String?` to avoid leaking experimental `kotlin.uuid.Uuid`) |
| **CompletionConfig** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Unified config object for LLM parameters |
| **Reasoning Effort** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | low/medium/high reasoning effort control |
| **Thinking Traces** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Model reasoning traces in gateway response |

#### Gateway Implementations

| Gateway | Python | Elixir | Rust | TypeScript | Swift | Kotlin | Notes |
| --------- | -------- | -------- | ------ | ------------ | ------- | ------- | ------- |
| **OpenAI** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Full featured (Kotlin: `mojentic-openai` module, Ktor Client, JSON schema response format, SSE streaming, parallel tool calls, reasoning effort for o-series) |
| **Ollama** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Full impl with streaming |
| **Anthropic (Claude)** | ✅ | ❌ | ❌ | 📝 | ✅ | 📝 | Python + Swift (Swift: behind `anthropic` package trait); TypeScript planned |
| **File Gateway** | ✅ | ❌ | ❌ | ❌ | ❌ | 📝 | Python: file-based mocking |
| **Tokenizer Gateway** | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | Token counting (Swift: approximate `chars/4` default; bring-your-own protocol. Kotlin: JVM-only `JtokkitTokenizerGateway` shipped in `mojentic-openai`; Kotlin/Native consumers inject their own implementation) |
| **Embeddings Gateway** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Vector embeddings (Kotlin: `OpenAIEmbeddingsGateway`) |

#### Ollama Gateway Features

| Feature | Python | Elixir | Rust | TypeScript | Swift | Kotlin |
| --------- | -------- | -------- | ------ | ------------ | ------- | ------- |
| Chat Completions | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Structured Output | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Tool Calling | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Streaming | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Streaming + Tools | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Image Analysis | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Model Listing | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Embeddings | ✅ | ✅ | ✅ | ✅ | ✅ | 📝 |
| Message Adaptation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Reasoning Effort (think) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Thinking Traces | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

#### Message System

| Feature | Python | Elixir | Rust | TypeScript | Swift | Kotlin | Notes |
| --------- | -------- | -------- | ------ | ------------ | ------- | ------- | ------- |
| **Message Types** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | System, User, Assistant, Tool |
| **Multimodal (Images)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Image content in messages |
| **Tool Call Messages** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Tool request/response |
| **Message Composers** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Helper builders (Kotlin: `LlmMessage.system/user/assistant/tool` factories) |
| **Content Annotations** | ✅ | ❌ | ❌ | ❌ | ❌ | 📝 | Python-only: metadata |
| **Audience Targeting** | ✅ | ❌ | ❌ | ❌ | ❌ | 📝 | Python-only: routing |
| **Priority System** | ✅ | ❌ | ❌ | ❌ | ❌ | 📝 | Python-only: importance |

#### Tool System

| Feature | Python | Elixir | Rust | TypeScript | Swift | Kotlin | Notes |
| --------- | -------- | -------- | ------ | ------------ | ------- | ------- | ------- |
| **Tool Trait/Behaviour** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Base interface |
| **Tool Descriptors** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | JSON schema definitions |
| **Tool Execution** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Kotlin: `suspend fun execute(arguments)` |
| **Parallel Tool Execution** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | `ToolRunner` abstraction; serial default for the chat broker; Kotlin: `ParallelToolRunner` opt-in (Phase 3-A) |
| **Tool Cancellation (AbortSignal)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Idiomatic per language: asyncio.Event / Task.shutdown / CancellationToken / AbortSignal / Swift Task.checkCancellation / Kotlin coroutine cancellation |
| **Tool Wrapper** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Agent as tool (delegation) |
| **Date Resolver Tool** | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | Natural language dates (Kotlin: Phase 1 minimal parser — today/tomorrow/yesterday/in N units/N units ago/next-or-last weekday/ISO passthrough. No full `parsedatetime` equivalent on Native yet.) |
| **Current DateTime Tool** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Current time access |
| **File Tools (8 tools)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Read/Write/List/etc. Kotlin: sandboxed `FilesystemGateway` + okio-backed impl; `fileToolsFor(fs)` |
| **Task Manager Tool** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Ephemeral tasks; Kotlin: `EphemeralTaskList` + 7 tools via `taskToolsFor(list)` |
| **Ask User Tool** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Interactive input; Kotlin: `AskUserTool` + `UserInteractionGateway`, JVM `ConsoleUserInteractionGateway` |
| **Tell User Tool** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | User output; same gateway abstraction as ask_user |
| **Web Search Tool** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Organic search; Kotlin: `WebSearchGateway` + `OrganicWebSearchTool`, SerpApi-backed gateway in `mojentic-websearch-serpapi` |

#### Chat Session

| Feature | Python | Elixir | Rust | TypeScript | Swift | Kotlin | Notes |
| --------- | -------- | -------- | ------ | ------------ | ------- | ------- | ------- |
| **Session Management** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Conversation state (Kotlin: `Mutex`-protected history, atomic update + rollback) |
| **Message History** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Context retention |
| **Context Window** | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | Token limit management (Kotlin: `TokenizerGateway` interface ships in Phase 2; ChatSession doesn't auto-trim yet) |
| **System Prompts** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Initial instructions |
| **Tool Integration** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Session-level tools |
| **Streaming Send** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Stream responses with auto history management |

### Layer 2: Tracer System

| Feature | Python | Elixir | Rust | TypeScript | Swift | Kotlin | Notes |
| --------- | -------- | -------- | ------ | ------------ | ------- | ------- | ------- |
| **Tracer System** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Event recording |
| **Event Store** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Event persistence; Kotlin: `Mutex`-protected buffer + `SharedFlow` live stream |
| **Event Types** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | LLM/Tool/Agent events; Kotlin: `sealed interface TracerEvent` |
| **Null Tracer** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Null object pattern |
| **Correlation Tracking** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Request correlation |
| **Performance Metrics** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Duration tracking (kotlin.time.Duration) |
| **Event Querying** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Filter/search events (type / time-window / predicate / getLastN) |
| **LLM Call Events** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Call tracking |
| **LLM Response Events** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Response tracking |
| **Tool Call Events** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Tool invocation tracking |
| **Tool Batch Events** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Aggregate per-batch stats (parallel runner) |
| **Agent Events** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Agent lifecycle; Kotlin: `AgentInteractionEvent` emitted by `AsyncDispatcher` |

### Layer 4: Realtime Voice

| Feature | Python | Elixir | Rust | TypeScript | Swift | Kotlin | Notes |
| --------- | -------- | -------- | ------ | ------------ | ------- | ------- | ------- |
| **RealtimeVoiceBroker** | ✅ | ✅ | ✅ | ✅ | ✅ | 📝 | Sibling to LlmBroker |
| **OpenAI Realtime Gateway** | ✅ | ✅ | ✅ | ✅ | ✅ | 📝 | WebSocket transport |
| **Server VAD turn detection** | ✅ | ✅ | ✅ | ✅ | ✅ | 📝 |  |
| **Manual VAD / push-to-talk** | ✅ | ✅ | ✅ | ✅ | ✅ | 📝 | turn_detection: 'none' |
| **Interruption / barge-in** | ✅ | ✅ | ✅ | ✅ | ✅ | 📝 | Manual + speech_started; Elixir: async Task keeps GenServer responsive; Swift: cooperative Task cancellation |
| **Parallel tool calls in voice turn** | ✅ | ✅ | ✅ | ✅ | ✅ | 📝 | Inherits ParallelToolRunner |
| **Vendor-neutral event union** | ✅ | ✅ | ✅ | ✅ | ✅ | 📝 | RealtimeEvent enum / struct + raw access |
| **Raw event escape hatch** | ✅ | ✅ | ✅ | ✅ | ✅ | 📝 | session.raw_events() / rawEvents() / transport pid |
| **Audio in/out streams** | ✅ | ✅ | ✅ | ✅ | ✅ | 📝 | numpy int16 / binary PCM16 / Vec<i16> / Int16Array / Swift [Int16] @ 24kHz |
| **Tool cancellation on interrupt** | ✅ | ✅ | ✅ | ✅ | ✅ | 📝 | asyncio.Event / atomics ref (wired to interrupt/1) / CancellationToken / AbortSignal / Swift Task.cancel |

### Layer 3: Agent System

#### Core Agent Infrastructure

| Feature | Python | Elixir | Rust | TypeScript | Swift | Kotlin | Notes |
| --------- | -------- | -------- | ------ | ------------ | ------- | ------- | ------- |
| **Base Agent** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Agent trait/interface (Kotlin: single `Agent` interface; `suspend` collapses sync/async) |
| **Base Async Agent** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Async agent support (Kotlin/Swift: async-first — single surface) |
| **Base LLM Agent** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | LLM-enabled agents (Kotlin: `BaseAsyncLlmAgent`; Swift: `AsyncLLMAgent`) |
| **AgentEventAdapter** | ✅ | ❌ | ❌ | ❌ | ❌ | 📝 | Event-driven agent wrapper |
| **Event System** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Event types (Kotlin: `Event` / `TerminateEvent`) |
| **Dispatcher** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Event routing (Kotlin/Swift: async-first — covered by `AsyncDispatcher`) |
| **Async Dispatcher** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Async event processing (Kotlin: coroutine queue + `TerminateEvent` shutdown) |
| **Router** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Event-to-agent routing (Kotlin: `KClass<out Event>`-keyed) |
| **Shared Working Memory** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Context sharing (Kotlin: `Mutex`-protected `Map<String, JsonElement>`) |

#### Agent Implementations

| Agent Type | Python | Elixir | Rust | TypeScript | Swift | Kotlin | Notes |
| ------------ | -------- | -------- | ------ | ------------ | ------- | ------- | ------- |
| **Async LLM Agent** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | LLM with async processing (Kotlin: `BaseAsyncLlmAgent`) |
| **Async Aggregator Agent** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Result aggregation (Kotlin: `AsyncAggregatorAgent` keyed by correlationId) |
| **Iterative Problem Solver** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Multi-step reasoning (Kotlin: chat-session loop with DONE/FAIL termination) |
| **Simple Recursive Agent** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Self-recursive processing (Kotlin: `SolverEvent` history + `withTimeoutOrNull`) |
| **ReAct Pattern** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Reasoning + Acting (Swift: collapses Thought/Action/Observation into broker's recursive tool loop with ReAct system prompt; Kotlin: single-class `ReActAgent` with `FINAL ANSWER:` marker, reuses broker's recursive tool dispatch) |

### Examples by Complexity Level

#### Level 1: Basic LLM Usage

| Example | Description | Dependencies |
|---------|-------------|--------------|
| **simple_llm** | Basic text generation | Broker, Gateway |
| **list_models** | List available models | Gateway |
| **simple_structured** | Schema-based structured output | Broker, JSON Schema |
| **simple_tool** | Single tool usage (DateResolver) | Broker, Tool system |

#### Level 2: Advanced LLM Features

| Example | Description | Dependencies |
|---------|-------------|--------------|
| **broker_examples** | Comprehensive broker features | All broker features |
| **streaming** | Streaming with tool support | Streaming API |
| **chat_session** | Interactive chat | ChatSession |
| **chat_session_with_tool** | Chat with tools | ChatSession, Tools |
| **image_analysis** | Multimodal image analysis | Vision models |
| **embeddings** | Vector embeddings | Embeddings API |
| **current_datetime_tool** | DateTime tool demo | CurrentDateTimeTool |

#### Level 3: Tool System & Extensions

| Example | Description | Dependencies |
|---------|-------------|--------------|
| **file_tool** | File operations | File tools |
| **coding_file_tool** | Code-aware file ops | File tools |
| **broker_as_tool** | Broker as tool (delegation) | Tool wrapping |
| **ephemeral_task_manager** | Task management | TaskManager |
| **tell_user** | User communication | TellUser tool |
| **ask_user** | User input | AskUser tool |
| **web_search** | Web search | WebSearch tool |

#### Level 4: Tracing & Observability

| Example | Description | Dependencies |
|---------|-------------|--------------|
| **tracer_demo** | Tracer system demo | TracerSystem |

#### Level 5: Agent System Basics

| Example | Description | Dependencies |
|---------|-------------|--------------|
| **async_llm** | Async LLM agents | AsyncDispatcher, Agents |
| **async_dispatcher** | Event routing | AsyncDispatcher, Router |

#### Level 6: Advanced Agent Patterns

| Example | Description | Dependencies |
|---------|-------------|--------------|
| **iterative_solver** | Multi-iteration solving | IterativeProblemSolver |
| **recursive_agent** | Self-recursive agent | SimpleRecursiveAgent |
| **solver_chat_session** | Interactive solver | Solver + ChatSession |

#### Level 7: Multi-Agent & Specialized

| Example | Description | Dependencies |
|---------|-------------|--------------|
| **react** | ReAct pattern | ReAct agent |
| **working_memory** | Shared memory | SharedWorkingMemory |

---

## Remaining Differences

### Gateway Coverage

| Gateway | Python | Elixir | Rust | TypeScript | Swift | Kotlin | Notes |
| --------- | -------- | -------- | ------ | ------------ | ------- | ------- | ------- |
| **Anthropic** | ✅ | ❌ | ❌ | 📝 | 📝 | 📝 | Python-only currently; TypeScript planned |
| **File Gateway** | ✅ | ❌ | ❌ | ❌ | ❌ | 📝 | Python: file-based mocking for tests |

### Message Features (Python-only)

| Feature | Python | Others | Swift | Kotlin | Notes |
| --------- | -------- | -------- | ------- | ------- | ------- |
| Content Annotations | ✅ | ❌ | ❌ | 📝 | Message metadata |
| Audience Targeting | ✅ | ❌ | ❌ | 📝 | Message routing |
| Priority System | ✅ | ❌ | ❌ | 📝 | Message importance levels |

### Advanced Features

| Feature | Python | Elixir | Rust | TypeScript | Swift | Kotlin |
| --------- | -------- | -------- | ------ | ------------ | ------- | ------- |
| AgentEventAdapter | ✅ | ❌ | ❌ | ❌ | ❌ | 📝 |
| Configuration Files | ✅ | 📝 | ⚠️ | 📝 | ❌ | 📝 |
| Builder Pattern | ✅ | ❌ | ⚠️ | 📝 | ❌ | 📝 |
| Connection Pooling | ⚠️ | 📝 | ⚠️ | 📝 | ❌ | 📝 |
| Retry Logic | ⚠️ | ❌ | ❌ | ❌ | ❌ | 📝 |

### Python-Only Examples

These utility scripts exist only in Python and are not planned for other ports:

- `ensures_files_exist.py` - File existence verification
- `raw.py` - Raw gateway debugging
- `characterize_ollama.py` / `characterize_openai.py` - Gateway characterization
- `fetch_openai_models.py` - Model metadata fetching
- `model_characterization.py` - Model benchmarking
- `oversized_embeddings.py` - Embedding size testing
- `design_analysis.py` / `file_deduplication.py` - Analysis utilities
- `broker_image_examples.py` / `image_broker*.py` - Specialized image demos
- `openai_gateway_enhanced_demo.py` - OpenAI feature demo
- `simple_llm_repl.py` - REPL interface
- `tracer_qt_viewer.py` - Qt GUI for tracer events
- `routed_send_response.py` - Complex routing patterns

---

## Documentation Philosophy

The Mojentic documentation follows a structured approach that emphasizes learning through practical use cases while maintaining comprehensive API reference material.

### Core Principles

1. **Tools as Examples**: Provided tools (File Tools, Task Management, Web Search) are reference implementations demonstrating how to build custom tools, not core library features.
2. **Use Cases First**: Documentation is organized around practical tutorials that guide users through complete scenarios.
3. **Self-Contained Tutorials**: Each use case guide includes all necessary context, imports, and explanations without requiring navigation across multiple pages.
4. **Clear Separation**: Documentation is structured into distinct sections:
   - **Use Cases**: Complete, tutorial-style guides for common scenarios
   - **Examples**: Reference implementations of tools and patterns
   - **Core Concepts**: API documentation and technical details

### Documentation Structure

Each library's documentation site includes:

| Section | Purpose | Content Type |
|---------|---------|--------------|
| **Use Cases** | Learning path for common scenarios | Self-contained tutorials with Why/When/How structure |
| **Examples** | Reference implementations | Code examples with explanations |
| **Core Concepts** | API reference | Technical documentation of library features |

### Use Case Coverage

Each library provides tutorials for these core use cases:

| Use Case | Description | Key Features Demonstrated |
|----------|-------------|--------------------------|
| **Building Chatbots** | Creating conversational agents with context | Chat sessions, message history, system prompts |
| **Structured Output** | Extracting data from unstructured text | Schema definition, JSON validation, type safety |
| **Building Agents** | Creating autonomous problem-solving systems | Tool usage, reasoning loops, multi-step execution |
| **Image Analysis** | Working with multimodal inputs | Vision models, image processing |

### Library-Specific Documentation Adherence

| Library | Use Cases Section | Examples Section | Tutorial Format | Self-Contained | Notes |
|---------|------------------|------------------|-----------------|----------------|-------|
| **Python** | ✅ | ✅ | ✅ | ✅ | Reference implementation; most comprehensive |
| **Elixir** | ✅ | ✅ | ✅ | ✅ | Uses ExDoc with grouped extras |
| **Rust** | ✅ | ✅ | ✅ | ✅ | Uses mdBook with chapter organization |
| **TypeScript** | ✅ | ✅ | ✅ | ✅ | Uses VitePress with sidebar navigation |
| **Swift** | ✅ | ✅ | ✅ | ✅ | DocC catalog shipped per SWIFT.md §6 |
| **Kotlin** | 📝 | 📝 | 📝 | 📝 | Dokka v2 + handwritten Markdown; structure planned in KOTLIN.md §6 |

### Documentation Tooling

| Library | Tool | Config File | Structure |
|---------|------|-------------|-----------|
| **Python** | MkDocs | `mkdocs.yml` | Navigation-based sections |
| **Elixir** | ExDoc | `mix.exs` | Grouped extras with regex patterns |
| **Rust** | mdBook | `book/src/SUMMARY.md` | Chapter-based hierarchy |
| **TypeScript** | VitePress | `docs/.vitepress/config.mts` | Sidebar item groups |
| **Swift** | DocC | `Sources/Mojentic/Mojentic.docc/` | DocC tutorials + auto-generated API reference |
| **Kotlin** (📝 Planned) | Dokka v2 | `mojentic-kt/docs/` | Dokka multi-module HTML + handwritten Markdown use-case guides |

### Example Tool Documentation

All provided tools are documented as examples with emphasis on extensibility:

| Tool Category | Python | Elixir | Rust | TypeScript | Swift | Kotlin | Presentation |
| --------------- | -------- | -------- | ------ | ------------ | ------- | ------- | -------------- |
| **File Tools** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | "Example: File Tools" (Kotlin: `examples/file-tool`) |
| **Task Management** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | "Example: Task Management" (Kotlin: `examples/ephemeral-task-manager`) |
| **Web Search** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | "Example: Web Search" (Kotlin: `examples/web-search`) |

Each example guide includes:
- Introduction emphasizing it's a reference implementation
- Description of what the tool demonstrates
- Complete usage examples
- Guidance on customization and extension

---

## Philosophical Differences: Data Modeling Approaches

The three implementations represent fundamentally different approaches to working with data, each with distinct advantages:

### Python: Runtime Validation (Pydantic)
**Philosophy**: Trust but verify at runtime
- Classes with rich validation logic
- Runtime type coercion and conversion
- Detailed error messages for invalid data
- Schema generation from classes

**Example Mindset**:
```python
class Message(BaseModel):
    role: str
    content: str

    @field_validator('role')
    def validate_role(cls, v):
        if v not in ['user', 'assistant', 'system']:
            raise ValueError('Invalid role')
        return v
```

### Elixir: Data Transformation ("Thinking in Data")
**Philosophy**: Data flows through transformations; structure emerges from use
- Plain maps and structs without behavior
- Pattern matching for destructuring and validation
- Pipelines transform data through functions
- Shape is validated by usage, not declaration
- Guards and pattern matching provide implicit contracts

**Example Mindset**:
```elixir
# Data is just data - structs are lightweight
%Message{role: :user, content: "Hello"}

# Pattern matching validates structure through use
def handle_message(%Message{role: :user, content: content}) when is_binary(content) do
  # Compiler ensures we handle the shape we expect
  process_user_message(content)
end

# Data transformations in pipelines
messages
|> Enum.filter(&match?(%{role: :user}, &1))
|> Enum.map(&Message.from_map/1)
|> validate_messages()
```

**Key Insight**: Elixir doesn't validate data against schemas - it uses pattern matching to destructure it. If the pattern doesn't match, the function clause doesn't fire. This is "thinking in data" - the shape of data determines program flow, not types per se.

### Rust: Compile-Time Guarantees
**Philosophy**: Invalid states unrepresentable
- Strong static typing with zero-cost abstractions
- Enum variants encode state transitions
- Type system prevents entire classes of bugs
- Traits define behavior contracts

**Example Mindset**:
```rust
enum MessageRole {
    User,
    Assistant,
    System,
}

struct Message {
    role: MessageRole,  // Can ONLY be valid roles
    content: String,
}

// Invalid state cannot be constructed
// let msg = Message { role: "invalid", content: "..." }; // Compile error!
```

### Comparison Summary

| Aspect | Python (Pydantic) | Elixir (Pattern Matching) | Rust (Type System) |
|--------|-------------------|--------------------------|-------------------|
| **When validated** | Runtime | At usage (pattern match) | Compile time |
| **Invalid data** | Throws exception | Function clause doesn't match | Cannot compile |
| **Flexibility** | Very high | High | Lower (by design) |
| **Performance** | Validation overhead | Minimal overhead | Zero overhead |
| **Philosophy** | "Trust but verify" | "Let it crash / flow" | "Make invalid states unrepresentable" |
| **Learning curve** | Gentle | Moderate | Steep |
| **Refactoring** | Tests catch issues | Pattern match exhaustiveness warnings | Compiler catches issues |
| **Best for** | Rapid development, external APIs | Concurrent systems, data pipelines | Systems programming, critical correctness |

### Why Elixir's Approach Matters

Elixir's "thinking in data" philosophy means:

1. **Data is separate from behavior**: Structs hold data, modules transform it
2. **Pattern matching is your validator**: If data doesn't match, function won't execute
3. **Pipelines over mutation**: Data flows through transformations
4. **Let it crash**: Don't defensively validate everything - match what you expect
5. **Implicit contracts**: Function signatures and pattern matches define what data shapes are accepted

This leads to code that's often clearer about what shapes of data it expects and handles, without needing explicit validation code:

```elixir
# These patterns ARE the validation
def process({:ok, %{data: data}}), do: transform(data)
def process({:error, reason}), do: handle_error(reason)
def process(_), do: {:error, :invalid_format}
```

---

## Test & Quality Snapshot

| Port | Tests | Coverage | Lint Warnings | Security |
|------|-------|----------|---------------|----------|
| Python | 227 | ~63% | 0 (flake8) | pip-audit (network-blocked) |
| Elixir | 634 | 81.56% | 0 (Credo) | mix deps.audit clean |
| Rust | 365+ | tarpaulin | 0 (clippy) | cargo deny (non-blocking warnings) |
| TypeScript | 656 | Jest | 0 (ESLint) | npm audit clean |
| Swift | 118 (through Phase 6) | not yet measured | 0 (swift-format strict); SwiftLint via CI | Dependabot (CI) |
| Kotlin | 144 (through Phase 2) | not yet measured | 0 (ktlint strict; Detekt now scans every KMP source set) | 📝 Phase 3+ (OWASP Dependency-Check planned) |

---

## Glossary

- **✅ Complete**: Feature is fully implemented and tested
- **⚠️ Partial**: Feature exists but incomplete or has limitations
- **❌ Not Started**: Feature not yet begun
- **📝 Planned**: Feature documented in plan but not implemented

---

*This document is maintained alongside ELIXIR.md, RUST.md, TYPESCRIPT.md, SWIFT.md, and KOTLIN.md.*
