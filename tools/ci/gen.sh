#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -euo pipefail
IFS=$'\n\t'
cd "$(dirname "$0")"/../..

# shellcheck disable=SC2154
trap 's=$?; echo >&2 "$0: error on line "${LINENO}": ${BASH_COMMAND}"; exit ${s}' ERR

bail() {
    echo >&2 "error: $*"
    exit 1
}

if [[ -z "${CI:-}" ]]; then
    bail "this script is intended to call from release workflow on CI"
fi

failed=0

git config user.name "Taiki Endo"
git config user.email "te316e89@gmail.com"

cargo run --manifest-path tools/codegen/Cargo.toml
git add -N tools
if ! git diff --exit-code -- tools; then
    git add tools
    git commit -m "Update target-spec"
    failed=1
fi

cargo run --manifest-path rust/lint/Cargo.toml
git add -N rust/lint
if ! git diff --exit-code -- rust/lint; then
    git add rust/lint
    git commit -m "Update lint list"
    failed=1
fi

if [[ "${failed}" == "1" ]]; then
    echo "success=false" >>"${GITHUB_OUTPUT}"
fi
