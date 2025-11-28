# Mojentic Feature Parity Matrix

This document tracks **differences and incomplete work** across the four Mojentic implementations.

**Legend:**
- ✅ Complete
- ⚠️ Partial
- ❌ Not Started
- 📝 Planned

Last Updated: November 25, 2025

---

## What's Complete (Uniform Across All Ports)

These features are **fully implemented in Python, Elixir, Rust, and TypeScript**:

- **Layer 1 (LLM Integration)**: Broker, OpenAI + Ollama gateways, structured output, tool calling, streaming with recursive tool execution, image analysis, tokenizer, embeddings
- **Layer 2 (Tracer System)**: Event recording, correlation tracking, event filtering, broker/tool integration
- **Layer 3 (Agent System - Core)**: Base agents, async agents, event system, dispatcher, router, aggregators, iterative solver, recursive agent, ReAct pattern, shared working memory
- **Tools**: DateResolver, File tools (8 tools), Task manager, Tell user, Ask user, Web search, Current datetime, Tool wrapper (broker as tool)
- **Examples**: 24 shared examples implemented across all ports
- **Infrastructure**: Full test suites, zero lint warnings, CI/CD pipelines, documentation

---

## Detailed Feature Reference

This section provides comprehensive feature tables for implementing new ports (e.g., Swift).

### Layer 1: LLM Integration

#### Core Broker & Gateway

| Feature | Python | Elixir | Rust | TypeScript | Notes |
|---------|--------|--------|------|------------|-------|
| **LLM Broker** | ✅ | ✅ | ✅ | ✅ | Core interface for LLM interactions |
| **Gateway Trait/Behaviour** | ✅ | ✅ | ✅ | ✅ | Abstract interface for providers |
| **Text Generation** | ✅ | ✅ | ✅ | ✅ | Basic completion API |
| **Structured Output** | ✅ | ✅ | ✅ | ✅ | JSON schema-based responses |
| **Streaming Responses** | ✅ | ✅ | ✅ | ✅ | Ollama with full recursive tool execution |
| **Tool Calling** | ✅ | ✅ | ✅ | ✅ | Recursive tool execution |
| **Message History** | ✅ | ✅ | ✅ | ✅ | Conversation context |
| **Correlation IDs** | ✅ | ✅ | ✅ | ✅ | Request tracing |

#### Gateway Implementations

| Gateway | Python | Elixir | Rust | TypeScript | Notes |
|---------|--------|--------|------|------------|-------|
| **OpenAI** | ✅ | ✅ | ✅ | ✅ | Full featured |
| **Ollama** | ✅ | ✅ | ✅ | ✅ | Full impl with streaming |
| **Anthropic (Claude)** | ✅ | ❌ | ❌ | 📝 | Python only; TypeScript planned |
| **File Gateway** | ✅ | ❌ | ❌ | ❌ | Python: file-based mocking |
| **Tokenizer Gateway** | ✅ | ✅ | ✅ | ✅ | Token counting |
| **Embeddings Gateway** | ✅ | ✅ | ✅ | ✅ | Vector embeddings |

#### Ollama Gateway Features

| Feature | Python | Elixir | Rust | TypeScript |
|---------|--------|--------|------|------------|
| Chat Completions | ✅ | ✅ | ✅ | ✅ |
| Structured Output | ✅ | ✅ | ✅ | ✅ |
| Tool Calling | ✅ | ✅ | ✅ | ✅ |
| Streaming | ✅ | ✅ | ✅ | ✅ |
| Streaming + Tools | ✅ | ✅ | ✅ | ✅ |
| Image Analysis | ✅ | ✅ | ✅ | ✅ |
| Model Listing | ✅ | ✅ | ✅ | ✅ |
| Embeddings | ✅ | ✅ | ✅ | ✅ |
| Message Adaptation | ✅ | ✅ | ✅ | ✅ |

#### Message System

| Feature | Python | Elixir | Rust | TypeScript | Notes |
|---------|--------|--------|------|------------|-------|
| **Message Types** | ✅ | ✅ | ✅ | ✅ | System, User, Assistant, Tool |
| **Multimodal (Images)** | ✅ | ✅ | ✅ | ✅ | Image content in messages |
| **Tool Call Messages** | ✅ | ✅ | ✅ | ✅ | Tool request/response |
| **Message Composers** | ✅ | ✅ | ✅ | ✅ | Helper builders |
| **Content Annotations** | ✅ | ❌ | ❌ | ❌ | Python-only: metadata |
| **Audience Targeting** | ✅ | ❌ | ❌ | ❌ | Python-only: routing |
| **Priority System** | ✅ | ❌ | ❌ | ❌ | Python-only: importance |

#### Tool System

| Feature | Python | Elixir | Rust | TypeScript | Notes |
|---------|--------|--------|------|------------|-------|
| **Tool Trait/Behaviour** | ✅ | ✅ | ✅ | ✅ | Base interface |
| **Tool Descriptors** | ✅ | ✅ | ✅ | ✅ | JSON schema definitions |
| **Tool Execution** | ✅ | ✅ | ✅ | ✅ | Synchronous execution |
| **Tool Wrapper** | ✅ | ✅ | ✅ | ✅ | Agent as tool (delegation) |
| **Date Resolver Tool** | ✅ | ✅ | ✅ | ✅ | Natural language dates |
| **Current DateTime Tool** | ✅ | ✅ | ✅ | ✅ | Current time access |
| **File Tools (8 tools)** | ✅ | ✅ | ✅ | ✅ | Read/Write/List/etc. |
| **Task Manager Tool** | ✅ | ✅ | ✅ | ✅ | Ephemeral tasks |
| **Ask User Tool** | ✅ | ✅ | ✅ | ✅ | Interactive input |
| **Tell User Tool** | ✅ | ✅ | ✅ | ✅ | User output |
| **Web Search Tool** | ✅ | ✅ | ✅ | ✅ | Organic search |

