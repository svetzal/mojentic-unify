# Mojentic 2.1.0 release record

Authorized by Stacey on September 30, 2026. All six ports are released as 2.1.0.

## Scope

Release all six ports as 2.1.0. Python, TypeScript, Elixir, Rust, and Kotlin skip
2.0.0. Kotlin joins with its first Maven Central release. Swift was previously at
2.0.0. All six ports now have a 2.1.0 release commit and matching v2.1.0 tag.

Include the oMLX gateway, September streaming and trace alignment, message
adapter corrections, streamed tool-call corrections, and embedding bug fixes.
The contracts are `OMLX-2026-09.md` and `ALIGNMENT-2026-09.md`.

## Decisions and prerequisites

- Disabled reasoning parity is deferred to 2.2.0. Rust keeps its existing
  value; no port changes that behavior for this release.

- Ordinary `generate` finish handling keeps each port's current behavior.
  Cross-port rejection of non-stop finishes is deferred to a later major release.

- Swift and Kotlin keep whole-text embeddings as a documented 2.1.0 exception.

- Kotlin publishing credentials are configured as of September 30. Sonatype
  verified `com.vetzal` through Route 53; Kotlin uses `com.vetzal.mojentic`.
  All five repository secrets are installed. The GPG public key is published,
  and detached POM signatures verified for all six modules. Private material
  is in `~/Keys/mojentic/`, outside the repositories. The Sonatype token expires
  March 30, 2027; the signing key expires September 29, 2028. The signed
  upload passed Central validation. Deployment `219ebb0d-b366-4869-939c-9926b1501bf2`
  contains 36 coordinates across the six modules, covering common metadata,
  JVM, Android and three iOS targets. All 36 public POMs and their detached
  signatures are verified against release key
  `C7F060F905F5222ECC7D0D258D7C3CDCE4DA9E1B`. A fresh Gradle JVM consumer
  resolved all six modules from Maven Central, compiled and ran successfully.

- Foundry release is enabled for all six ports, including Swift and Kotlin.

- Exact-version instructions in each port's `AGENTS.md` produced 2.1.0.
  Every release tag points at its version and changelog commit.

The scope decisions and credential setup are complete.
Swift and Kotlin's automatic long-text embedding support remains deferred.
Neither port averages embeddings, so neither had the weighting bug.

## Accepted limits

The oMLX embedding success path has fake-transport coverage but no live test.

The live server had no embedding model during the gateway work. Swift's Apple events
transport does not expose error bodies. Some streams do not expose Warning
headers.

The oMLX contract accepts those transport limits.

## Release procedure used

1. Sync each port with its remote `main`.
2. Run the full quality gate specified in each port's `AGENTS.md`.
3. Check every Unreleased section against its final commits.
4. Check every port's latest tag before changing versions.
5. Configure the exact coordinated version in the Foundry release context.
6. Run `foundry release <project>` separately for each port.
7. Wait for each publishing pipeline to finish successfully.
8. Check the published package version in each package registry.
9. Install each published artifact for a smoke test.
10. Update the parent pointers for all six submodules in one scoped commit.
11. Record the published versions and results in `PARITY.md`.

The projects are `mojentic-ex`, `mojentic-py`, `mojentic-ts`, `mojentic-ru`,
`mojentic-kt`, and `mojentic-sw`. Work lands directly on `main`.
Stop on a publishing failure before proceeding with another port.
Do not change the unrelated `.claude/settings.local.json` file.

## Second audit results, September 30

The second audit found and corrected stream validation, partial evidence,
model validation, authentication precedence, and cancellation discrepancies.
All six ports passed their local quality gates after those corrections.

| Port | Validation | Release route |
| ---- | ---------- | ------------- |
| Elixir | 841 tests, strict Credo, format, dependency audits, docs | Hex token exists |
| Python | 516 tests, strict flake8, pip-audit, Bandit, package builds, docs | PyPI OIDC workflow |
| TypeScript | 870 tests, coverage thresholds, lint, format, build, audits, docs | npm OIDC workflow |
| Rust | 539 unit tests, 54 integration tests, 18 doctests, Clippy, audits, verified package | crates.io token exists |
| Swift | 254 default tests, 255 with all traits, format, lint, build, DocC, OSV | Git tag for SwiftPM |
| Kotlin | JVM, Android and iOS build/tests, lint, API check, Dokka, full dependency audit | Maven namespace, signing and token configured |

