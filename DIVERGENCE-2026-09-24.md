# Port divergence report, 2026-09-24

Snapshot of how the six Mojentic ports differ as of 2026-09-24, and a proposed
path back to sync. `PARITY.md` is the long-lived tracker; this file is a dated
audit and is not updated after today.

Method: git history of each submodule since 2026-05-15, unreleased CHANGELOG
sections, published registry versions, and targeted source greps. Items marked
"inferred" come from greps, not from running the code.

## Summary

The ports were at parity on 2026-05-21, when Python, Elixir, and Rust shipped
1.5.0 and Swift and Kotlin finished their catch-up phases. Since then:

1. **A coordinated feature wave on 2026-09-08 is unreleased everywhere** and
   uneven in scope. Five ports committed it. Kotlin has it only as uncommitted
   work in its working tree.
2. **Elixir moved ahead alone** with four broker and streaming behaviours
   between 2026-09-08 and 2026-09-19.
3. **Rust moved ahead alone** with Ollama thinking and stream-progress
   primitives between June and August. These are early pieces of the adaptive
   harness plan, built before that plan's shared schema exists.
4. **Version numbers no longer agree**, which breaks the "major and minor stay
   in sync" rule.
5. **The monorepo's own records are stale.** `PARITY.md` has uncommitted edits
   from June and September, two planning docs are untracked, and all six
   submodule pointers lag.

## Versions

| Port | Manifest | Latest tag | Published | Notes |
| ---- | -------- | ---------- | --------- | ----- |
| Python | 1.5.0 | v1.5.0 | PyPI 1.5.0 | 89 commits past tag |
| Elixir | 1.5.0 | v1.5.0 | Hex 1.5.0 | |
| Rust | 1.5.0 | v1.5.0 | crates.io 1.5.0 | |
| TypeScript | 1.5.1 | v1.5.1 | npm 1.5.0 | v1.5.1 tagged 2026-06-16, never published. Local clone 3 commits behind origin |
| Swift | 2.0.0 | v2.0.0 | SPM (git tag) | Jumped to 2.0 on 2026-05-18 ("Realtime is the 2.0 line"). Other ports shipped Realtime in 1.5 |
| Kotlin | 0.1.0-SNAPSHOT | none | Maven Central: nothing | CHANGELOG plans a v1.4.0 push that never happened |

Swift is a major version ahead and Kotlin has never released. Neither matches
the 1.5 line.

## The 2026-09-08 wave: native responses and unlimited tool rounds

All ports use the same public names: `generate_response` / `generateResponse`,
and a nullable or symbolic "unlimited" tool-iteration setting. That part is
consistent. The scope around it is not.

| Capability | Py | Ex | Ru | TS | Sw | Kt |
| ---------- | -- | -- | -- | -- | -- | -- |
| Single native response API | ✅ | ✅ | ✅ | ✅ | ✅ | WIP |
| Explicit unlimited tool rounds | ✅ | ✅ | ✅ | ✅ | ✅ | WIP |
| Caller `tool_context` (cancellation, callbacks) | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ |
| Unknown tools produce error outcomes | ✅ | ? | ? | ? | ✅ | WIP |
| Committed | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Released | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

"?" means the port's CHANGELOG does not claim it and a grep did not settle it.

Kotlin's uncommitted work (12 files, dated 2026-09-08) covers the broker API,
nullable `maxToolIterations`, ordered unknown-tool outcomes, bounded
`ParallelToolRunner`, a new `docs/use-cases/native-responses.md`, and an
updated API dump. It also bundles an unrelated Dependency-Check upgrade. It has
not been built or tested in this audit.

## Elixir-only behaviour (2026-09-08 to 2026-09-19)

| Change | Commit | In other ports |
| ------ | ------ | -------------- |
| Continue a response that stopped at the token limit (`finish_reason: "length"`) by appending a continuation prompt | 82879d3 | None |
| Return `{:error, {:incomplete_completion, reason}}` for any finish reason other than stop or length | 82879d3 | None. Other ports return whatever content arrived |
| Keep reported usage, provider model, finish reason, and metadata on `LLMResponseTracerEvent`; absent usage stays nil | 065649e | None (inferred) |
| Forward configured structured output (`response_format`) in OpenAI streaming requests | 5db5039 | None (inferred) |
| Keep single-request streaming completion and cancellation evidence | 11a5622 | None |
| Load struct tool modules before reading descriptors | e6ade1c | Elixir-specific, no port needed |

The length-continuation and incomplete-completion changes alter what callers
get back. They are the most important divergence in this report: the same
prompt now behaves differently in Elixir than in the other five ports.

### Where the Elixir drift came from

Every Elixir-only change was made for Bedrock's workshop agent and landed
within minutes of a matching Bedrock commit
(`~/Work/Projects/Mojility/bedrock-workspace/bedrock`):

| mojentic-ex | Bedrock | Bedrock commit |
| ----------- | ------- | -------------- |
| 11a5622, 09-08 02:42 | 13ff5c8, 02:46 | Collect workshop model streams with explicit completion evidence |
| ab4ac60, 09-08 21:45 | 3f5bad1, 22:00 | Use native Mojentic tool requests with caller-owned workshop context |
| 065649e, 09-09 03:41 | 2c25e4f, 03:45 | Recover workshop usage through Mojentic response traces |
| 82879d3, 09-19 11:17 | 83fd981, 11:18 | Resume length-limited workshop turns |

