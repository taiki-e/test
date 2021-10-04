#!/bin/bash

# Run code generators.
#
# Usage:
#    ./tools/gen.sh [options]

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "$0")" && pwd)"/..

set -x

cargo run --manifest-path tools/codegen/Cargo.toml -- "$@"

cargo run --manifest-path rust/lint/Cargo.toml
