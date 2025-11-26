# Mojentic Feature Parity Implementation Plan

**Created**: November 25, 2025
**Updated**: November 25, 2025 - **Phase 1, 2, 3, 4, 5, 6 & 7 COMPLETED** ✅
**Purpose**: Detailed roadmap for achieving feature parity across all four Mojentic implementations while preserving idiomatic traits of each language.

---

## ✅ Phase 1, 2, 3, 4, 5, 6 & 7 Completion Summary (November 25, 2025)

**Status**: Phase 1 (Test Stabilization), Phase 2 (Core API Alignment), Phase 3 (Gateway Parity), Phase 4 (Tool System Parity), Phase 5 (Agent System Parity), Phase 6 (Message System Parity), and Phase 7 (Chat Session Parity) are **COMPLETE** across all four implementations.

### Phase 1: Test Stabilization ✅
- **Python**: 200/200 tests passing, all quality gates clean
- **Elixir**: 586/586 tests passing (includes new BaseAgent tests)
- **Rust**: 311 tests passing + doc tests
- **TypeScript**: 589 tests passing across 30 test suites

### Phase 2: Core API Alignment ✅

**CompletionConfig Standardization Achieved:**

All four implementations now have complete, standardized CompletionConfig with these fields:
- `temperature` - Temperature sampling (all implementations)
- `numCtx/num_ctx` - Context window size (all implementations)
- `numPredict/num_predict` - Max tokens to predict (all implementations)
- `maxTokens/max_tokens` - Max tokens in response (all implementations)
- `topP/top_p` - Nucleus sampling (all implementations)
- `topK/top_k` - Top-k sampling (all implementations)
- `responseFormat/response_format` - Structured output (all implementations)

### Phase 3: Gateway Parity ✅

**Ollama Gateway Complete Feature Set:**

| Feature | Python | Elixir | Rust | TypeScript |
|---------|--------|--------|------|------------|
| Chat completions | ✅ | ✅ | ✅ | ✅ |
| Streaming | ✅ | ✅ | ✅ | ✅ |
| Streaming + Tools | ✅ | ✅ | ✅ | ✅ |
| Structured output | ✅ | ✅ | ✅ | ✅ |
| Tool calling | ✅ | ✅ | ✅ | ✅ |
| Image analysis | ✅ | ✅ | ✅ | ✅ |
| Model listing | ✅ | ✅ | ✅ | ✅ |
| Model pulling | ✅ | ✅ | ✅ | ✅ |
| Embeddings | ✅ | ✅ | ✅ | ✅ |

### Phase 4: Tool System Parity ✅

**All Tools Now Available Across All Implementations:**

| Tool | Python | Elixir | Rust | TypeScript |
|------|--------|--------|------|------------|
| DateResolver | ✅ | ✅ | ✅ | ✅ |
| CurrentDateTime | ✅ | ✅ | ✅ | ✅ |
| File Manager | ✅ | ✅ | ✅ | ✅ |
| Task Manager | ✅ | ✅ | ✅ | ✅ |
| Tell User | ✅ | ✅ | ✅ | ✅ |
| Ask User | ✅ | ✅ | ✅ | ✅ |
| Tool Wrapper | ✅ | ✅ | ✅ | ✅ |
| **Web Search** | ✅ SerpAPI | ✅ DuckDuckGo | ✅ DuckDuckGo | ✅ DuckDuckGo |

**Web Search Highlight**: Elixir, Rust, and TypeScript now have FREE web search using DuckDuckGo (no API key required), while Python uses paid SerpAPI.

**Quality Metrics:**
- Total tests across all implementations: **1,666+ tests** (all passing)
- Zero linting warnings across all implementations
- All security audits clean
- 100% backward compatibility maintained

---

## Executive Summary

This plan addresses the discrepancies identified in PARITY.md and outlines specific actions to bring the Elixir, Rust, and TypeScript implementations into feature parity with the Python reference implementation, while respecting each language's idioms.

### Current State Summary

| Implementation | Tests | Status | Layer 1 | Layer 2 | Layer 3 |
|---------------|-------|--------|---------|---------|---------|
| **Python** | 200 | ✅ Passing | ✅ Complete | ✅ Complete | ⚠️ Experimental |
| **Elixir** | 554 (2 failures) | ⚠️ Minor issues | ⚠️ Ollama only | ✅ Complete | ⚠️ Experimental |
| **Rust** | 316 | ✅ Passing | ⚠️ Ollama only | ✅ Complete | ⚠️ Experimental |
| **TypeScript** | 544 | ✅ Passing | ⚠️ Ollama only | ✅ Complete | ⚠️ Experimental |

---

## Phase 1: Test Stabilization (Priority: CRITICAL) - ✅ COMPLETED

Before implementing new features, all implementations must have passing test suites.

### 1.1 Python Test Fixes (Estimated: 1-2 days) - ✅ COMPLETED

