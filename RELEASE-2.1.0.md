# Mojentic 2.1.0 release plan

Prepared September 30, 2026. This plan does not authorize publishing.

## Scope

Release all six ports as 2.1.0. Python, TypeScript, Elixir, Rust, and Kotlin skip
2.0.0. Kotlin joins with its first Maven Central release. Swift is already at
2.0.0. No versions or tags changed during this completion pass.

Include the oMLX gateway, September streaming and trace alignment, message
adapter corrections, streamed tool-call corrections, and embedding bug fixes.
The contracts are `OMLX-2026-09.md` and `ALIGNMENT-2026-09.md`.

## Decisions and prerequisites

- Settle disabled reasoning across ports, or explicitly defer it to 2.2.0.
  Rust alone has the disabled value today.

- Settle whether ordinary `generate` rejects non-stop finishes in every port,
  or explicitly defer that behavior. The alignment contract excludes it.

- Confirm Kotlin can access its Sonatype and signing secrets. Its repository
  secret list was empty on September 30. Organization access needs confirmation.
  The workflow needs `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD`,
  `SIGNING_KEY`, `SIGNING_KEY_ID`, and `SIGNING_KEY_PASSWORD`.

- Enable Foundry release for Swift and Kotlin after those prerequisites pass.
  Their registry records currently disable release for the earlier decisions.

- Confirm Foundry will publish the exact version 2.1.0 in each port.
  A generic minor bump does not produce 2.1.0 from the older ports' versions.

The Operations `Planning/TODO.md` holds the decisions and credential action.
Swift and Kotlin's automatic long-text embedding support is a separate parity
decision. Neither port averages embeddings, so neither had the weighting bug.

## Accepted limits

The oMLX embedding success path has fake-transport coverage but no live test.

The live server had no embedding model during the gateway work. Swift's Apple events
transport does not expose error bodies. Some streams do not expose Warning
headers.

The oMLX contract accepts those transport limits.

## Release procedure

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
