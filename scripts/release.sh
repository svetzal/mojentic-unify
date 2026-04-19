#!/usr/bin/env bash
set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────────────

ALL_PORTS=(mojentic-ex mojentic-py mojentic-ru mojentic-ts)
SHORT_NAMES=(ex py ru ts)

# ── Color helpers (only when writing to a TTY) ─────────────────────────────────

is_tty() { [ -t 1 ]; }

red()    { if is_tty; then printf '\033[0;31m%s\033[0m' "$*"; else printf '%s' "$*"; fi; }
green()  { if is_tty; then printf '\033[0;32m%s\033[0m' "$*"; else printf '%s' "$*"; fi; }
yellow() { if is_tty; then printf '\033[0;33m%s\033[0m' "$*"; else printf '%s' "$*"; fi; }
bold()   { if is_tty; then printf '\033[1m%s\033[0m' "$*"; else printf '%s' "$*"; fi; }

die() {
    printf '%s\n' "$(red "ERROR: $*")" >&2
    exit 1
}

log() { printf '%s\n' "$*"; }

# ── Repo-root discovery ────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && git rev-parse --show-toplevel)"

# ── Usage ─────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
$(bold "mojentic-release") — synchronized tag+push across all Mojentic port submodules

$(bold USAGE)
    $(bold "./scripts/release.sh") <version> [options]

$(bold ARGUMENTS)
    <version>          Semver version: MAJOR.MINOR.PATCH or vMAJOR.MINOR.PATCH

$(bold OPTIONS)
    --apply            Execute tagging (default: plan only — read-only)
    --update-parent    After tagging, bump submodule pointers in mojentic-unify
                       and create a local commit (does NOT push the parent)
    --ports <list>     Comma-separated subset of ports to process
                       Short names:  ex, py, ru, ts
                       Long names:   mojentic-ex, mojentic-py, mojentic-ru, mojentic-ts
    --help             Print this help and exit 0

$(bold PORTS)
    mojentic-ex   Elixir port
    mojentic-py   Python reference implementation
    mojentic-ru   Rust port
    mojentic-ts   TypeScript port

$(bold EXAMPLES)
    # Show what would happen (no mutations)
    ./scripts/release.sh 1.3.0

    # Show plan for two ports only
    ./scripts/release.sh 1.3.0 --ports ex,py

    # Tag all four ports
    ./scripts/release.sh 1.3.0 --apply

    # Tag all ports and bump submodule pointers in mojentic-unify (no parent push)
    ./scripts/release.sh 1.3.0 --apply --update-parent

$(bold SMOKE TESTS)
    # Dirty-tree check — leave an uncommitted change in a port, then:
    touch mojentic-ex/DIRTY
    ./scripts/release.sh 999.0.0 --apply --ports ex   # should fail loudly
    rm mojentic-ex/DIRTY

    # Idempotency — run apply twice; second run reports all already-up-to-date
    ./scripts/release.sh 999.0.0 --apply --ports ex
    ./scripts/release.sh 999.0.0 --apply --ports ex
    # Clean up:
    git -C mojentic-ex push --delete origin v999.0.0
    git -C mojentic-ex tag -d v999.0.0
EOF
}

# ── Validation ─────────────────────────────────────────────────────────────────

