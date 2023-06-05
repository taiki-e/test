#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -euo pipefail
IFS=$'\n\t'
cd "$(dirname "$0")"/..

# shellcheck disable=SC2154
trap 's=$?; echo >&2 "$0: error on line "${LINENO}": ${BASH_COMMAND}"; exit ${s}' ERR

# Run code generators.
#
# USAGE:
#    ./tools/gen.sh [options]

set -x

./tools/target_spec.sh

cargo run --manifest-path tools/codegen/Cargo.toml -- "$@"

cargo run --manifest-path rust/lint/Cargo.toml