**Issue resolved**: The uv-based project management wasn't syncing dev dependencies by default.

**Solution**:
```bash
cd mojentic-py
uv sync --extra dev  # Syncs all dependencies including dev extras
```

**Status**: ✅ All 200 tests passing, flake8 clean, bandit clean, pip-audit clean

### 1.2 Elixir Test Fixes (Estimated: 1 day) - ✅ COMPLETED

**Status**: ✅ All 554 tests passing (18 doctests, 536 tests)

**Resolution**: The 2 failing tests mentioned in the plan were already resolved before execution.

**Quality gates verified:**
- ✅ mix test: All 554 tests pass
- ✅ mix format --check-formatted: Clean
- ✅ mix credo --strict: Clean

### 1.3 Rust Test Verification (Estimated: None - already passing)

- ✅ All 294 active tests passing
- 22 ignored doc tests (acceptable - likely require async runtime)

### 1.4 TypeScript Test Verification (Estimated: None - already passing)

- ✅ All 544 tests passing across 28 test suites

---

## Phase 2: Core API Alignment (Priority: HIGH) - ✅ COMPLETED

Ensure the core broker API is consistent across implementations while allowing for idiomatic differences.

### 2.1 Broker API Harmonization

**Python (Reference):**
```python
class LLMBroker:
    def generate(self, messages, tools=None, temperature=1.0, num_ctx=32768,
                 num_predict=-1, max_tokens=16384, correlation_id=None) -> str
    def generate_stream(self, messages, tools=None, temperature=1.0, ...) -> Iterator[str]
    def generate_object(self, messages, object_model, temperature=1.0, ...) -> BaseModel
```

**Current Discrepancies:**

| Feature | Python | Elixir | Rust | TypeScript |
|---------|--------|--------|------|------------|
| `num_predict` param | ✅ | ⚠️ In config | ✅ In config | ✅ Complete |
| `max_tokens` param | ✅ | ⚠️ In config | ✅ In config | ✅ In config |
| Correlation ID | ✅ Auto-generated | ✅ Auto-generated | ✅ Auto-generated | ✅ Auto-generated |
| Return types | Exceptions | Result tuples | Result<T, E> | Result pattern |

**Actions:**

#### 2.1.1 TypeScript: Add num_predict support (Estimated: 2 hours) - ✅ COMPLETED

**Status**: ✅ Completed November 25, 2025

**Changes made:**
1. ✅ Added `numPredict?: number` to `CompletionConfig` interface in `src/llm/models.ts`
2. ✅ Updated Ollama gateway to pass `numPredict` through (takes precedence over `maxTokens`)
3. ✅ Added comprehensive tests:
   - Test for `numPredict` parameter passing
   - Test for precedence over `maxTokens`
   - Test for fallback to `maxTokens` when `numPredict` not provided
4. ✅ All quality gates passed:
   - ESLint: ZERO warnings
   - All 547 tests passing (including 25 Ollama-specific tests)
   - npm audit: zero vulnerabilities
5. ✅ Created test example in `examples/test_numPredict.ts`

**Implementation notes:**
- `numPredict` takes precedence over `maxTokens` when both are provided
- Maintains backward compatibility with existing `maxTokens` usage
- Follows TypeScript idioms with optional field and proper type safety

#### 2.1.2 Verify parameter passing across all implementations - ✅ COMPLETED
- ✅ Cross-implementation parameter passing verified
- ✅ Intentional differences documented (snake_case vs camelCase, Result types vs exceptions)

### 2.2 CompletionConfig Standardization

**Target standardized fields:**
```typescript
interface CompletionConfig {
  temperature?: number;      // 0.0-2.0, default varies by model
  numCtx?: number;           // Context window size
  numPredict?: number;       // Max tokens to predict (-1 for unlimited)
  maxTokens?: number;        // Max tokens in response
  topP?: number;             // Top-p sampling
  topK?: number;             // Top-k sampling
  responseFormat?: object;   // For structured output
}
```

**Actions:**
1. ✅ Python: Already has all fields
2. ✅ Elixir: All fields added to `CompletionConfig` struct - **COMPLETED November 25, 2025**
3. ✅ Rust: All fields added to `CompletionConfig` struct - **COMPLETED November 25, 2025**
4. ✅ TypeScript: All fields added to `CompletionConfig` interface - **COMPLETED November 25, 2025**

**Elixir completion details:**
- ✅ Added `top_p: float() | nil` to CompletionConfig struct
- ✅ Added `top_k: integer() | nil` to CompletionConfig struct
- ✅ Added `response_format: response_format() | nil` to CompletionConfig struct
- ✅ Updated Ollama gateway to pass all parameters
- ✅ Added 23 comprehensive tests (11 config tests, 12 gateway tests)
- ✅ All 571 tests passing
- ✅ Quality gates: mix format, mix credo --strict all passing

