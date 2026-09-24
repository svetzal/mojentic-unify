# Adaptive Harness-Derived Enhancements

**Status:** Draft cross-port parity target
**Source evidence:** Sandbox2 adaptive harness experiments, especially
Generation 4 through Generation 10
**Primary reference port:** Python, then apply evenly across TypeScript,
Elixir, Rust, Swift, and Kotlin
**Last updated:** 2026-06-16

This document captures library-level Mojentic enhancements discovered while
building the Sandbox2 adaptive coding harness. The harness is intentionally an
application on top of Mojentic; only reusable primitives belong here.

The common theme is operational visibility. Agent applications need to know
what context was sent, why it was sent, how much pressure tool results add, what
the provider is doing during streaming, and whether a reasoning model is
producing useful action or only hidden reasoning.

## Evidence Sources

The originating evidence lives outside this monorepo:

- `/Users/svetzal/Work/Sandbox2/CHARTER.md`
- `/Users/svetzal/Work/Sandbox2/Experiments/Generation4/mojentic-improvement-backlog.md`
- `/Users/svetzal/Work/Sandbox2/Experiments/Generation4/model-progress-policy.md`
- `/Users/svetzal/Work/Sandbox2/Experiments/Generation9/thinking-visibility-reassessment.md`
- `/Users/svetzal/Work/Sandbox2/Experiments/Generation10/thinking-cap-assessment.md`

Do not copy the adaptive coding harness into Mojentic. Use these artifacts as
evidence for reusable tracing, streaming, context assembly, and summary
interfaces.

## Core Principle

Mojentic should provide the primitives. Applications should own the policy.

Mojentic should expose enough structured evidence for a caller to answer:

- What messages and tool results were sent to the provider?
- Why was each component included?
- How large was the effective prompt, including tool payloads?
- What stream progress did the provider report?
- Did the provider produce visible content, tool-call arguments, reasoning, or
  no actionable output?
- Which trace summary fields let separate ports compare behavior evenly?

The adaptive harness can then decide whether to retry, compact context,
interrupt a stream, narrow a work packet, or stop a run.

## Enhancement Set

### 1. Context Assembly Ledger

**Need:** Before each provider call, emit a trace event describing the assembled
prompt.

Minimum event fields:

- correlation id and parent call id
- policy name, initially `append_full_tool_transcript`
- component list with role, component kind, inclusion reason, and size
- message counts by role
- tool descriptor size
- estimated prompt tokens
- optional context window and utilization
- pressure band: `green`, `yellow`, `orange`, or `red`
- delta from the previous provider call in the same conversation or run

This should be emitted immediately before each `complete` or `completeStream`
gateway call. The goal is to answer, "Why is this text in the prompt now?"

### 2. Context Append Events

**Need:** Recursive tool execution mutates the next provider call by appending
assistant tool-call messages and tool-result messages. That append step must be
trace-visible.

Minimum event fields:

- correlation id
- appended component kind: assistant tool call or tool result
- tool name and tool call id when available
- success, error class, and duration when available
- message size and estimated tokens
- append reason

These events should share the parent correlation chain with the provider call
that produced the tool request.

### 3. Tool Payload Measurement

**Need:** Tool results can create effective context pressure even when the
outer user prompt is small.

Minimum measurement fields:

- tool name or kind
- result character count and estimated token count
- cumulative tool-result size for the run/session
- largest single tool payload
- payload totals by tool kind

Emit these measurements at the tool runner boundary. Keep raw tool results
available to existing callers, but make size and pressure observable.

### 4. Provider Stream Progress And Metrics

**Need:** Local model runs can appear quiet while the provider is actively
generating content, hidden reasoning, or tool-call JSON. Mojentic should not
force applications to guess from wall-clock time.

All ports should expose provider-neutral stream events for:

- visible content chunks
- tool-call argument progress when the provider supports it
- reasoning or thinking chunks when the provider exposes them
- raw/progress heartbeats when visible output is not available
- final provider metrics

Provider metrics should preserve fields when available, including:

