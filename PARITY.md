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
| Agent Broker | ✅ | ❌ | ❌ | ❌ |
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
