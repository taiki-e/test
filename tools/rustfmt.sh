#!/bin/bash

# Format all rust code with rustfmt.
#
# Usage:
#    ./tools/rustfmt.sh
#
# Note: This script requires rustfmt.

set -euo pipefail
IFS=$'\n\t'

if [[ -z "${CI:-}" ]]; then
    (
        set -x
        # shellcheck disable=SC2046
        rustfmt --edition 2018 $(git ls-files "*rs")
    )
else
    (
        set -x
        # shellcheck disable=SC2046
        rustfmt --check --edition 2018 $(git ls-files "*rs")
    )
fi
