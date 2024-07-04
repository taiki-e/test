#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -CeEuo pipefail
IFS=$'\n\t'
cd "$(dirname "$0")"/../..

# shellcheck disable=SC2154
trap 's=$?; printf >&2 "%s\n" "$0: error on line "${LINENO}": ${BASH_COMMAND}"; exit ${s}' ERR

bail() {
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        printf "::error::%s\n" "$*"
    else
        printf >&2 "error: %s\n" "$*"
    fi
    exit 1
}

if [[ -z "${CI:-}" ]]; then
    bail "this script is intended to call from release workflow on CI"
fi

failed=''

git config user.name "Taiki Endo"
git config user.email "te316e89@gmail.com"

cargo run --manifest-path rust/lint/Cargo.toml
git add -N rust/lint
if ! git diff --exit-code -- rust/lint; then
    git add rust/lint
    git commit -m "Update lint list"
    failed=1
fi

if [[ -n "${failed}" ]]; then
    printf "success=false\n" >>"${GITHUB_OUTPUT}"
fi
