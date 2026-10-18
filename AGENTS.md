# Mojentic Monorepo — Agent Guidance

This file provides shared guidance for all AI agents working across the Mojentic monorepo. Each sub-project also has its own `AGENTS.md` with language-specific detail — consult it when working inside that sub-project.

## Project Overview

Mojentic is a multi-language agentic framework providing simple, flexible LLM interaction capabilities. The monorepo contains six language ports. Five ship releases; Kotlin is feature-complete but not yet published:

| Sub-project | Language | Role |
|-------------|----------|------|
| `mojentic-py/` | Python | Port (original implementation) |
| `mojentic-ts/` | TypeScript | Port |
| `mojentic-ex/` | Elixir | **Reference implementation** — new capabilities land here first |
| `mojentic-ru/` | Rust | Port |
| `mojentic-sw/` | Swift | Port |
| `mojentic-kt/` | Kotlin | Port (not yet published — see KOTLIN.md) |

**PARITY.md** tracks feature completeness across all implementations. When adding features to one port, check PARITY.md and update it accordingly.

**PARITY.md is the only home for cross-port status.** What each port has, where ports diverge, known divergences a release ships with, and planned alignment work all go in PARITY.md, in the section they belong to. Do not create a separate file for a divergence report, audit, survey, snapshot or alignment plan, dated or not; update PARITY.md and let git keep the history. The only other documents at the root are binding contracts the ports implement (`ALIGNMENT-2026-09.md`, `OMLX-2026-09.md`, `MODEL-METADATA-2026-10.md` and similar) and release plans (`RELEASE-X.Y.Z.md`). Their implementation status still goes in PARITY.md. Before creating any new root document, check whether it is really a contract; if it records state, it belongs in PARITY.md. (Stacey, 2026-10-17, after dated divergence reports kept accumulating beside PARITY.md.)

## Cross-Language Coordination

- The Elixir implementation is the **source of truth** for API design and feature behaviour. New capabilities are prototyped there first because an active Elixir product (Bedrock) drives them. Every port is kept at feature parity; Elixir leads only in time.
- New cross-port capabilities get a contract document at the monorepo root (for example `ALIGNMENT-2026-09.md`): the binding behaviour, not progress or status. Elixir implements it first; the other ports follow the contract, and Elixir's behaviour where the contract is silent. Progress against the contract is tracked in PARITY.md.
- Changes to the Elixir reference should be reflected in PARITY.md, flagging work needed in other ports
- **Each port serves its own platform ecosystem and nothing more.** Python serves Python, Kotlin serves the JVM and Android, Swift serves Apple platforms (and Swift on Linux). A port does not target another port's ecosystem: Kotlin has no iOS targets, because native Apple apps use `mojentic-sw`. Do not add cross-ecosystem targets, bridges or distributions without Stacey's explicit decision. (Stacey, 2026-10-11, when iOS was dropped from Kotlin.)
- Each port must maintain its own quality gates independently (see sub-project `AGENTS.md`)
- Do not change multiple ports in a single commit — make focused, per-port changes
- **Major and minor versions stay synchronised across all six ports.** The same `X.Y` means the same feature set in every language. A feature that bumps the minor version in one port ships in all six under that version; patch versions may differ. Before tagging any port, check the others' latest tags.

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
- **No test makes a real network connection.** Tests do not open sockets,
  start local or scripted HTTP servers, or call any service, a package registry
  included. To test the real HTTP client, use the HTTP library's own in-process
  test transport (`URLProtocol`, a Req test adapter or plug, Ktor `MockEngine`,
  an injected `fetch`, a stub `httpx` transport). Inject the clock and the
  sleeper; tests do not sleep for real time or assert wall-clock thresholds.
  No suite in any port is an exception. (Stacey, 2026-10-18, after real-server
  tests made CI slow and hung Swift CI for up to six hours.)

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
| Swift | `swiftlint --strict` + `swift format lint --strict` | `swift test --parallel` (Swift Testing) | GitHub Dependabot + manual `Package.resolved` review |
| Kotlin | `./gradlew ktlintCheck detekt` | `./gradlew allTests` (`kotlin.test` + Turbine + Ktor MockEngine) | OWASP Dependency-Check (`./gradlew dependencyCheckAggregate`) |

## Per-Language Documentation

Each port maintains its own end-user documentation. Update docs in the same commit as code changes.

| Language | Docs tool | Location |
|----------|-----------|----------|
| TypeScript | VitePress | `mojentic-ts/docs/` |
| Python | MkDocs | `mojentic-py/docs/` |
| Elixir | ex_docs | `mojentic-ex/guides/` |
| Rust | mdBook | `mojentic-ru/book/src/` |
| Swift | DocC | `mojentic-sw/Sources/Mojentic/Mojentic.docc/` |
| Kotlin | Dokka v2 | `mojentic-kt/docs/` |

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