**Rust completion details:**
- ✅ Added `top_p: Option<f32>` to CompletionConfig struct
- ✅ Added `top_k: Option<u32>` to CompletionConfig struct
- ✅ Added `response_format: Option<ResponseFormat>` with ResponseFormat enum (Text, JsonObject)
- ✅ Updated Ollama gateway to pass all parameters
- ✅ Added 16 comprehensive tests (7 gateway tests, 9 Ollama tests)
- ✅ All 292 tests passing + 13 doc tests passing
- ✅ Quality gates: cargo fmt, cargo clippy (zero warnings), cargo test all passing
- ✅ Documentation updated in mdBook

**TypeScript completion details:**
- ✅ Added `topK?: number` to CompletionConfig interface
- ✅ Added `numCtx?: number` to CompletionConfig interface
- ✅ Updated Ollama gateway to map both parameters (`top_k`, `num_ctx`)
- ✅ Added comprehensive tests for both parameters (28 Ollama tests passing)
- ✅ All 550 tests passing across 28 test suites
- ✅ ESLint: ZERO warnings
- ✅ Build successful
- ✅ Documentation updated in `docs/api/core.md` and `docs/api/gateways.md`
- ✅ Created comprehensive example in `examples/completion_config_parameters.ts`

---

## Phase 3: Gateway Parity (Priority: HIGH) - ✅ COMPLETED November 25, 2025

### 3.1 Ollama Gateway Feature Completion ✅

All implementations now have complete Ollama gateway parity:

| Feature | Python | Elixir | Rust | TypeScript |
|---------|--------|--------|------|------------|
| Chat completions | ✅ | ✅ | ✅ | ✅ |
| Streaming | ✅ | ✅ | ✅ | ✅ |
| Streaming + Tools | ✅ | ✅ | ✅ | ✅ |
| Structured output | ✅ | ✅ | ✅ | ✅ |
| Tool calling | ✅ | ✅ | ✅ | ✅ |
| Image analysis | ✅ | ✅ | ✅ | ✅ |
| Model listing | ✅ | ✅ | ✅ | ✅ |
| Model pulling | ✅ | ✅ | ✅ | ✅ |
| Embeddings | ✅ | ✅ | ✅ | ✅ |

**Actions:**

#### 3.1.1 Elixir: Image Analysis Support - ✅ COMPLETED November 25, 2025

**Status**: ✅ Already fully implemented - verified and enhanced

**Implementation details:**
- ✅ `image_paths` field already exists in Message struct
- ✅ `with_images/2` helper function for adding image paths
- ✅ Base64 encoding in `maybe_add_images/2` function
- ✅ File read error handling with logging
- ✅ Comprehensive tests (4 test cases for images)
- ✅ `image_analysis.exs` example with vision model

**Quality gates:**
- ✅ mix format: Clean
- ✅ mix credo --strict: ZERO warnings (fixed 5 pre-existing warnings)
- ✅ mix test: 553 tests passing

#### 3.1.2 Rust: Image Analysis Support (Estimated: 1 day) - ✅ COMPLETED November 25, 2025

**Status**: ✅ Completed - Image analysis support is already fully implemented

**Verification:**
1. ✅ `image_paths` field already exists in `LlmMessage` struct (src/llm/models.rs)
2. ✅ Base64 encoding already implemented in Ollama gateway (src/llm/gateways/ollama.rs)
3. ✅ Comprehensive tests exist:
   - `test_adapt_messages_with_images` - Tests Base64 encoding with temporary files
   - `test_message_with_images` - Tests message construction with image paths
   - All 292 unit tests passing + 13 doc tests passing
4. ✅ `image_analysis.rs` example already exists and works (examples/image_analysis.rs)
5. ✅ Test image available at `examples/images/flash_rom.jpg`

**Implementation details:**
- Uses `base64` crate (v0.22) for encoding
- Reads image files from paths specified in `LlmMessage.image_paths`
- Encodes as Base64 using `base64::engine::general_purpose::STANDARD`
- Includes encoded images in `images` field of Ollama API requests
- Supports multiple images per message

**Documentation:**
- ✅ Updated `book/src/core/image_analysis.md` with comprehensive guide
- ✅ Includes usage examples, error handling, and supported models
- ✅ Documents the complete workflow from file reading to API transmission

**Quality gates:**
- ✅ cargo fmt --check: Clean (formatting passes)
- ✅ cargo clippy --all-targets --all-features -- -D warnings: ZERO warnings
- ✅ cargo test: All 292 tests passing
- ✅ cargo tarpaulin: 64.65% coverage (1227/1898 lines)
- ✅ cargo deny check: Advisories ok, bans ok, licenses ok, sources ok

#### 3.1.3 TypeScript: Complete Image Analysis - ✅ COMPLETED November 25, 2025

**Status**: ✅ Already implemented - enhanced with tests and documentation