validate_version() {
    local raw="$1"
    # Strip optional leading 'v'
    local ver="${raw#v}"
    if [[ ! "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        die "invalid semver: $raw (expected MAJOR.MINOR.PATCH)"
    fi
    printf '%s' "$ver"
}

# ── Port selection ─────────────────────────────────────────────────────────────

normalize_ports_arg() {
    local raw="$1"
    local -a result=()
    IFS=',' read -ra items <<< "$raw"
    for item in "${items[@]}"; do
        # Strip optional 'mojentic-' prefix
        local short="${item#mojentic-}"
        local matched=false
        local i
        for i in "${!SHORT_NAMES[@]}"; do
            if [[ "${SHORT_NAMES[$i]}" == "$short" ]]; then
                result+=("${ALL_PORTS[$i]}")
                matched=true
                break
            fi
        done
        if [[ "$matched" == false ]]; then
            die "unknown port: $item (expected one of ex, py, ru, ts)"
        fi
    done
    printf '%s\n' "${result[@]}"
}

# ── Submodule readiness check ─────────────────────────────────────────────────

assert_submodule_initialized() {
    local port="$1"
    local path="$REPO_ROOT/$port"
    if [[ ! -e "$path/.git" ]]; then
        die "$port submodule is not initialized — run: git submodule update --init $port"
    fi
}

# ── Tag state probe ────────────────────────────────────────────────────────────

# Returns:
#   missing          tag not found locally or remotely
#   local-only:<hash>   tag exists locally only
#   remote-only:<hash>  tag exists remotely only (local hash is remote's)
#   both:<hash>      tag exists locally and remotely, same commit
#   conflict:<local>:<remote>   tag exists but points to different commits
tag_state() {
    local port="$1"
    local tag="$2"
    local path="$REPO_ROOT/$port"

    local local_hash=""
    local remote_hash=""

    if git -C "$path" rev-parse --verify "${tag}^{commit}" &>/dev/null; then
        local_hash="$(git -C "$path" rev-parse "${tag}^{commit}")"
    fi

    local remote_line
    remote_line="$(git -C "$path" ls-remote --tags origin "refs/tags/${tag}" 2>/dev/null || true)"
    if [[ -n "$remote_line" ]]; then
        # ls-remote returns the dereferenced tag for annotated tags as <hash>^{}
        # For lightweight tags it's just the commit hash
        local dereffed
        dereffed="$(git -C "$path" ls-remote --tags origin "refs/tags/${tag}^{}" 2>/dev/null | awk '{print $1}' || true)"
        if [[ -n "$dereffed" ]]; then
            remote_hash="$dereffed"
        else
            remote_hash="$(printf '%s' "$remote_line" | awk '{print $1}')"
        fi
    fi

    if [[ -z "$local_hash" && -z "$remote_hash" ]]; then
        printf 'missing'
    elif [[ -n "$local_hash" && -z "$remote_hash" ]]; then
        printf 'local-only:%s' "$local_hash"
    elif [[ -z "$local_hash" && -n "$remote_hash" ]]; then
        printf 'remote-only:%s' "$remote_hash"
    elif [[ "$local_hash" == "$remote_hash" ]]; then
        printf 'both:%s' "$local_hash"
    else
        printf 'conflict:%s:%s' "$local_hash" "$remote_hash"
    fi
}

# ── Plan phase ────────────────────────────────────────────────────────────────

plan_port() {
    local port="$1"
    local tag="$2"
    local path="$REPO_ROOT/$port"

    assert_submodule_initialized "$port"

    log ""
    log "$(bold "── $port ──")"

    git -C "$path" fetch origin --quiet 2>/dev/null || log "  $(yellow "⚠  fetch failed — working with cached state")"

    local branch
    branch="$(git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'detached-HEAD')"
    local head_hash
    head_hash="$(git -C "$path" rev-parse HEAD)"
    local short_head="${head_hash:0:8}"

    local origin_main_hash=""
    origin_main_hash="$(git -C "$path" rev-parse origin/main 2>/dev/null || true)"
    local short_origin="${origin_main_hash:0:8}"

    local dirty=""
    if ! git -C "$path" diff --quiet 2>/dev/null || ! git -C "$path" diff --cached --quiet 2>/dev/null; then
        dirty="$(yellow " ⚠ DIRTY")"
    fi

    log "  branch:       $branch$dirty"
    log "  HEAD:         $short_head"
    log "  origin/main:  ${short_origin:-unknown}"

    local state
    state="$(tag_state "$port" "$tag")"

    local tag_line
    case "${state%%:*}" in
        missing)       tag_line="$(yellow "missing — would be created")" ;;
        local-only)    tag_line="$(yellow "local only @ ${state#local-only:} — would push")" ;;
        remote-only)   local h="${state#remote-only:}"; tag_line="$(yellow "remote only @ ${h:0:8}")" ;;
        both)          local h="${state#both:}"; tag_line="$(green "exists @ ${h:0:8}")" ;;
        conflict)      local parts="${state#conflict:}"
                       local lh="${parts%%:*}"
                       local rh="${parts#*:}"
                       tag_line="$(red "CONFLICT — local @ ${lh:0:8}, remote @ ${rh:0:8}")" ;;
    esac
    log "  $tag:    $tag_line"
}

# ── Apply phase ───────────────────────────────────────────────────────────────

