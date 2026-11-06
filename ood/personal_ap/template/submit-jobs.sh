#!/bin/bash
#
# submit-jobs.sh - Wait for the personal AP to accept queries, then submit each
# given submit file from its own directory (condor_submit, or condor_submit_dag
# for *.dag files). Exits 0 only if every file was submitted successfully.

set -euo pipefail

AP_LINK="$HOME/personal-htcondor/current-ap"
WATCH_PID=""
TIMEOUT=240

usage() {
    cat <<USAGE
Usage: $(basename "${BASH_SOURCE[0]}") [--ap-link <path>] [--watch-pid <pid>] [--timeout <seconds>] <submit-file>...

Wait for the AP at <path> (default: $AP_LINK) to accept queries, then submit
each file. If --watch-pid is given, stop waiting when that process exits.
Exit status: 0 all submitted; 1 some submissions failed; 2 the AP never became ready.
USAGE
}

FILES=()
while [ $# -gt 0 ]; do
    case "$1" in
        --help) usage; exit 0 ;;
        --ap-link|--watch-pid|--timeout)
            if [ $# -lt 2 ]; then
                echo "error: $1 requires an argument" >&2
                usage >&2
                exit 1
            fi
            case "$1" in
                --ap-link) AP_LINK="$2" ;;
                --watch-pid) WATCH_PID="$2" ;;
                --timeout) TIMEOUT="$2" ;;
            esac
            shift 2
            ;;
        -*) echo "error: unknown argument: $1" >&2; usage >&2; exit 1 ;;
        *) FILES+=("$1"); shift ;;
    esac
done

if [ "${#FILES[@]}" -eq 0 ]; then
    echo "error: no submit files given" >&2
    usage >&2
    exit 1
fi

# The AP only accepts IDTOKENS (see start.sh, which mints the token).
export _condor_SEC_CLIENT_AUTHENTICATION_METHODS=IDTOKENS

# Re-resolve the AP link on every attempt: a fresh install repoints it.
ap_ready() (
    # shellcheck disable=SC1091
    . "$(readlink -f "$AP_LINK")/condor.sh" && condor_q >/dev/null 2>&1
)

echo "==> Waiting for the AP to accept queries before submitting jobs"
waited=0
until ap_ready 2>/dev/null; do
    if [ -n "$WATCH_PID" ] && ! kill -0 "$WATCH_PID" 2>/dev/null; then
        echo "error: the AP exited before it was ready; not submitting jobs" >&2
        exit 2
    fi
    if [ "$waited" -ge "$TIMEOUT" ]; then
        echo "error: AP not accepting queries after ${TIMEOUT}s; not submitting jobs" >&2
        exit 2
    fi
    sleep 2
    waited=$((waited + 2))
done

# shellcheck disable=SC1091
. "$(readlink -f "$AP_LINK")/condor.sh"

failed=0
for file in "${FILES[@]}"; do
    path="$(readlink -f "$file" 2>/dev/null || true)"
    if [ -z "$path" ] || [ ! -f "$path" ]; then
        echo "error: submit file not found: $file" >&2
        failed=$((failed + 1))
        continue
    fi
    if [[ "$path" == *.dag ]]; then
        cmd=(condor_submit_dag)
    else
        cmd=(condor_submit)
    fi
    echo "==> ${cmd[0]} $path"
    if ! (cd "$(dirname "$path")" && "${cmd[@]}" "$(basename "$path")"); then
        echo "error: ${cmd[0]} failed for $path" >&2
        failed=$((failed + 1))
    fi
done

if [ "$failed" -gt 0 ]; then
    echo "error: $failed submit file(s) failed" >&2
    exit 1
fi
echo "==> Submitted ${#FILES[@]} submit file(s)"
