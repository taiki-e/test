#!/bin/bash

# Format all Rust code and shell script with `rustfmt` and `shfmt`.
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
if [[ "$@" == "check" ]]; then
    cargo fmt --all -- --check
else
    cargo fmt --all
fi

# Shell Script
if [[ "$@" == "check" ]]; then
    shfmt -i 4 -ci -d ci/scripts/*.sh
else
    shfmt -i 4 -ci -l -w ci/scripts/*.sh
fi
