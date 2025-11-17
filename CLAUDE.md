# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a **multi-language monorepo** containing four independent implementations of the Mojentic LLM integration framework:

```
/Users/svetzal/Work/Personal/conversion/
├── mojentic-py/     # Python reference implementation (complete) [git submodule]
├── mojentic-ex/     # Elixir implementation (in progress) [git submodule]
├── mojentic-ru/     # Rust implementation (in progress) [git submodule]
├── mojentic-ts/     # TypeScript implementation (in progress) [git submodule]
├── PARITY.md        # Feature parity tracking matrix (CRITICAL - always consult and update)
├── ELIXIR.md        # Elixir implementation guide
├── RUST.md          # Rust implementation guide
└── TYPESCRIPT.md    # TypeScript implementation guide
```

**Note**: Each `mojentic-*` directory is a **git submodule**, pointing to its own independent repository. This allows each language implementation to have its own version control, CI/CD, and release cycle while maintaining coordinated feature parity across implementations.

**CRITICAL**: The Python implementation (`mojentic-py`) is the **reference implementation**. All other implementations must achieve feature parity with it. **Always consult `PARITY.md`** before implementing features to understand current status and priorities.

## Working with Language-Specific Agents

**IMPORTANT**: This monorepo has four specialized agents for quality work in each language:

- **@elixir-craftsperson** - Elixir work in `mojentic-ex/`
- **@python-craftsperson** - Python work in `mojentic-py/`
- **@rust-craftsperson** - Rust work in `mojentic-ru/`
- **@typescript-craftsperson** - TypeScript work in `mojentic-ts/`

### When to Delegate to Specialized Agents

Always use language-specific agents for:
- **Implementation work** - New features, refactoring, bug fixes
- **Quality assurance** - Code review, testing, linting, security audits
- **Documentation sync** - Ensuring guides match current implementation
- **Best practices** - Idiomatic patterns, functional core/imperative shell design
- **Final review** - Before committing, ensure all quality gates pass

### Coordination Pattern for Multi-Language Features

When implementing a feature across multiple languages:

```
✅ Effective approach:
1. Analyze Python reference implementation (coordinator)
2. Delegate to each language agent:
   @python-craftsperson: Review and enhance Python implementation
   @elixir-craftsperson: Implement in Elixir following mojentic-py pattern
   @rust-craftsperson: Implement in Rust following mojentic-py pattern
   @typescript-craftsperson: Implement in TypeScript following mojentic-py pattern
3. Each agent ensures:
   - Idiomatic implementation
   - Comprehensive tests (all passing)
   - Linting/formatting compliance
   - Security audit
   - Documentation sync
4. Coordinator updates PARITY.md and commits
```

### Example Agent Invocations

**After implementing a feature:**
```
@elixir-craftsperson: I've implemented the TokenizerGateway. Please review
for code quality, test coverage, Credo compliance, and ensure the guides
in lib/mojentic/ match the implementation.
```

**Starting new work:**
```
@rust-craftsperson: Implement ChatSession following the Python reference in
mojentic-py/src/mojentic/llm/chat_session.py. Include comprehensive tests
with mokito mocks, rustdoc, and update book/src/chat-session.md.
```

**Quality gate check:**
```
@typescript-craftsperson: Run full quality check on the Broker implementation:
ESLint, Prettier, Jest tests, npm audit, and verify VitePress docs are current.
```

### Benefits of Language-Specific Agents

1. **Deep expertise** - Each agent knows their language's idioms, tools, and best practices
2. **Quality enforcement** - Agents run language-specific quality tools (Credo, clippy, ESLint, flake8)
3. **Concurrent work** - Different agents can work in parallel on their language implementations
4. **Documentation sync** - Agents ensure guides (ex_docs, mdBook, VitePress, mkdocs) stay current
5. **Security** - Each agent runs appropriate security audits (mix_audit, cargo-deny, npm audit, pysentry)

## MANDATORY Quality Gates

**CRITICAL**: Every code change session MUST run full quality checks before considering work complete. These gates are non-negotiable.

### Pre-Commit Checklist (ALL implementations)

Before ANY commit or completion of work:

1. ✅ **Format check** - Code must be formatted per language standards
2. ✅ **Lint check** - All linter warnings resolved (including examples/tests)
3. ✅ **Test suite** - All tests passing
4. ✅ **Security audit** - No known vulnerabilities
5. ✅ **Examples validate** - All examples compile/run without errors

### Language-Specific Quality Commands

**Python** (mojentic-py/):
```bash
flake8 src && \
pytest && \
pip-audit
```

**Elixir** (mojentic-ex/):
```bash
mix format --check-formatted && \
mix credo --strict && \
mix test && \
mix audit
```