**Implementation details:**
- ✅ Image utilities in `src/llm/image-utils.ts` (encodeImageToBase64, createImageContent, createTextContent)
- ✅ ContentItem interface supports multimodal messages
- ✅ Ollama gateway extracts base64 from data URIs
- ✅ Added 2 new tests for image handling
- ✅ Updated `image_analysis.ts` example
- ✅ Created comprehensive `docs/image-analysis.md` documentation

**Quality gates:**
- ✅ npm run lint: ZERO warnings
- ✅ npm test: 552 tests passing
- ✅ npm audit: Zero vulnerabilities

#### 3.1.4 Elixir: Model Pull Support - ✅ COMPLETED November 25, 2025

**Status**: ✅ Implemented with streaming progress support

**Implementation details:**
- ✅ Added `pull_model/2` function to Ollama gateway
- ✅ Optional progress callback receives status updates (status, completed, total, digest)
- ✅ Streams newline-delimited JSON from `/api/pull` endpoint
- ✅ Robust chunk buffering for incomplete JSON
- ✅ Returns `{:ok, model_name}` or `{:error, reason}`
- ✅ 8 comprehensive tests covering all cases
- ✅ Created `examples/pull_model.exs` with progress display

**Quality gates:**
- ✅ mix format: Clean
- ✅ mix credo --strict: ZERO warnings
- ✅ mix test: 557 tests passing

#### 3.1.5 TypeScript: Model Pull Support - ✅ COMPLETED November 25, 2025

**Status**: ✅ Implemented with streaming progress support

**Implementation details:**
- ✅ Added `pullModel` method to OllamaGateway class
- ✅ `PullProgress` interface with status, digest, total, completed fields
- ✅ Optional `PullProgressCallback` for progress tracking
- ✅ Streams from `/api/pull` endpoint with JSON parsing
- ✅ Returns `Result<void, Error>` for functional error handling
- ✅ 8 comprehensive tests covering success, errors, empty names
- ✅ Created `examples/pull_model.ts` with rich progress display
- ✅ Added `npm run example:pull-model` script

**Quality gates:**
- ✅ npm run lint: ZERO warnings
- ✅ npm test: 560 tests passing (38 Ollama tests)
- ✅ npm audit: Zero vulnerabilities

### 3.2 OpenAI Gateway (Future - Lower Priority)

Python is the only implementation with OpenAI gateway. This is documented as lower priority.

**Future actions (not in current sprint):**
- [ ] Elixir: Implement OpenAI gateway
- [ ] Rust: Implement OpenAI gateway
- [ ] TypeScript: Implement OpenAI gateway (planned)

---

## Phase 4: Tool System Parity (Priority: HIGH) - ✅ COMPLETED November 25, 2025

### 4.1 Core Tool Interface ✅

All implementations have consistent tool interfaces:

| Tool Feature | Python | Elixir | Rust | TypeScript |
|-------------|--------|--------|------|------------|
| Base trait/interface | ✅ | ✅ (behaviour) | ✅ (trait) | ✅ (interface) |
| `descriptor()` | ✅ | ✅ | ✅ | ✅ |
| `run(args)` | ✅ | ✅ | ✅ | ✅ |
| `matches(name)` | ✅ | ✅ | ✅ | ✅ |
| Tool wrapper | ✅ | ✅ | ✅ | ✅ |

**Actions:**

#### 4.1.1 Standardize Tool Name Matching - ✅ COMPLETED November 25, 2025

**Status**: ✅ All implementations now have consistent `matches(name)` functionality

**Verification findings**:
- Python: `matches(name)` method on BaseTool - compares against `self.name`
- Elixir: `Tool.matches?/2` module function - compares against descriptor name
- Rust: `matches(&str)` trait method with default impl - compares against descriptor name
- TypeScript: `matches(name)` method added to BaseTool - compares against `this.name()`

**All implementations are functionally equivalent** - they all perform exact string equality matching.

**TypeScript Enhancement**: Added `matches(name: string): boolean` method to BaseTool class for API parity (previously only had `name()` accessor).

### 4.2 Tool Implementations Parity ✅

| Tool | Python | Elixir | Rust | TypeScript |
|------|--------|--------|------|------------|
| DateResolver | ✅ | ✅ | ✅ SimpleDateTool | ✅ |
| CurrentDateTime | ✅ | ✅ | ✅ | ✅ |
| File Manager | ✅ | ✅ | ✅ | ✅ |
| Task Manager | ✅ | ✅ | ✅ | ✅ |
| Tell User | ✅ | ✅ | ✅ | ✅ |
| Ask User | ✅ | ✅ | ✅ | ✅ |
| Tool Wrapper | ✅ | ✅ | ✅ | ✅ |
| Web Search | ✅ SerpAPI | ✅ DuckDuckGo | ✅ DuckDuckGo | ✅ DuckDuckGo |

#### 4.2.1 DateResolver Naming Alignment - ✅ DOCUMENTED November 25, 2025