# Echoes one of: "tagged:<hash>", "up-to-date:<hash>", "failed:<reason>"
apply_port() {
    local port="$1"
    local tag="$2"
    local path="$REPO_ROOT/$port"

    assert_submodule_initialized "$port"

    # Fetch
    if ! git -C "$path" fetch origin --quiet 2>/dev/null; then
        printf 'failed:fetch from origin failed'
        return
    fi

    # Clean working tree check
    if ! git -C "$path" diff --quiet 2>/dev/null || ! git -C "$path" diff --cached --quiet 2>/dev/null; then
        printf 'failed:working tree dirty — refusing to release'
        return
    fi

    # Checkout main
    if ! git -C "$path" checkout main --quiet 2>/dev/null; then
        # Try creating local tracking branch from origin/main
        if ! git -C "$path" checkout -B main origin/main --quiet 2>/dev/null; then
            printf 'failed:could not checkout main'
            return
        fi
    fi

    # Pull --ff-only
    if ! git -C "$path" pull --ff-only origin main --quiet 2>/dev/null; then
        printf 'failed:non-fast-forward pull on main'
        return
    fi

    local head_hash
    head_hash="$(git -C "$path" rev-parse HEAD)"

    # Probe tag state
    local state
    state="$(tag_state "$port" "$tag")"

    case "${state%%:*}" in
        missing)
            # Create tag and push
            git -C "$path" tag "$tag" HEAD
            if ! git -C "$path" push origin "$tag" --quiet 2>/dev/null; then
                printf 'failed:push of %s failed' "$tag"
                return
            fi
            printf 'tagged:%s' "$head_hash"
            ;;
        local-only)
            local existing="${state#local-only:}"
            if [[ "$existing" != "$head_hash" ]]; then
                printf 'failed:%s points to %s locally but HEAD is %s' "$tag" "${existing:0:8}" "${head_hash:0:8}"
                return
            fi
            # Tag exists locally at correct commit; push it
            if ! git -C "$path" push origin "$tag" --quiet 2>/dev/null; then
                printf 'failed:push of %s failed' "$tag"
                return
            fi
            printf 'tagged:%s' "$head_hash"
            ;;
        remote-only)
            local existing="${state#remote-only:}"
            if [[ "$existing" != "$head_hash" ]]; then
                printf 'failed:%s already exists on origin at %s but HEAD is %s' "$tag" "${existing:0:8}" "${head_hash:0:8}"
                return
            fi
            # Create local ref to match remote (idempotent)
            git -C "$path" tag "$tag" HEAD 2>/dev/null || true
            printf 'up-to-date:%s' "$head_hash"
            ;;
        both)
            local existing="${state#both:}"
            if [[ "$existing" != "$head_hash" ]]; then
                printf 'failed:%s already points to %s on origin but HEAD is %s' "$tag" "${existing:0:8}" "${head_hash:0:8}"
                return
            fi
            printf 'up-to-date:%s' "$head_hash"
            ;;
        conflict)
            local parts="${state#conflict:}"
            local lh="${parts%%:*}"
            local rh="${parts#*:}"
            printf 'failed:%s local@%s conflicts with remote@%s' "$tag" "${lh:0:8}" "${rh:0:8}"
            ;;
    esac
}

# ── Parent update ─────────────────────────────────────────────────────────────