**Rust** (mojentic-ru/):
```bash
cargo fmt --check && \
cargo clippy --all-targets --all-features -- -D warnings && \
cargo test && \
cargo deny check
```

**TypeScript** (mojentic-ts/):
```bash
npm run lint && \
npm run format:check && \
npm test && \
npm audit
```

**Note**: `npm run lint` now enforces `--max-warnings 0` by default. **Zero warnings allowed.**

### Why This Matters

**Examples are executable documentation** - When examples fail to compile, users cannot learn from them. The `--all-targets` flag in linting/checking MUST include examples to catch API mismatches immediately.

**Prevention over cure** - Running quality gates takes seconds. Debugging broken examples in CI or production takes hours. Always run checks before committing.

### When Quality Gates Fail

If quality checks reveal errors:
1. **Stop immediately** - Do not proceed with other work
2. **Fix the root cause** - Don't suppress warnings
3. **Re-run all checks** - Ensure the fix didn't introduce new issues
4. **Document exceptions** - If suppressing a lint, explain why in comments

## Working Across Language Boundaries

### Before Implementing a Feature

1. **Check `PARITY.md`** for current implementation status
2. **Read the Python reference implementation** in `mojentic-py/` to understand the expected behavior
3. **Update `PARITY.md`** after completing or modifying features
4. **Test examples** - ensure all examples work with locally available Ollama models

### Available Ollama Models

When writing examples, use models from this list:

- qwen3-coder:30b - coding focused
- qwen3-vl:30b - visual model
- gpt-oss:20b
- gpt-oss:120b
- qwen3-128k:32b
- qwen3:0.6b
- qwen3:30b
- qwen3:30b-a3b-q4_K_M
- qwen3:32b
- qwen2.5:72b
- gemma3:4b - visual model
- gemma3:12b - visual model
- gemma3:27b - visual model

## Development Commands by Language

### Python (mojentic-py/)
```bash
# Setup
cd mojentic-py
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

# Testing
pytest                                    # All tests with coverage
pytest src/mojentic/llm/llm_broker_spec.py  # Single test file

# Linting
flake8 src

# Documentation
mkdocs serve  # Serve docs locally
mkdocs build  # Build docs
```

### Elixir (mojentic-ex/)
```bash
# Setup
cd mojentic-ex
mix deps.get
mix compile

# Testing
mix test                                    # All tests
mix test test/mojentic/llm/broker_test.exs  # Single test file

# Linting & Formatting
mix format
mix credo

# Documentation
mix docs

# Examples
mix run examples/simple_llm.exs
mix run examples/streaming.exs
mix run examples/tool_usage.exs
```

### Rust (mojentic-ru/)
```bash
# Setup
cd mojentic-ru
cargo build

# Testing
cargo test                           # All tests
cargo test --lib                     # Library tests only
cargo test broker::tests            # Specific test module

# Linting & Formatting
cargo fmt
cargo clippy

# Documentation
cargo doc --no-deps --all-features   # API docs
mdbook build book                    # User guide

# Examples
cargo run --example simple_llm
cargo run --example streaming
cargo run --example tool_usage
```

### TypeScript (mojentic-ts/)
```bash
# Setup
cd mojentic-ts
npm install

# Testing
npm test                                # All tests
npm test -- broker.test.ts              # Single test file

# Linting & Formatting
npm run lint
npm run format

# Build
npm run build

# Examples
npx ts-node examples/simple_llm.ts
npx ts-node examples/streaming.ts
npx ts-node examples/tool_usage.ts
```

## Architecture Overview

### Three-Layer Design

All implementations follow this architecture from the Python reference:

**Layer 1: LLM Integration (Stable)**
- `Broker` - Main interface for LLM interactions
  - `generate()` - Text generation with optional tool calling
  - `generate_object()` - Structured output with JSON schema
  - `generate_stream()` - Streaming with recursive tool execution
- `Gateway` - Abstract interface for LLM providers
  - `OllamaGateway` - Local Ollama models (primary focus)
  - `OpenAIGateway` - OpenAI API (Python only, partially in others)
  - `AnthropicGateway` - Anthropic API (Python only)
- `Tool` - Extensible function calling system

**Layer 2: Tracer System (Python complete, others partial)**
- Event-based observability system
- Records LLM calls, tool executions, agent interactions
- Correlation IDs for tracking related events

**Layer 3: Agent System (Python only, planned for others)**
- Event-driven multi-agent coordination
- Dispatcher and Router patterns
- Shared working memory

### Critical Implementation Patterns

#### Error Handling
- **Python**: Raise exceptions
- **Elixir**: Return `{:ok, result}` | `{:error, reason}` tuples
- **Rust**: Return `Result<T, MojenticError>`
- **TypeScript**: Return `Result<T, Error>` type (Rust-inspired)