**Decision**: Keep `SimpleDateTool` name in Rust - it accurately reflects the simpler implementation.

**Rationale**:
- Rust's SimpleDateTool uses basic pattern matching (simpler than Python's parsedatetime NLP)
- The LLM-facing function name (`resolve_date`) is already consistent across all languages
- Renaming would break backward compatibility for no functional benefit
- The name "Simple" is semantically accurate

#### 4.2.2 Web Search Tool - ✅ IMPLEMENTED November 25, 2025

**Status**: ✅ Implemented in Elixir, Rust, and TypeScript using FREE DuckDuckGo endpoint

**Implementation Details**:
- Uses DuckDuckGo's lite endpoint (https://lite.duckduckgo.com/lite/) - **NO API KEY REQUIRED**
- Parses HTML to extract organic search results (title, URL, snippet)
- Returns up to 10 results to minimize token usage
- Robust error handling for network failures, empty results, etc.

**TypeScript** (`src/llm/tools/web-search-tool.ts`):
- 18 tests, all passing
- Uses native fetch API
- Comprehensive HTML entity decoding
- ESLint: ZERO warnings

**Elixir** (`lib/mojentic/llm/tools/web_search_tool.ex`):
- 20 tests, all passing (91.67% coverage)
- Uses HTTPoison for HTTP, regex for parsing
- mix credo --strict: ZERO warnings

**Rust** (`src/llm/tools/web_search_tool.rs`):
- 14 tests, all passing
- Uses scraper crate for HTML parsing
- cargo clippy: ZERO warnings

**Advantage over Python**: Free (no API key) vs Python's SerpAPI (requires paid API key)

---

## Phase 5: Agent System Parity (Priority: MEDIUM) - ✅ COMPLETED

### 5.1 Core Agent Infrastructure

| Component | Python | Elixir | Rust | TypeScript |
|-----------|--------|--------|------|------------|
| BaseAgent | ✅ | ✅ | ✅ | ✅ |
| BaseAsyncAgent | ✅ | ✅ | ✅ | ✅ |
| BaseLLMAgent | ✅ | ✅ | ✅ AsyncLlmAgent | ✅ |
| BaseLLMAgentWithMemory | ✅ | ✅ | ✅ | ✅ |
| SharedWorkingMemory | ✅ | ✅ | ✅ | ✅ |
| EventEmitter | ✅ | ✅ (GenServer) | ✅ | ✅ |
| Router | ✅ | ✅ | ✅ | ✅ |
| AsyncDispatcher | ✅ | ✅ | ✅ | ✅ |

**Actions:**

#### 5.1.1 Elixir: Implement BaseAgent Behaviour (Estimated: 1 day) - ✅ COMPLETED November 25, 2025
- [x] Create `BaseAgent` behaviour module
- [x] Define callback specs
- [x] Add documentation
- [x] Add tests (8 tests)

**Implementation**: Created `lib/mojentic/agents/base_agent.ex` with:
- `@callback receive_event(event :: Event.t()) :: [Event.t()]`
- `__using__` macro for default implementation
- Full ExDoc documentation

#### 5.1.2 Rust: Implement Base Agent Trait (Estimated: 1 day) - ✅ COMPLETED November 25, 2025
- [x] Create `BaseAgent` trait
- [x] Define required methods
- [x] Add documentation
- [x] Add tests (5 tests)

**Implementation**: Created `src/agents/base_agent.rs` with:
- `fn receive_event(&self, event: Box<dyn Event>) -> Vec<Box<dyn Event>>`
- Exported via `src/agents/mod.rs`
- Full rustdoc documentation

#### 5.1.3 TypeScript: Implement BaseAgent Interface - ✅ COMPLETED November 25, 2025
- [x] Create `BaseAgent` interface
- [x] Add tests (7 tests)

**Implementation**: Created `src/agents/base-agent.ts` with:
- `receiveEvent(event: Event): Event[]`
- Exported via `src/agents/index.ts`
- JSDoc documentation

**Note on BaseLLMAgent in Rust**: Rust's `AsyncLlmAgent` serves as the functional equivalent of Python's `BaseLLMAgent`. Since LLM calls are inherently I/O-bound, async-only implementations are appropriate. Python's synchronous versions use `asyncio.to_thread` internally anyway.

### 5.2 Agent Implementations

| Agent | Python | Elixir | Rust | TypeScript |
|-------|--------|--------|------|------------|
| AsyncLLMAgent | ✅ | ✅ | ✅ | ✅ |
| AsyncLLMAgentWithMemory | ✅ | ✅ | ✅ | ✅ |
| OutputAgent | ✅ | ✅ | ✅ | ✅ |
| AsyncAggregatorAgent | ✅ | ✅ | ✅ | ✅ |
| CorrelationAggregator | ✅ | ✅ | ✅ | ✅ |
| IterativeProblemSolver | ✅ | ✅ | ✅ | ✅ |
| SimpleRecursiveAgent | ✅ | ✅ | ✅ | ✅ |
| AgentBroker | ✅ | ❌ Deferred | ❌ Deferred | ❌ Deferred |

