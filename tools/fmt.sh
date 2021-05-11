#!/bin/bash

# Format all code.
#
# Usage:
#    ./tools/fmt.sh
#
# Note: This script requires rustfmt, shfmt, and prettier.

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "${0}")" && pwd)"/..

# shellcheck disable=SC2046
if [[ -z "${CI:-}" ]]; then
    # `cargo fmt` cannot recognize modules defined inside macros, so run
    # rustfmt directly.
    # Refs: https://github.com/rust-lang/rustfmt/issues/4078
    rustfmt $(git ls-files '*.rs')
    shfmt -l -w $(git ls-files '*.sh')
    prettier -l -w $(git ls-files '*.yml')
else
    # `cargo fmt` cannot recognize modules defined inside macros, so run
    # rustfmt directly.
    # Refs: https://github.com/rust-lang/rustfmt/issues/4078
    rustfmt --check $(git ls-files '*.rs')
    shfmt -d $(git ls-files '*.sh')
    prettier -c $(git ls-files '*.yml')
fi
