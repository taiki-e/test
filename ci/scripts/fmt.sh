#!/bin/bash

# Format all Rust code with `rustfmt`.
#
# Usage:
#
#    $ bash ci/scripts/fmt.sh
#
# To print a diff and exit 1 if code is not formatted, but without changing any
# files, use:
#
#    $ bash ci/scripts/fmt.sh check
#

set -euo pipefail

# Rust
if [[ "${1:-fmt}" == "check" ]]; then
    cargo fmt --all -- --check
else
    cargo fmt --all
fi
