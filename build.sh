#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="${SCRIPT_DIR}/patches"

if [[ ! -d "${PATCHES_DIR}" ]]; then
    echo "error: patches directory not found at ${PATCHES_DIR}" >&2
    exit 1
fi

shopt -s nullglob
patches=( "${PATCHES_DIR}"/*.patch )
shopt -u nullglob

if [[ ${#patches[@]} -eq 0 ]]; then
    echo "error: no .patch files found in ${PATCHES_DIR}" >&2
    exit 1
fi

echo "Initializing biome submodule..."
git -C "${SCRIPT_DIR}" submodule update --init biome

# Reset any previously applied patches
git -C "${SCRIPT_DIR}/biome" checkout -- .

echo "Checked out biome at $(git -C "${SCRIPT_DIR}/biome" rev-parse HEAD)"

for patch in "${patches[@]}"; do
    echo "Applying $(basename "${patch}")..."
    git -C "${SCRIPT_DIR}/biome" apply --index --whitespace=nowarn "${patch}"
done

echo "Done. Patched biome tree is at: ${SCRIPT_DIR}/biome"