**Actions:**

#### 5.2.1 AgentBroker Implementation (Future - Low Priority)
The AgentBroker is a coordinator component in Python. Consider whether this pattern is needed in other implementations:

- [ ] Elixir: May use OTP supervision patterns instead
- [ ] Rust: May use different coordination patterns
- [ ] TypeScript: May use different patterns

**Decision**: Defer until real use cases emerge requiring multi-agent coordination.

---

## Phase 6: Message System Parity (Priority: MEDIUM) - ✅ COMPLETED

### 6.1 Message Types and Features

| Feature | Python | Elixir | Rust | TypeScript |
|---------|--------|--------|------|------------|
| System message | ✅ | ✅ | ✅ | ✅ |
| User message | ✅ | ✅ | ✅ | ✅ |
| Assistant message | ✅ | ✅ | ✅ | ✅ |
| Tool message | ✅ | ✅ | ✅ | ✅ |
| Image support | ✅ | ✅ | ✅ | ✅ |
| Message composers | ✅ | ✅ | ✅ | ✅ |
| Audience targeting | ✅ | ❌ Deferred | ❌ Deferred | ❌ Deferred |
| Priority system | ✅ | ❌ Deferred | ❌ Deferred | ❌ Deferred |

**Verification Complete (November 25, 2025):**

All implementations have full message system parity for core functionality:

- **Message composers**: All have helper methods (`Message.user()`, `Message.system()`, etc.)
- **Image support**: All implementations support multimodal messages with images
  - Python: `image_paths` field on `LLMMessage`
  - Elixir: `image_paths` field with `Message.with_images/2` helper
  - Rust: `image_paths` field with `with_images()` builder method
  - TypeScript: `ContentItem[]` array supporting `image_url` type (OpenAI-style)

**Deferred Features:**
- **Audience targeting**: Python-only feature for advanced multi-agent scenarios
- **Priority system**: Python-only feature for message prioritization

These features are deferred until real use cases emerge in other implementations.

---

## Phase 7: Chat Session Parity (Priority: MEDIUM) - ✅ COMPLETED

### 7.1 Chat Session Features

| Feature | Python | Elixir | Rust | TypeScript |
|---------|--------|--------|------|------------|
| Session management | ✅ | ✅ | ✅ | ✅ |
| Message history | ✅ | ✅ | ✅ | ✅ |
| Context window | ✅ | ✅ | ✅ | ✅ |
| System prompts | ✅ | ✅ | ✅ | ✅ |
| Tool integration | ✅ | ✅ | ✅ | ✅ |
| Token counting | ✅ | ✅ | ✅ | ✅ |

**Verification Complete (November 25, 2025):**

All implementations have full ChatSession parity:

- **Session management**: All support creating sessions with broker, system prompt, tools, max_context, and temperature
- **Message history**: All maintain conversation history with proper message insertion
- **Context window**: All automatically trim old messages when context limit exceeded (preserving system prompt)
- **System prompts**: All support custom system prompts as first message
- **Tool integration**: All pass tools to broker during generation
- **Token counting**: All use tokenizer to count tokens and manage context window

**Test Coverage:**
- Python: ChatSession tested through integration tests
- Elixir: 14 tests in `chat_session_test.exs`
- Rust: 14 tests in `chat_session.rs`
- TypeScript: 11 tests in `chat-session.test.ts`

**Note**: The previous "Streaming support" row was misleading. None of the implementations have `send_stream` on ChatSession - streaming is available via the broker's `generate_stream` method, not the ChatSession. This is consistent across all implementations.

**Architectural Note**: Text-based chat streaming is inherently asymmetric - responses stream from server to client (LLM generating tokens progressively), but client-to-server messages are sent atomically (user submits complete message). This is the standard pattern for LLM chat interfaces.

---

## Phase 8: Tracer System Verification (Priority: LOW)

The tracer system is complete across all implementations. Verify integration quality:

### 8.1 Tracer Integration Points

| Integration | Python | Elixir | Rust | TypeScript |
|-------------|--------|--------|------|------------|
| Broker.generate | ✅ | ✅ | ✅ | ✅ |
| Broker.generate_stream | ✅ | ✅ | ✅ | ✅ |
| Broker.generate_object | ✅ | ⚠️ | ✅ | ✅ |
| Tool execution | ✅ | ✅ | ✅ | ✅ |
| Agent events | ✅ | ✅ | ✅ | ✅ |

**Actions:**

#### 8.1.1 Elixir: Tracer in generate_object (Estimated: 1 hour)
- [ ] Verify tracer integration in `Broker.generate_object/4`
- [ ] Add recording calls if missing
- [ ] Add tests

---

## Phase 9: Example and Documentation Sync (Priority: MEDIUM)

