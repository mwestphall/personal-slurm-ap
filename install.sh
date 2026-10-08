#!/bin/bash
#
# install.sh - Copy the shared AP/EP files from their source of truth,
# ood/personal_ap/template/, to every other place that needs a copy: the
# standalone EP OOD app, and the top-level ap/ and ep/ dirs. Slurm and OOD
# don't follow symlinks into the shared filesystem, so these are real copies.
# Run this after editing any of the files below, and commit the result.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/ood/personal_ap/template"

# <destination dir relative to the repo>: <files copied from $SRC>
declare -A COPIES=(
    [ap]="11-ap-annex.conf install.sh start.sh"
    [ep]="annex-ep.sub update-annex-collector.sh"
    [ood/personal_ep/template]="annex-ep.sub update-annex-collector.sh"
)

for dest in "${!COPIES[@]}"; do
    mkdir -p "$REPO_DIR/$dest"
    for file in ${COPIES[$dest]}; do
        if [ ! -f "$SRC/$file" ]; then
            echo "error: source file not found: $SRC/$file" >&2
            exit 1
        fi
        cp -p "$SRC/$file" "$REPO_DIR/$dest/$file"
        echo "$dest/$file"
    done
done