update_parent() {
    local version="$1"
    local -a ports=("${@:2}")

    # Check parent working tree is clean before touching it
    if ! git -C "$REPO_ROOT" diff --quiet 2>/dev/null || ! git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
        log "$(yellow "⚠  parent working tree is dirty — skipping --update-parent")"
        return
    fi

    local -a port_dirs=()
    for port in "${ports[@]}"; do
        port_dirs+=("$REPO_ROOT/$port")
    done

    git -C "$REPO_ROOT" add "${ports[@]}"

    if git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
        log "$(green "⊝  parent already in sync — no submodule pointers changed")"
    else
        git -C "$REPO_ROOT" commit -m "Bump submodules for v${version} release"
        log "$(green "✓  parent commit created (not pushed)")"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    local version=""
    local apply=false
    local update_parent=false
    local ports_arg=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                usage
                exit 0
                ;;
            --apply)
                apply=true
                shift
                ;;
            --update-parent)
                update_parent=true
                shift
                ;;
            --ports)
                [[ $# -ge 2 ]] || die "--ports requires an argument"
                ports_arg="$2"
                shift 2
                ;;
            --ports=*)
                ports_arg="${1#--ports=}"
                shift
                ;;
            -*)
                die "unknown option: $1"
                ;;
            *)
                if [[ -n "$version" ]]; then
                    die "unexpected argument: $1"
                fi
                version="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$version" ]]; then
        printf '%s\n' "$(red "ERROR: version required")" >&2
        printf '\n' >&2
        usage >&2
        exit 1
    fi

    version="$(validate_version "$version")"
    local tag="v${version}"

    # Resolve port list
    local -a ports=()
    if [[ -n "$ports_arg" ]]; then
        local normalized_ports
        normalized_ports="$(normalize_ports_arg "$ports_arg")"
        while IFS= read -r p; do
            [[ -n "$p" ]] && ports+=("$p")
        done <<< "$normalized_ports"
    else
        ports=("${ALL_PORTS[@]}")
    fi

    # ── Plan phase ────────────────────────────────────────────────────────────
    if [[ "$apply" == false ]]; then
        log "$(bold "Mojentic release plan for $tag")"
        log "$(bold "(run with --apply to execute)")"

        local any_blocker=false
        local blockers=()

        for port in "${ports[@]+"${ports[@]}"}"; do
            plan_port "$port" "$tag"
        done

        log ""

        # Summarise any dirty ports as blockers
        for port in "${ports[@]+"${ports[@]}"}"; do
            local path="$REPO_ROOT/$port"
            if [[ -e "$path/.git" ]] && \
               { ! git -C "$path" diff --quiet 2>/dev/null || ! git -C "$path" diff --cached --quiet 2>/dev/null; }; then
                blockers+=("$port (dirty working tree)")
                any_blocker=true
            fi
        done

        if [[ "$any_blocker" == true ]]; then
            log "$(yellow "⚠  Blockers detected (fix before running --apply):")"
            for b in "${blockers[@]+"${blockers[@]}"}"; do
                log "   - $b"
            done
        else
            log "$(green "✓  No blockers detected. Safe to run with --apply.")"
        fi
        exit 0
    fi

    # ── Apply phase ───────────────────────────────────────────────────────────
    log "$(bold "Mojentic release $tag — applying")"
    log ""

    local -a status_port=()
    local -a status_result=()
    local -a status_hash=()
    local failed=false

    for port in "${ports[@]+"${ports[@]}"}"; do
        if [[ "$failed" == true ]]; then
            status_port+=("$port")
            status_result+=("skipped")
            status_hash+=("")
            continue
        fi

        printf '  %s … ' "$(bold "$port")"
        local outcome
        outcome="$(apply_port "$port" "$tag")"

        local kind="${outcome%%:*}"
        local detail="${outcome#*:}"

        status_port+=("$port")
        status_hash+=("${detail:0:8}")

        case "$kind" in
            tagged)
                status_result+=("tagged")
                printf '%s\n' "$(green "✓ tagged $tag @ ${detail:0:8}")"
                ;;
            up-to-date)
                status_result+=("up-to-date")
                printf '%s\n' "$(green "⊝ already up-to-date @ ${detail:0:8}")"
                ;;
            failed)
                status_result+=("failed")
                failed=true
                printf '%s\n' "$(red "✗ failed: $detail")"
                printf '%s\n' "$(red "ERROR: $port: $detail")" >&2
                ;;
        esac
    done

    # Summary
    log ""
    log "$(bold "── Summary ──────────────────────────────────────────────────────────────────")"
    local i
    for i in "${!status_port[@]}"; do
        local p="${status_port[$i]}"
        local r="${status_result[$i]}"
        local h="${status_hash[$i]}"
        case "$r" in
            tagged)     log "  $(green "✓") $p — tagged $tag @ $h" ;;
            up-to-date) log "  $(green "⊝") $p — already up-to-date @ $h" ;;
            failed)     log "  $(red "✗") $p — failed" ;;
            skipped)    log "  — $p — skipped (not reached due to earlier failure)" ;;
        esac
    done
    log ""

    if [[ "$failed" == true ]]; then
        die "release aborted due to failure — see summary above for partial state"
    fi

    # ── Optional parent update ─────────────────────────────────────────────────
    if [[ "$update_parent" == true ]]; then
        log "$(bold "Updating submodule pointers in parent …")"
        update_parent "$version" "${ports[@]+"${ports[@]}"}"
    fi

    log "$(green "Release $tag complete.")"
}

main "$@"
