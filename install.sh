#!/bin/bash
#
# install.sh - Copy the shared AP/EP files from their source of truth,
# ood/personal_condor_system/template/, to every other place that needs a copy:
# the AP-only OOD app, and the top-level ap/ and ep/ dirs. Slurm and OOD
# don't follow symlinks into the shared filesystem, so these are real copies.
# Run this after editing any of the files below, and commit the result.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/ood/personal_condor_system/template"

# <destination dir relative to the repo>: <files copied from $SRC>
declare -A COPIES=(
    [ap]="11-ap-annex.conf install.sh start.sh"
    [ep]="annex-ep.sub update-annex-collector.sh"
    [ood/personal_ap/template]="entrypoint.sh install.sh start.sh update-view.sh 11-ap-annex.conf"
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
