#!/bin/bash
#
# install.sh - Copy the shared AP/EP files from their source of truth,
# ood/personal_condor_system/template/, to every other place that needs a copy:
# the AP-only OOD app. Slurm and OOD don't follow symlinks into the shared
# filesystem, so this is a real copy.
# Run this after editing any of the files below, and commit the result.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/ood/personal_condor_system/template"

# <destination dir relative to the repo>: <files copied from $SRC>
declare -A COPIES=(
    [ood/personal_ap/template]="entrypoint.sh parse_args.sh install.sh start.sh update-view.sh wait-for-lock.py 11-ap-annex.conf"
)

for dest in "${!COPIES[@]}"; do
    mkdir -p "$REPO_DIR/$dest"
    for file in ${COPIES[$dest]}; do
        if [ ! -f "$SRC/$file" ]; then
            echo "error: source file not found: $SRC/$file" >&2
            exit 1
        fi
        mkdir -p "$(dirname "$REPO_DIR/$dest/$file")"
        cp -p "$SRC/$file" "$REPO_DIR/$dest/$file"
        echo "$dest/$file"
    done
done
