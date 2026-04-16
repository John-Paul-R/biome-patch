#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="${SCRIPT_DIR}/patches"
BIOME_DIR="${SCRIPT_DIR}/biome"

# Ensure submodule is initialized
git -C "${SCRIPT_DIR}" submodule update --init biome

current_ref="$(git -C "${BIOME_DIR}" rev-parse HEAD)"
echo "Current pinned ref: ${current_ref}"

echo "Fetching latest main from upstream..."
git -C "${BIOME_DIR}" fetch --depth=1 origin main

latest_ref="$(git -C "${BIOME_DIR}" rev-parse FETCH_HEAD)"
echo "Latest ref:         ${latest_ref}"

if [[ "${current_ref}" == "${latest_ref}" ]]; then
    echo "Already up to date."
    exit 0
fi

# Test patches against the latest commit on a detached HEAD
echo "Testing patches against ${latest_ref}..."
git -C "${BIOME_DIR}" checkout --quiet "${latest_ref}"

shopt -s nullglob
patches=( "${PATCHES_DIR}"/*.patch )
shopt -u nullglob

failed=0
for patch in "${patches[@]}"; do
    name="$(basename "${patch}")"
    if git -C "${BIOME_DIR}" apply --check "${patch}" 2>/dev/null; then
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
    echo "Rolling back submodule to ${current_ref}." >&2
    git -C "${BIOME_DIR}" checkout --quiet "${current_ref}"
    exit 1
fi

echo
echo "Updated biome submodule: ${current_ref} -> ${latest_ref}"
echo "Stage and commit the submodule change to persist this update."