#### Tool Calling
All implementations must support **recursive tool execution**:
1. LLM makes tool call request
2. Execute tool with provided arguments
3. Add tool result to conversation messages
4. Recursively call `generate()` with updated messages
5. Continue until LLM returns text response (no more tool calls)

#### Streaming with Tool Calls
Streaming must handle tool calls correctly:
1. Stream content chunks as they arrive
2. Accumulate tool calls from stream
3. When stream completes with tool calls:
   - Execute all tools
   - Add results to messages
   - Recursively stream with updated messages
4. Flatten recursive streams for continuous output

### Gateway-Specific Behaviors

#### Ollama Gateway
- **Endpoint**: `http://localhost:11434/api/chat`
- **Streaming**: Newline-delimited JSON (`\n` separated objects)
- **Tool calls**: Arrive in `message.tool_calls[]` array
- **Context**: Use `num_ctx` for context window
- **Embeddings**: Separate `/api/embeddings` endpoint

#### Message Adaptation
Each gateway adapts universal `LlmMessage` format to provider-specific format:
- **Ollama**: `{role, content, tool_calls}`
- **OpenAI**: `{role, content, tool_calls}` with `tool_choice` support
- Images: Ollama uses `images: [base64...]`, OpenAI uses content array

## Common Issues and Solutions

### Streaming Errors

**Problem**: Stream transform fails with `:halt` atom
- **Cause**: Missing pattern match for `:halt` in stream transformation
- **Solution**: Add `:halt -> {:halt, :halt}` or `:halt -> {[], :halt}` pattern

**Problem**: Tool calls not executing during streaming
- **Cause**: Tool calls not being accumulated before stream completion
- **Solution**: Accumulate tool calls in stream state, execute after stream completes

### Tool Execution Errors

**Problem**: "Tool not found" errors
- **Cause**: Tool matching by name not working correctly
- **Solution**: Extract tool name from descriptor's `function.name` field

**Problem**: Tool arguments type mismatch
- **Cause**: Arguments passed as wrong type (e.g., `HashMap<String, String>` instead of `HashMap<String, Value>`)
- **Solution**: Preserve JSON values, don't convert to strings prematurely

### Model Availability

**Problem**: 404 errors from Ollama
- **Cause**: Using model that doesn't exist on user's system
- **Solution**: Check available models list above, use `qwen3:32b` as default

### Example Failures

**Problem**: Examples timeout or fail
- **Cause**: Ollama not running or model not loaded
- **Solution**: Examples requiring Ollama are expected to timeout in tests; verify with `ollama list`

## Testing Philosophy

### Unit Tests
- Mock gateways, not external dependencies (HTTPoison, reqwest, axios)
- Test broker logic in isolation
- Verify tool execution flow
- Check message adaptation correctness

### Integration Tests
- Examples serve as integration tests
- Examples should run successfully against local Ollama
- Keep examples simple and focused on single feature

### Running All Tests
```bash
# From parent directory
cd mojentic-py && pytest
cd ../mojentic-ex && mix test
cd ../mojentic-ru && cargo test
cd ../mojentic-ts && npm test
```

## Documentation Structure

Each implementation maintains language-specific docs:
- **Python**: MkDocs in `docs/`
- **Elixir**: ExDoc in `guides/` and inline `@moduledoc`
- **Rust**: mdBook in `book/` + rustdoc
- **TypeScript**: Markdown docs in `docs/`

Keep examples synchronized across all implementations where feature parity exists.

## Parity Tracking Workflow

1. **Before starting work**: Read `PARITY.md` to understand current state
2. **During implementation**: Follow Python reference implementation behavior
3. **After completion**: Update `PARITY.md` status (✅, ⚠️, ❌, 📝)
4. **Test examples**: Ensure examples work with available Ollama models
5. **Update language-specific docs**: Keep README and guides synchronized

## Key Differences from Python Reference

### Elixir-Specific
- Uses OTP supervision trees (future feature)
- Streams use `Stream.resource/3` and `Stream.transform/3`
- Tools are modules with `@behaviour` instead of classes
- No Mix.install in examples (examples must run with `mix run`)

### Rust-Specific
- Uses `Pin<Box<dyn Stream>>` for streaming
- Requires `Arc<Gateway>` for thread-safe gateway sharing
- Tools use trait objects `Box<dyn LlmTool>`
- Uses `async-stream` crate for stream composition

### TypeScript-Specific
- Uses Result type pattern (inspired by Rust)
- Async generators (`async function*`) for streaming
- Tools extend `BaseTool` abstract class
- Uses `yield*` for recursive stream flattening

## When to Update PARITY.md

- ✅ Feature fully implemented and tested
- ⚠️ Feature partially working or missing edge cases
- ❌ Feature not started
- 📝 Feature planned but not started

Always include implementation notes for partial features explaining what's missing.