### 9.1 Missing Examples

| Example | Python | Elixir | Rust | TypeScript |
|---------|--------|--------|------|------------|
| list_models | ✅ | ✅ | ❌ | ❌ |
| ensures_files_exist | ✅ | ❌ | ❌ | ❌ |
| broker_image_examples | ✅ | ❌ | ❌ | ❌ |

**Actions:**

#### 9.1.1 Rust/TypeScript: list_models Example (Estimated: 1 hour each)
- [ ] Rust: Create `list_models.rs` example
- [ ] TypeScript: Create `list_models.ts` example

#### 9.1.2 ensures_files_exist (Future - Low Priority)
- Python-only utility script
- Consider if needed in other implementations

### 9.2 Documentation Gaps

| Documentation | Python | Elixir | Rust | TypeScript |
|---------------|--------|--------|------|------------|
| README | ✅ | 📝 | ✅ | ✅ |
| API Reference | ✅ | 📝 | ✅ | ✅ |
| User Guide | ✅ | ✅ | ✅ | ⚠️ |
| Changelog | ✅ | ❌ | ❌ | ✅ |
| Migration Guide | N/A | ✅ | ✅ | 📝 |

**Actions:**

#### 9.2.1 Elixir: Complete README (Estimated: 2 hours)
- [ ] Add comprehensive README with examples
- [ ] Document installation
- [ ] Add quick start guide

#### 9.2.2 Elixir/Rust: Add CHANGELOG (Estimated: 1 hour each)
- [ ] Create CHANGELOG.md following Keep a Changelog format
- [ ] Document version history

#### 9.2.3 TypeScript: Complete VitePress Docs (Estimated: 1 day)
- [ ] Complete user guide sections
- [ ] Add error handling guide
- [ ] Add streaming guide
- [ ] Add architecture overview

---

## Phase 10: CI/CD and Quality Assurance (Priority: LOW)

### 10.1 Current CI/CD Status

| Feature | Python | Elixir | Rust | TypeScript |
|---------|--------|--------|------|------------|
| CI Pipeline | ✅ | ✅ | ✅ | ✅ |
| Test automation | ✅ | ✅ | ✅ | ✅ |
| Lint checks | ✅ | ✅ | ✅ | ✅ |
| Security scan | ✅ | ✅ | ✅ | ✅ |
| Doc generation | ✅ | ✅ | ✅ | ⚠️ |
| Package publish | ✅ (PyPI) | ❌ | ❌ | ⚠️ (npm ready) |

**Actions:**

#### 10.1.1 TypeScript: Documentation Deployment (Estimated: 0.5 days)
- [ ] Set up GitHub Pages deployment for VitePress docs
- [ ] Add documentation build to CI

#### 10.1.2 Elixir: Hex Publishing Setup (Future)
- [ ] Set up publishing to hex.pm
- [ ] Add documentation to HexDocs

#### 10.1.3 Rust: Crates.io Publishing Setup (Future)
- [ ] Set up publishing to crates.io
- [ ] Add documentation to docs.rs

---

## Implementation Timeline

### Sprint 1: Stabilization (Week 1) - ✅ COMPLETED November 25, 2025
- ✅ Fix Python test issues (already resolved)
- ✅ Fix Elixir test failures (already resolved)
- ✅ Verify all test suites pass (1,616 tests passing)

### Sprint 2: Core API (Week 2) - ✅ COMPLETED November 25, 2025
- ✅ CompletionConfig standardization (all 7 fields in all implementations)
- ✅ Broker API parameter alignment (numPredict added to TypeScript)
- ✅ Message constructor helpers (verified across implementations)

### Sprint 3: Gateway Features (Weeks 3-4) - ✅ COMPLETED November 25, 2025
- ✅ Image analysis support (Elixir, Rust, TypeScript) - All verified/enhanced
- ✅ Model pull support (Elixir, TypeScript) - Implemented with streaming progress

### Sprint 4: Tool System (Week 5) - ✅ COMPLETED November 25, 2025
- ✅ Tool name matching standardized (TypeScript matches() method added)
- ✅ DateResolver naming documented (Rust SimpleDateTool kept with rationale)
- ✅ Web Search Tool implemented (FREE DuckDuckGo in Elixir, Rust, TypeScript)

### Sprint 5: Agent System (Weeks 6-7) - IN PROGRESS
- [ ] BaseAgent implementations (Elixir, Rust)
- [ ] Agent integration verification

### Sprint 5: Documentation and Polish (Weeks 7-8)
- [ ] Complete all documentation gaps
- [ ] Add missing examples
- [ ] Create CHANGELOGs

---

## Idiomatic Patterns to Preserve

### Python
- **Class-based OOP** with Pydantic models
- **Exception-based error handling**
- **Synchronous API with optional async**
- **Runtime type validation**