Kotlin's NVD feed was current at September 30, 12:00 EDT. The full audit
reported zero unsuppressed findings after documented review of its matches.
The suppression file records exact artifacts, evidence, and December 23 expiries.
The bundled protobuf exception remains limited to Android lint's compiler.
The audit includes build tools and published configurations.

The later publication pass confirmed PyPI and npm trusted publishing, Hex
and crates.io token access, and Kotlin's Central token and signing setup.

## Publication results, September 30

All six publishing workflows passed. Each GitHub release is 2.1.0 and each tag
points at the audited release commit below. Foundry ran every release.

| Port | Release commit | Publishing workflow | Consumer verification |
| ---- | -------------- | ------------------- | --------------------- |
| Elixir | [765808c](https://github.com/svetzal/mojentic-ex/commit/765808c3e9f76d73459452d87923b23380c2bcd9) | [Passed](https://github.com/svetzal/mojentic-ex/actions/runs/36789257377) | Fresh registry install and import/compile passed |
| Python | [0ef58d5](https://github.com/svetzal/mojentic/commit/0ef58d57cf49b756667d14572a50126e3e0312a8) | [Passed](https://github.com/svetzal/mojentic/actions/runs/36791160120) | Fresh registry install and import/compile passed |
| TypeScript | [9cd6587](https://github.com/svetzal/mojentic-ts/commit/9cd658760520b9520a516d818105d4bbe2751598) | [Passed](https://github.com/svetzal/mojentic-ts/actions/runs/36791349706) | Fresh registry install and import/compile passed |
| Rust | [29a549e](https://github.com/svetzal/mojentic-ru/commit/29a549e807f6bab32bba39ea40a284a34b7eeffb) | [Passed](https://github.com/svetzal/mojentic-ru/actions/runs/36791916469) | Fresh registry install and import/compile passed |
| Swift | [618eb7b](https://github.com/svetzal/mojentic-sw/commit/618eb7b42ff2b74e6ff9bb6fd9f3c65373da2262) | [Passed](https://github.com/svetzal/mojentic-sw/actions/runs/36792393408) | Fresh SwiftPM exact 2.1.0 build and run passed |
| Kotlin | [df00ff2](https://github.com/svetzal/mojentic-kt/commit/df00ff22fa488ef6208243e78ad2eb8b9be89e9c) | [Passed](https://github.com/svetzal/mojentic-kt/actions/runs/36790184332) | All 36 signed POMs verified; fresh six-module Gradle build and run passed |

Elixir's first release attempt exposed real-socket timeout tests that failed
under concurrent Linux suite load. The isolated test module passed the full
841-test suite twice before the retry; production code was unchanged.

TypeScript's public `VERSION` export now reports 2.1.0, matching its package
metadata. Swift's public version also reports 2.1.0. Kotlin documentation
publishing required enabling GitHub Pages and permitting the workflow's `v*`
tags. The retried deployment passed and the public site returns HTTP 200.

Public packages are [Hex](https://hex.pm/packages/mojentic/2.1.0),
[PyPI](https://pypi.org/project/mojentic/2.1.0/),
[npm](https://www.npmjs.com/package/mojentic/v/2.1.0),
[crates.io](https://crates.io/crates/mojentic/2.1.0),
[SwiftPM](https://github.com/svetzal/mojentic-sw/releases/tag/v2.1.0), and
[Maven Central](https://repo.maven.apache.org/maven2/com/vetzal/mojentic/).

The Elixir consumer check ran on mojility-ops-01. The other five consumer
checks ran on Max-Headroom, all against public registry artifacts. Foundry's
release gates ran on mojility-ops-01; GitHub Actions also verified macOS/iOS
and Linux where applicable. Kotlin's Central propagation took
about 19 minutes after validation, before the public consumer check passed.
