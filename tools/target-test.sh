#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC2154
trap 's=$?; echo >&2 "$0: error on line "${LINENO}": ${BASH_COMMAND}"; exit ${s}' ERR

bail() {
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::error::$*"
    else
        echo >&2 "error: $*"
    fi
    exit 1
}
warn() {
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::warning::$*"
    else
        echo >&2 "warning: $*"
    fi
}

script_dir="$(cd "$(dirname "$0")" && pwd)"
cd "${script_dir}"/..

host=$(rustc -Vv | grep 'host: ' | sed 's/host: //')
target="${1:-"${host}"}"
cargo="cargo"
if [[ "${host}" != "${target}" ]]; then
    case "${target}" in
        # https://github.com/cross-rs/cross#supported-targets
        *-windows-msvc* | *-windows-gnu* | *-darwin* | *-fuchsia* | *-redox*) ;;
        *)
            cargo="cross"
            cargo install cross
            # "${script_dir}"/../ci/install-cross.sh
            ;;
    esac
fi

set -x

"${cargo}" build --lib --target "${target}" --manifest-path rust/lib-no-std/Cargo.toml

if "${cargo}" build --lib --target "${target}" --manifest-path rust/lib/Cargo.toml; then
    if [[ -n "${BUILD_STD_FAIL:-}" ]]; then
        bail "${target}: marked as no-std, but build with std was successful"
    fi
else
    if [[ -n "${BUILD_STD_FAIL:-}" ]]; then
        warn "${target}: failed to build library with std as expected"
        exit 0
    else
        exit 1
    fi
fi

if ${cargo} build --bin rust-test-bin --target "${target}"; then
    if [[ -n "${BUILD_BIN_FAIL:-}" ]]; then
        bail "${target}: marked as bin-fail, but build was successful"
    fi
else
    if [[ -n "${BUILD_BIN_FAIL:-}" ]]; then
        warn "${target}: failed to build binary as expected"
        exit 0
    else
        exit 1
    fi
fi
