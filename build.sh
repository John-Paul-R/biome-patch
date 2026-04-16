#!/usr/bin/env bash
set -euo pipefail

BIOME_REPO_URL="${BIOME_REPO_URL:-https://github.com/biomejs/biome.git}"
WORK_DIR="${WORK_DIR:-biome}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="${SCRIPT_DIR}/patches"
REF_FILE="${SCRIPT_DIR}/BIOME_REF"

if [[ ! -f "${REF_FILE}" ]]; then
    echo "error: ${REF_FILE} not found" >&2
    exit 1
fi

BIOME_REF="${BIOME_REF:-$(tr -d '[:space:]' < "${REF_FILE}")}"
if [[ -z "${BIOME_REF}" ]]; then
    echo "error: BIOME_REF is empty" >&2
    exit 1
fi

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

if [[ -e "${WORK_DIR}" ]]; then
    echo "error: working directory '${WORK_DIR}' already exists; remove it or set WORK_DIR" >&2
    exit 1
fi

echo "Fetching biome at ${BIOME_REF} from ${BIOME_REPO_URL} into ${WORK_DIR}..."
git init --quiet "${WORK_DIR}"
cd "${WORK_DIR}"
git remote add origin "${BIOME_REPO_URL}"
git fetch --depth=1 --quiet origin "${BIOME_REF}"
git checkout --quiet FETCH_HEAD

echo "Checked out biome at $(git rev-parse HEAD)"

for patch in "${patches[@]}"; do
    echo "Applying $(basename "${patch}")..."
    git apply --index --whitespace=nowarn "${patch}"
done

echo "Done. Patched biome tree is at: $(pwd)"
