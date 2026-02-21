# Mojentic Monorepo — Agent Guidance

This file provides shared guidance for all AI agents working across the Mojentic monorepo. Each sub-project also has its own `AGENTS.md` with language-specific detail — consult it when working inside that sub-project.

## Project Overview

Mojentic is a multi-language agentic framework providing simple, flexible LLM interaction capabilities. The monorepo contains four language ports:

| Sub-project | Language | Role |
|-------------|----------|------|
| `mojentic-py/` | Python | **Reference implementation** — all ports follow this API design |
| `mojentic-ts/` | TypeScript | Port |
| `mojentic-ex/` | Elixir | Port |
| `mojentic-ru/` | Rust | Port |

**PARITY.md** tracks feature completeness across all implementations. When adding features to one port, check PARITY.md and update it accordingly.

## Cross-Language Coordination

- The Python implementation is the **source of truth** for API design and feature behaviour
- Changes to the Python reference should be reflected in PARITY.md, flagging work needed in other ports
- Each port must maintain its own quality gates independently (see sub-project `AGENTS.md`)
- Do not change multiple ports in a single commit — make focused, per-port changes

## Shared Engineering Principles

All craftsperson agents used in this project should share the same core philosophy.

### Code is Communication

Every line written optimises for the next human reader. Variable names reveal intent, function signatures document contracts, module boundaries reflect domain concepts.

### Simple Design Heuristics (in priority order)

1. **All tests pass** — Correctness is non-negotiable. Never compromise on passing tests.
2. **Reveals intent** — Code should read like an explanation. Prefer `calculate_compound_interest()` over `calc()`.
3. **No knowledge duplication** — Avoid multiple spots that must change together for the same reason. Identical code is fine when it represents independent decisions that might diverge.
4. **Minimal entities** — Remove unnecessary indirection. Don't create abstractions until you need them.

When these heuristics conflict with stated requirements, explicitly surface the tension and consult the user.

### Small, Safe Increments

- Make single-reason commits that could ship independently
- Avoid speculative work (YAGNI — You Aren't Gonna Need It)
- Build the simplest thing that could work, then refactor

### Tests Are the Executable Spec

- Write tests first (red) to clarify what you're building
- Make them pass (green) with the simplest implementation
- Tests verify behaviour, not implementation details
- Only mock gateway/boundary classes, never mock library internals
- Do not test gateway (I/O isolating) classes unless they have custom logic

### Functional Core, Imperative Shell

- Isolate pure business logic in the core (no side effects, easy to test)
- Push I/O, state changes, and side effects to the shell boundaries
- **Gateway Pattern**: All external interactions (databases, APIs, file systems, HTTP) go through gateway classes. Gateway classes should be thin wrappers around underlying libraries with no logic.
- Core functions should be pure: same inputs always produce same outputs

### Compose Over Inherit

- Favour composition and interface/protocol/trait-based polymorphism over inheritance
- Prefer pure functions; contain side effects at boundaries

## Per-Language Quality Gates

Each port enforces its own mandatory quality checks. **All gates must pass before considering work complete.** See the sub-project `AGENTS.md` for the exact commands.

| Language | Linting | Testing | Security |
|----------|---------|---------|----------|
| TypeScript | ESLint (`--max-warnings 0`) + Prettier | Jest | `npm audit --omit=dev --audit-level=moderate` |
| Python | flake8 (zero warnings) | pytest | `pip-audit` |
| Elixir | `mix credo --strict` (zero warnings) + `mix format` | ExUnit | `mix audit` |
| Rust | `cargo clippy --all-targets --all-features -- -D warnings` + `cargo fmt` | `cargo test` | `cargo deny check` |

## Per-Language Documentation

Each port maintains its own end-user documentation. Update docs in the same commit as code changes.

| Language | Docs tool | Location |
|----------|-----------|----------|
| TypeScript | VitePress | `mojentic-ts/docs/` |
| Python | MkDocs | `mojentic-py/docs/` |
| Elixir | ex_docs | `mojentic-ex/guides/` |
| Rust | mdBook | `mojentic-ru/book/src/` |

## Code Review Mindset

- Review code, not colleagues
- Critique ideas with curiosity: "What if we...", "Have we considered..."
- Assume positive intent
- Psychological safety is paramount

## Escalation

Seek user guidance when:
- Design heuristics conflict with stated requirements
- A change in one port requires coordinated changes across multiple ports
- Security findings require architectural changes
- PARITY.md reveals ambiguity in what "feature parity" means for a given capability
- Performance needs might compromise clarity
