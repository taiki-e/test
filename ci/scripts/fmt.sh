#!/bin/bash

# Format all Rust code with `rustfmt`.
#
# Usage:
#
#    $ . ci/scripts/fmt.sh
#
# To print a diff and exit 1 if code is not formatted, but without changing any
# files, use:
#
#    $ . ci/scripts/fmt.sh check
#

set -euo pipefail

# Rust
if [[ "${1:=fmt}" == "check" ]]; then
    # shellcheck disable=SC1091
    . ci/scripts/ci-tools.sh fmt ./**/Cargo.toml --check
    # cargo fmt --all -- --check
else
    # shellcheck disable=SC1091
    . ci/scripts/ci-tools.sh fmt ./**/Cargo.toml
    # cargo fmt --all
fi