### Elixir
- **Behaviour-based polymorphism** (not classes)
- **Result tuples** (`{:ok, value}` / `{:error, reason}`)
- **Immutable data structures** with struct transformations
- **OTP patterns** (GenServer for state, Task for async)
- **Pattern matching** for flow control

### Rust
- **Trait-based polymorphism**
- **Result<T, E> error handling**
- **Ownership and borrowing** for memory safety
- **Async/await with tokio**
- **Zero-cost abstractions**

### TypeScript
- **Interface/class hybrid approach**
- **Result type pattern** (inspired by Rust)
- **Async/await throughout**
- **Compile-time type checking**
- **Functional patterns where appropriate**

---

## Success Criteria

A feature is considered at parity when:

1. ✅ **API matches** - Same functionality available (method names may differ idiomatically)
2. ✅ **Tests pass** - Comprehensive test coverage with passing tests
3. ✅ **Documentation exists** - Both API docs and user guide coverage
4. ✅ **Example works** - Corresponding example runs successfully
5. ✅ **Quality gates pass** - Linting, formatting, security checks pass

---

## Risk Mitigation

### Technical Risks

| Risk | Mitigation |
|------|------------|
| Breaking changes | Version lock dependencies; run full test suite before merge |
| Performance regressions | Add benchmarks for critical paths |
| API drift | Regular cross-implementation reviews |

### Process Risks

| Risk | Mitigation |
|------|------------|
| Scope creep | Strict adherence to this plan; defer non-essential features |
| Knowledge silos | Use language-specific agents for all implementation work |
| Documentation lag | Update docs as part of each feature PR |

---

## Appendix A: File Location Reference

### Key Files by Implementation

**Python (mojentic-py):**
```
src/mojentic/
├── llm/
│   ├── llm_broker.py        # Main broker
│   ├── chat_session.py      # Chat session
│   └── gateways/
│       ├── ollama.py        # Ollama gateway
│       └── openai.py        # OpenAI gateway
├── agents/                   # Agent implementations
├── tracer/                   # Tracer system
└── context/                  # SharedWorkingMemory
```

**Elixir (mojentic-ex):**
```
lib/mojentic/
├── llm/
│   ├── broker.ex            # Main broker
│   ├── chat_session.ex      # Chat session
│   └── gateways/
│       └── ollama.ex        # Ollama gateway
├── agents/                   # Agent implementations
├── tracer/                   # Tracer system
└── context/                  # SharedWorkingMemory
```

**Rust (mojentic-ru):**
```
src/
├── llm/
│   ├── broker.rs            # Main broker
│   ├── chat_session.rs      # Chat session
│   └── gateways/
│       └── ollama.rs        # Ollama gateway
├── agents/                   # Agent implementations
├── tracer/                   # Tracer system
└── context/                  # SharedWorkingMemory
```

**TypeScript (mojentic-ts):**
```
src/
├── llm/
│   ├── broker.ts            # Main broker
│   ├── chat-session.ts      # Chat session
│   └── gateways/
│       └── ollama.ts        # Ollama gateway
├── agents/                   # Agent implementations
├── tracer/                   # Tracer system
└── context/                  # SharedWorkingMemory
```

---

## Appendix B: Idiomatic Code Examples

### Error Handling

**Python:**
```python
try:
    result = broker.generate(messages)
except GatewayError as e:
    logger.error(f"Gateway error: {e}")
```

**Elixir:**
```elixir
case Broker.generate(broker, messages) do
  {:ok, result} -> handle_success(result)
  {:error, reason} -> handle_error(reason)
end
```

**Rust:**
```rust
match broker.generate(&messages, None, None, None).await {
    Ok(result) => handle_success(result),
    Err(e) => handle_error(e),
}
```

**TypeScript:**
```typescript
const result = await broker.generate(messages);
if (isOk(result)) {
    handleSuccess(result.value);
} else {
    handleError(result.error);
}
```

### Tool Definition

**Python:**
```python
class MyTool(BaseTool):
    def descriptor(self):
        return {"type": "function", "function": {...}}

    def run(self, **kwargs):
        return {"result": "..."}
```

**Elixir:**
```elixir
defmodule MyTool do
  @behaviour Mojentic.LLM.Tools.Tool

  @impl true
  def descriptor, do: %{type: "function", function: %{...}}

  @impl true
  def run(args), do: {:ok, %{result: "..."}}
end
```

**Rust:**
```rust
struct MyTool;

impl LlmTool for MyTool {
    fn descriptor(&self) -> ToolDescriptor { ... }
    fn run(&self, args: &HashMap<String, Value>) -> Result<Value> { ... }
}
```

**TypeScript:**
```typescript
class MyTool extends BaseTool {
    descriptor(): ToolDescriptor { return {...}; }
    async run(args: Record<string, unknown>): Promise<Result<unknown, Error>> {...}
}
```

---

*This plan should be reviewed and updated as implementation progresses. Check items off as they are completed and update PARITY.md accordingly.*
