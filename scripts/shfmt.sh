#!/bin/bash

# Format all shell scripts with shfmt.
#
# Usage:
#    ./scripts/shfmt.sh
#
# Note: This script requires shfmt.

set -euo pipefail
IFS=$'\n\t'

if [[ -z "${CI:-}" ]]; then
    (
        set -x
        shfmt -l -w ./**/*.sh
    )
else
    (
        set -x
        shfmt -d ./**/*.sh
    )
fi
