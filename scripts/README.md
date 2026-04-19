# scripts/

Release tooling for the Mojentic monorepo.

## mojentic-release (`release.sh`)

Coordinates a synchronized tag+push across the four Mojentic port submodules in one command.

### One-time setup (optional)

```sh
ln -s "$PWD/scripts/release.sh" ~/bin/mojentic-release
```

After that you can run `mojentic-release <version>` from anywhere.

### Usage

```
./scripts/release.sh <version> [options]
```

| Argument / Option | Description |
|-------------------|-------------|
| `<version>` | Semver: `MAJOR.MINOR.PATCH` or `vMAJOR.MINOR.PATCH` |
| `--apply` | Execute tagging. Default: plan only (read-only). |
| `--update-parent` | After tagging, bump submodule pointers in mojentic-unify and create a local commit. Does **not** push the parent. |
| `--ports <list>` | Comma-separated subset of ports. Short (`ex,py`) or long (`mojentic-ex,mojentic-py`) names. |
| `--help` | Print usage and exit 0. |

### Typical workflow

```sh
# 1. Inspect — no mutations, safe to run anytime
./scripts/release.sh 1.3.0

# 2. Execute across all four ports
./scripts/release.sh 1.3.0 --apply

# 3. Execute and bump submodule pointers in mojentic-unify
./scripts/release.sh 1.3.0 --apply --update-parent

# 4. Review the staged parent commit, then push when ready
git log -1 --oneline
git push
```

### Idempotency

Safe to re-run after a partial failure. Ports that are already tagged at the correct commit are reported as `⊝ up-to-date` and skipped.

### Smoke tests

**Dirty-tree check** — confirm the script refuses to tag a port with uncommitted changes:

```sh
touch mojentic-ex/DIRTY
./scripts/release.sh 999.0.0 --apply --ports ex   # must fail loudly
rm mojentic-ex/DIRTY
```

**Plan mode** — confirm no mutations occur:

```sh
./scripts/release.sh 999.0.0
# Verify: git -C mojentic-py tag -l v999.0.0  → empty
```

**Idempotency** — run apply twice; second run reports already-up-to-date:

```sh
./scripts/release.sh 999.0.0 --apply --ports ex
./scripts/release.sh 999.0.0 --apply --ports ex   # ⊝ already up-to-date
# Clean up:
git -C mojentic-ex push --delete origin v999.0.0
git -C mojentic-ex tag -d v999.0.0
```
