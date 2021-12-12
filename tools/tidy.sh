#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Format all code.
#
# USAGE:
#    ./tools/tidy.sh
#
# NOTE: This script requires rustfmt, shfmt, and prettier.

cd "$(cd "$(dirname "$0")" && pwd)"/..

# shellcheck disable=SC2046
if [[ -z "${CI:-}" ]]; then
    # `cargo fmt` cannot recognize modules defined inside macros, so run
    # rustfmt directly.
    # Refs: https://github.com/rust-lang/rustfmt/issues/4078
    rustfmt $(git ls-files '*.rs')
    shfmt -l -w $(git ls-files '*.sh')
    if prettier --version &>/dev/null; then
        prettier -l -w $(git ls-files '*.yml')
    fi
else
    # `cargo fmt` cannot recognize modules defined inside macros, so run
    # rustfmt directly.
    # Refs: https://github.com/rust-lang/rustfmt/issues/4078
    rustfmt --check $(git ls-files '*.rs')
    shfmt -d $(git ls-files '*.sh')
    prettier -c $(git ls-files '*.yml')
fi
