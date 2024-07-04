#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -CeEuo pipefail
IFS=$'\n\t'
cd "$(dirname "$0")"/..

# shellcheck disable=SC2154
trap 's=$?; printf >&2 "%s\n" "$0: error on line "${LINENO}": ${BASH_COMMAND}"; exit ${s}' ERR

# Run code generators.
#
# USAGE:
#    ./tools/gen.sh [options]

set -x

cargo run --manifest-path rust/lint/Cargo.toml
