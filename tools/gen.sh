#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
cd "$(dirname "$0")"/..

# Run code generators.
#
# USAGE:
#    ./tools/gen.sh [options]

set -x

cargo run --manifest-path tools/codegen/Cargo.toml -- "$@"

cargo run --manifest-path rust/lint/Cargo.toml