#### Chat Session

| Feature | Python | Elixir | Rust | TypeScript | Notes |
|---------|--------|--------|------|------------|-------|
| **Session Management** | ✅ | ✅ | ✅ | ✅ | Conversation state |
| **Message History** | ✅ | ✅ | ✅ | ✅ | Context retention |
| **Context Window** | ✅ | ✅ | ✅ | ✅ | Token limit management |
| **System Prompts** | ✅ | ✅ | ✅ | ✅ | Initial instructions |
| **Tool Integration** | ✅ | ✅ | ✅ | ✅ | Session-level tools |

### Layer 2: Tracer System

| Feature | Python | Elixir | Rust | TypeScript | Notes |
|---------|--------|--------|------|------------|-------|
| **Tracer System** | ✅ | ✅ | ✅ | ✅ | Event recording |
| **Event Store** | ✅ | ✅ | ✅ | ✅ | Event persistence |
| **Event Types** | ✅ | ✅ | ✅ | ✅ | LLM/Tool/Agent events |
| **Null Tracer** | ✅ | ✅ | ✅ | ✅ | Null object pattern |
| **Correlation Tracking** | ✅ | ✅ | ✅ | ✅ | Request correlation |
| **Performance Metrics** | ✅ | ✅ | ✅ | ✅ | Duration tracking |
| **Event Querying** | ✅ | ✅ | ✅ | ✅ | Filter/search events |
| **LLM Call Events** | ✅ | ✅ | ✅ | ✅ | Call tracking |
| **LLM Response Events** | ✅ | ✅ | ✅ | ✅ | Response tracking |
| **Tool Call Events** | ✅ | ✅ | ✅ | ✅ | Tool invocation tracking |
| **Agent Events** | ✅ | ✅ | ✅ | ✅ | Agent lifecycle |

### Layer 3: Agent System

#### Core Agent Infrastructure

| Feature | Python | Elixir | Rust | TypeScript | Notes |
|---------|--------|--------|------|------------|-------|
| **Base Agent** | ✅ | ✅ | ✅ | ✅ | Agent trait/interface |
| **Base Async Agent** | ✅ | ✅ | ✅ | ✅ | Async agent support |
| **Base LLM Agent** | ✅ | ✅ | ✅ | ✅ | LLM-enabled agents |
| **AgentEventAdapter** | ✅ | ❌ | ❌ | ❌ | Event-driven agent wrapper |
| **Event System** | ✅ | ✅ | ✅ | ✅ | Event types |
| **Dispatcher** | ✅ | ✅ | ✅ | ✅ | Event routing |
| **Async Dispatcher** | ✅ | ✅ | ✅ | ✅ | Async event processing |
| **Router** | ✅ | ✅ | ✅ | ✅ | Event-to-agent routing |
| **Shared Working Memory** | ✅ | ✅ | ✅ | ✅ | Context sharing |

#### Agent Implementations

| Agent Type | Python | Elixir | Rust | TypeScript | Notes |
|------------|--------|--------|------|------------|-------|
| **Async LLM Agent** | ✅ | ✅ | ✅ | ✅ | LLM with async processing |
| **Async Aggregator Agent** | ✅ | ✅ | ✅ | ✅ | Result aggregation |
| **Iterative Problem Solver** | ✅ | ✅ | ✅ | ✅ | Multi-step reasoning |
| **Simple Recursive Agent** | ✅ | ✅ | ✅ | ✅ | Self-recursive processing |
| **ReAct Pattern** | ✅ | ✅ | ✅ | ✅ | Reasoning + Acting |

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

| Gateway | Python | Elixir | Rust | TypeScript | Notes |
|---------|--------|--------|------|------------|-------|
| **Anthropic** | ✅ | ❌ | ❌ | 📝 | Python-only currently; TypeScript planned |
| **File Gateway** | ✅ | ❌ | ❌ | ❌ | Python: file-based mocking for tests |

### Message Features (Python-only)

| Feature | Python | Others | Notes |
|---------|--------|--------|-------|
| Content Annotations | ✅ | ❌ | Message metadata |
| Audience Targeting | ✅ | ❌ | Message routing |
| Priority System | ✅ | ❌ | Message importance levels |

### Advanced Features

| Feature | Python | Elixir | Rust | TypeScript |
|---------|--------|--------|------|------------|
| AgentEventAdapter | ✅ | ❌ | ❌ | ❌ |
| Configuration Files | ✅ | 📝 | ⚠️ | 📝 |
| Builder Pattern | ✅ | ❌ | ⚠️ | 📝 |
| Connection Pooling | ⚠️ | 📝 | ⚠️ | 📝 |
| Retry Logic | ⚠️ | ❌ | ❌ | ❌ |

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
| Python | 200 | ~62% | 0 (flake8) | pip-audit (network-blocked) |
| Elixir | 625 | 81.56% | 0 (Credo) | mix deps.audit clean |
| Rust | 365 | tarpaulin | 0 (clippy) | cargo deny (non-blocking warnings) |
| TypeScript | 625 | Jest | 0 (ESLint) | npm audit (4 moderate advisories) |

---

## Glossary

- **✅ Complete**: Feature is fully implemented and tested
- **⚠️ Partial**: Feature exists but incomplete or has limitations
- **❌ Not Started**: Feature not yet begun
- **📝 Planned**: Feature documented in plan but not implemented

---

*This document is maintained alongside ELIXIR.md, RUST.md, and TYPESCRIPT.md.*
