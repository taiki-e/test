#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -CeEuo pipefail
IFS=$'\n\t'
trap -- 's=$?; printf >&2 "%s\n" "${0##*/}:${LINENO}: \`${BASH_COMMAND}\` exit with ${s}"; exit ${s}' ERR
trap -- 'printf >&2 "%s\n" "${0##*/}: trapped SIGINT"; exit 1' SIGINT
cd -- "$(dirname -- "$0")"/../..

bail() {
    printf >&2 'error: %s\n' "$*"
    exit 1
}

if [[ -z "${CI:-}" ]]; then
    bail "this script is intended to call from release workflow on CI"
fi

git config user.name "Taiki Endo"
git config user.email "te316e89@gmail.com"

has_update=''
cargo run --manifest-path rust/lint/Cargo.toml
git add -N rust/lint
if ! git diff --exit-code -- rust/lint; then
    git add rust/lint
    git commit -m "Update lint list"
    has_update=1
fi

if [[ -n "${has_update}" ]] && [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf 'success=false\n' >>"${GITHUB_OUTPUT}"
fi
