#!/usr/bin/env bash
set -euo pipefail

BIOME_REPO_URL="${BIOME_REPO_URL:-https://github.com/biomejs/biome.git}"
BIOME_BRANCH="${BIOME_BRANCH:-main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="${SCRIPT_DIR}/patches"
REF_FILE="${SCRIPT_DIR}/BIOME_REF"

current_ref="$(tr -d '[:space:]' < "${REF_FILE}")"
echo "Current pinned ref: ${current_ref}"

echo "Resolving latest ${BIOME_BRANCH} on ${BIOME_REPO_URL}..."
latest_ref="$(git ls-remote "${BIOME_REPO_URL}" "refs/heads/${BIOME_BRANCH}" | awk '{print $1}')"
if [[ -z "${latest_ref}" ]]; then
    echo "error: could not resolve ${BIOME_BRANCH} on ${BIOME_REPO_URL}" >&2
    exit 1
fi
echo "Latest ref:         ${latest_ref}"

if [[ "${current_ref}" == "${latest_ref}" ]]; then
    echo "Already up to date."
    exit 0
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

echo "Testing patches against ${latest_ref} in ${tmp_dir}..."
git init --quiet "${tmp_dir}/biome"
(
    cd "${tmp_dir}/biome"
    git remote add origin "${BIOME_REPO_URL}"
    git fetch --depth=1 --quiet origin "${latest_ref}"
    git checkout --quiet FETCH_HEAD
)

shopt -s nullglob
patches=( "${PATCHES_DIR}"/*.patch )
shopt -u nullglob

failed=0
for patch in "${patches[@]}"; do
    name="$(basename "${patch}")"
    if (cd "${tmp_dir}/biome" && git apply --check "${patch}") 2>/dev/null; then
        echo "  ok:   ${name}"
    else
        echo "  FAIL: ${name}"
        failed=1
    fi
done

if [[ ${failed} -ne 0 ]]; then
    echo
    echo "One or more patches do not apply cleanly to ${latest_ref}." >&2
    echo "Rebase the failing patch(es), then re-run this script." >&2
    echo "BIOME_REF was NOT updated." >&2
    exit 1
fi

echo "${latest_ref}" > "${REF_FILE}"
echo
echo "Updated BIOME_REF: ${current_ref} -> ${latest_ref}"