Bedrock's `docs/mojentic-broker-review.md` (e1712f1, 2026-09-08) is also where
the cross-port wave started. Its recommendations became the September changes
in all six ports. The follow-ups after that stayed in Elixir only.

Bedrock pins mojentic-ex by commit. `apps/workshop_executive` is pinned to
82879d3, and its test `a length-limited model response continues before
completion` depends on the library continuing. `apps/bedrock` is pinned to
e6ade1c, before that change. Reverting in mojentic-ex therefore means moving
continuation into Bedrock first.

By contrast, the Rust-only stream features below are consumed by the Sandbox2
benchmark harness (`~/Work/Sandbox2/Harness`), which is also the evidence
source for `ADAPTIVE-HARNESS-ENHANCEMENTS.md`.

## Rust-only behaviour (2026-06-12 to 2026-08-09)

| Change | Commit | In other ports |
| ------ | ------ | -------------- |
| `StreamChunk::Progress` and `StreamChunk::Metrics` for Ollama (eval counts and durations) | 9c2624a | None. TypeScript and Swift read eval counts into usage only |
| Streamed Ollama thinking chunks, with `thinking_chars` accounting | c1058e4 | None |
| Explicitly disable Ollama thinking (`think: false`) | 6874a3d | None. The other five send `think: true` when reasoning effort is set and omit it otherwise |
| Fixed-width PCM samples without raising MSRV | 03a923b | Rust-specific |

These map onto items 4 and 6 of `ADAPTIVE-HARNESS-ENHANCEMENTS.md`. That plan
says Python defines the reference shape first. Rust got there first instead,
so its enum shape is now the de facto draft.

## Long-standing gaps still open

| Gap | Ports affected |
| --- | -------------- |
| Anthropic gateway | Elixir, Rust, TypeScript. (`PARITY.md` contradicts itself on Swift: ✅ in the gateway table, 📝 in the docs table. Swift has the gateway behind a package trait) |
| Adaptive harness enhancements 1 to 9 | All ports planned; only Rust has partial pieces |

## Monorepo housekeeping

- `PARITY.md`: uncommitted since 2026-09-09. The diff adds the adaptive
  harness table and reformats tables. It still says "four implementations" in
  its first line.
- `ADAPTIVE-HARNESS-ENHANCEMENTS.md` (2026-06-16) and `REALTIME.md`: untracked.
- All six submodule pointers are behind their `main`.
- `.claude/settings.local.json`: uncommitted permission additions
  (`gh repo *`, `rm *`).

## Proposed next steps

### Step 1: land what exists

1. Kotlin: split the working tree into two commits (Dependency-Check upgrade,
   then the native-responses wave), run the full Gradle gate, push.
2. Commit `PARITY.md`, `ADAPTIVE-HARNESS-ENHANCEMENTS.md`, and `REALTIME.md`,
   then bump all six submodule pointers.
3. Pull TypeScript to origin.

### Step 2: close the September wave

1. Decide on the Elixir-only behaviours (see decisions below). Then either
   port them to the other five or revert them in Elixir.
2. Add caller `tool_context` to Rust, Swift, and Kotlin.
3. Confirm unknown-tool error outcomes in Elixir, Rust, and TypeScript, with a
   test in each.
4. Update `PARITY.md` with a row for each of these.
5. Cut one coordinated release across all six ports with the same major and
   minor version.

### Step 3: adaptive harness primitives

1. Write the shared schemas the plan asks for (stream progress, metrics,
   reasoning accounting, trace usage) before any more port-local work.
   Use Rust's `StreamChunk` variants and Elixir's trace usage fields as the
   starting draft, since they already exist.
2. Build the Python reference against the schema.
3. Retrofit Rust and Elixir to the agreed names, then port to TypeScript,
   Swift, and Kotlin.
4. Ollama `think: false` goes into the same schema pass as a reasoning-effort
   value, so all ports can turn thinking off.

### Step 4: Anthropic gateway for Elixir, Rust, TypeScript

Unchanged from the existing plan. Sequence it after step 3, because the
gateway should emit the new usage and reasoning evidence from the start.

## Decisions needed

These block step 2's release. Recorded in the Operations to-do list.

1. **Elixir's length continuation and incomplete-completion error: adopt in
   all ports, or revert?** Adopting changes return behaviour in five ports.
2. **Version for the coordinated release.** Swift is at 2.0.0, the rest at
   1.5.x, Kotlin unreleased. My recommendation: release every port as 2.1.0.
   The September wave changes `maxToolIterations` to nullable in typed ports
   and, if adopted, changes return behaviour, so a major bump is defensible.
   Swift's early 2.0.0 then becomes a one-off rather than a permanent offset.
3. **Kotlin's first public release:** join the coordinated release, or ship
   separately? It also needs the repo-admin steps from its CHANGELOG (Pages,
   six CI secrets).
