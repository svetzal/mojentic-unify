# Mojentic 3.0.0

Status: agreed with Stacey on 2026-10-15. Delivered by the Foundry initiative
`mojentic-3-0` on `mojility-ops-01`. This file is the initiative's brief.

3.0.0 is one coordinated major release of all six ports, followed by moving
every consumer to it. It replaces a planned 2.2.0: the unreleased work on the
ports' `main` branches already breaks the 2.1.0 public API (Rust's reasoning
types, Kotlin's iOS removal, a TypeScript union member), so it cannot ship as a
minor release.

## What 3.0.0 contains

Every port implements all of it. The same version means the same features in
every language (`AGENTS.md`).

1. **Transient completion recovery, finished.** `TRANSIENT-RECOVERY-2026-10.md`
   including its October 12 robustness amendment. Every port has the October 9
   contract; only Swift conforms to the amendment. Elixir does not conform to
   items 2, 5 and 7, and the contract says the root file overrides a port's own
   behaviour, so Elixir changes too. Swift's `RECOVERY-CONFORMANCE.md` maps
   every binding decision to a named test; each port ends with an equivalent
   conformance document.
2. **Native reasoning across all ports.** `REASONING-PROTOTYPE-2026-10.md`,
   which Rust prototyped (commit `67791b7`). 3.0.0 authorizes it for every
   port: native reasoning kept separate from content, the effort values
   Disabled, Enabled, Low, Medium, High and XHigh without conflation (this is
   the "disabled reasoning parity" earlier notes deferred to 2.2.0), explicit
   caller-selected model profiles, and opt-in reasoning retention. Rust is the
   reference for this part.
3. **Model metadata and request fidelity.** `MODEL-METADATA-2026-10.md`:
   `get_model_context_window`, client-measured first-token timing, and gateways
   that send only the parameters the caller set (`max_tokens` is the only
   output limit; `num_predict` is removed). Fixes issue #1.
4. **Kotlin drops iOS targets** (Stacey, 2026-10-11). Each port serves its own
   ecosystem. Documented as a breaking change in Kotlin's CHANGELOG.
5. **Bugs found in the 2026-10-15 audit.** #2 (mojentic-py Anthropic drops
   assistant messages; the same filter is copied into the new recovery body,
   so it appears twice), #3 (mojentic-ru casts a negative `num_predict` with
   `as usize`), #4 (mojentic-ts `ChatSession` turns temperature 0 into 1.0).

## Known per-port state at the start (2026-10-15 audit)

| Port | Remaining work |
| ---- | -------------- |
| Elixir | Recovery amendment items 2, 3 (capability citations), 5 (Retry-After date forms), 7 (oMLX keepalive in recovery streams, inferred from source) and 8; HTTP 500/502 tests; CHANGELOG does not mention recovery. Then reasoning (part 2) and part 3. |
| Python | Anthropic recovery covers ordinary completion only; amendment items 1, 2, 3, 8; CHANGELOG has a recovery entry under 2.1.0 by mistake; bug #2. Then parts 2 and 3. |
| Rust | Amendment items 2, 3, 8 and 500/502 tests; CHANGELOG describes only the prototype; bug #3; 46 committed `.foundry/logs` files would ship in the crate (add an `include` list). Part 2 is done as the reference; part 3. |
| TypeScript | Amendment items 2, 3, 5, 8; CHANGELOG does not mention recovery; bug #4. Then parts 2 and 3. |
| Swift | macOS CI "Test" step failing on every run since 2026-10-12 (cause unknown); run its API-breaking-change check. Then parts 2 and 3. |
| Kotlin | Amendment items 1, 3, 6, 8; `Mojentic.VERSION` reads `0.3.0-SNAPSHOT`; build-tool CVE suppressions expire 2026-12-23. Then parts 2 and 3. |

The audit is a starting point, not a checklist. Each port verifies its own
state against the contracts before acting on it.

## Rules for every port

- Work lands on the port's `main`. Do not change more than one port per commit.
- The contracts in this repository are binding. When a contract is silent,
  Elixir's behaviour is the reference, except for part 2, where Rust's is.
- When a port finds a contract gap or ambiguity, it reports it through the
  initiative as a finding. It does not decide a contract change on its own.
  Contract changes are made in this repository and relayed to every port.
- Each port's CHANGELOG `Unreleased` section must accurately describe every
  change since 2.1.0, with a breaking-changes section and migration notes.
- Every port's `AGENTS.md` still carries a "Coordinated 2.1.0 release
  authorization" section. Replace it with a 3.0.0 authorization that points
  here.
- Run the port's whole `.hone-gates.json` before every landing.

## Release

Releasing is part of the initiative.

- A port is ready when parts 1 to 5 are implemented, its conformance document
  maps every contract decision to a test, its CHANGELOG is accurate, and its
  gates and CI pass.
- Release only when all six ports are ready, so 3.0.0 appears everywhere with
  the same features. Then release each port with its normal process
  (`foundry release <port> --bump major`, which follows the port's
  `AGENTS.md`), stopping on any failure.
- Verify each published package with a fresh consumer install, as the 2.1.0
  release did (`RELEASE-2.1.0.md`). Kotlin's first upload without iOS has fewer
  Maven Central coordinates than 2.1.0's 36. Its Sonatype token expires
  2027-03-30 and its signing key 2028-09-29.
- Record the release in a `RELEASE-3.0.0` record section of this file: commits,
  CI runs, registry links and install checks per port.

## Consumers

After the release, each consumer moves to a `3.0` version range from the
package registry, never a git commit or branch pin (Operations `AGENTS.md`,
"Our own projects depend on each other by released version"):

- `bedrock` (`apps/bedrock/mix.exs`, now pinned to `mojentic-ex@e6ade1c`) and
  `bedrock-workshop` (`mix.exs`, pinned to `82879d3`): `{:mojentic, "~> 3.0"}`
  from Hex, keeping the `MOJENTIC_SOURCE` path override for local development.
  Bedrock deploys to production on every push to `main`; its full gates must
  pass before landing.
- `microgentic` (pinned to `mojentic-ru@4ca1ed2`): `mojentic = "3.0"` from
  crates.io. It then switches to Mojentic's `get_model_context_window` and
  first-token metrics, and deletes its local `src/model_metadata.rs` and
  `src/first_token.rs` in a commit of its own. Its benchmark-continuity tests
  must still pass.

## Done

- All six ports publish 3.0.0 with parts 1 to 5, verified by a fresh install.
- Each port has a conformance document for parts 1 to 3 and an accurate
  CHANGELOG.
- `bedrock`, `bedrock-workshop` and `microgentic` depend on `3.0` from their
  package registries, with no git pins, and their gates pass.
- `PARITY.md` has rows for every part, and the submodule pointers in this
  repository move to the 3.0.0 commits in one commit.