- generated token count
- generation duration
- prompt evaluation token count
- prompt evaluation duration
- total duration
- load duration
- derived tokens per second

Ollama should preserve `eval_count`, `eval_duration`, `prompt_eval_count`,
`prompt_eval_duration`, `total_duration`, and `load_duration` where available.
Other providers should map their closest equivalents.

### 5. Progress State Classification

**Need:** Applications need common language for stream health.

Mojentic should provide a small provider-neutral classification helper or event
shape with these states:

- `WaitingForFirstToken`
- `Generating`
- `GeneratingToolCall`
- `GeneratingReasoning`
- `ProgressUnknown`
- `PossiblyStalled`
- `Stalled`

Mojentic should emit evidence, not decide application-level stop policy.
Applications decide when to interrupt or adapt.

### 6. Thinking And Reasoning Accounting

**Need:** Reasoning models can spend large budgets in hidden or surfaced
thinking without producing assistant content, a tool call, or terminal output.

All ports should expose:

- reasoning chunk events when available
- per-call reasoning character and token estimates
- whether assistant-visible content was produced
- whether a tool call was started or completed
- whether the call ended with reasoning only

This lets applications distinguish:

- empty provider response
- tool-only response
- content response
- reasoning-only response
- no-action response after prior useful tool calls

### 7. Trace Summary API Or CLI

**Need:** Raw traces are too detailed for parity and experiment comparison.

Provide a reusable machine-readable summary with at least:

- provider call count
- max estimated context tokens and max context utilization
- pressure band counts
- appended message counts and sizes
- cumulative tool payload tokens
- largest tool payload
- stream progress and metric event counts
- observed output tokens and max observed tokens per second
- failed tool count
- final status when trace events contain one

Ports can expose this as a CLI, library function, or both, but the summary
schema should be shared.

### 8. Context Assembly Policy Hooks

**Need:** Full transcript retention is simple, but not always useful for small
or heavily quantized local models.

After the ledger and append events exist, add an extension point for context
assembly policy. The first behavior must preserve current semantics:
`append_full_tool_transcript`.

Candidate policies:

- `summarized_transcript`
- `tool_result_decay`
- `latest_failed_validation_preserved`
- `source_reread_over_retention`
- `model_sensitive_budget`

These are policy hooks, not mandatory default behavior.

### 9. Validation Output Summaries

**Need:** Agent applications often need precise validation failure evidence
without retaining a full shell transcript.

Provide a reusable summarizer shape for command-like tool output:

- command
- exit status
- success flag
- first useful failure line
- stderr tail
- stdout tail
- truncation counts
- command family
- normalized failure summary

This can live as a utility or optional tool-runner adapter. Mojentic should not
assume every shell command is validation.

## Non-Goals

These remain application or harness policy:

- Space Invaders benchmark logic
- Bevy-specific guidance
- coding-agent packet generation
- source-edit validation ladders
- repair hard-stop thresholds
- model-family experiment choices
- automatic interruption rules
- project-specific file scoping rules

Mojentic should make those policies possible and observable, not choose them.

## Cross-Port Acceptance Criteria

Each accepted enhancement should satisfy these criteria before being marked
complete in `PARITY.md`:

- Python reference implementation defines the public shape and behavior.
- Shared event names and field names are documented.
- Each port has tests for the event or summary schema.
- Existing broker and gateway APIs remain backward compatible unless a major
  release explicitly changes them.
- Provider-specific fields are preserved behind an escape hatch without
  preventing provider-neutral summaries.
- Documentation names the feature consistently across all ports.

## Suggested Rollout

1. Define shared schemas for ledger, append, payload, stream metric, progress
   state, reasoning accounting, and trace summary.
2. Implement the Python reference.
3. Bring Rust into alignment, reusing the Sandbox harness evidence to validate
   names and edge cases.
4. Port to TypeScript and Elixir.
5. Apply the same surface to Swift and Kotlin planned/stabilization work.
6. Only then add optional context assembly policy hooks beyond full transcript
   behavior.

This order keeps observability stable before introducing cross-port policy
variation.
