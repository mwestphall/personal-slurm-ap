#!/bin/bash
#
# sample-job.sh - Copy the sample HTCondor job (sample-job/, next to this
# script) into ~/personal-htcondor/sample-submit, leaving any files the user
# already has there alone.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/personal-htcondor/sample-submit"

usage() {
    cat <<USAGE
Usage: $(basename "${BASH_SOURCE[0]}") [--dest <path>]

Copy the sample job into <path> (default: $DEST_DIR). Existing files are
not overwritten.
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --help)
            usage
            exit 0
            ;;
        --dest)
            if [ $# -lt 2 ]; then
                echo "error: --dest requires a path argument" >&2
                usage >&2
                exit 1
            fi
            DEST_DIR="$2"
            shift 2
            ;;
        *)
            echo "error: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

mkdir -p "$DEST_DIR"

for file in "$SCRIPT_DIR"/sample-job/*; do
    [ -e "$DEST_DIR/$(basename "$file")" ] || cp -p "$file" "$DEST_DIR/"
done

echo "==> Sample job copied to $DEST_DIR (see README.md there)"
