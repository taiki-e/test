#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Run code generators.
#
# USAGE:
#    ./tools/gen.sh [options]

cd "$(cd "$(dirname "$0")" && pwd)"/..

set -x

cargo run --manifest-path tools/codegen/Cargo.toml -- "$@"

cargo run --manifest-path rust/lint/Cargo.toml
