#!/bin/bash

# Format shell scripts and YAML files.
#
# Usage:
#    ./tools/fmt.sh
#
# Note: This script requires shfmt and prettier.

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "${0}")" && pwd)"/..

# shellcheck disable=SC2046
if [[ -z "${CI:-}" ]]; then
    (
        set -x
        shfmt -l -w $(git ls-files "*.sh")
        prettier -l -w $(git ls-files "*.yml")
    )
else
    (
        set -x
        shfmt -d $(git ls-files "*.sh")
        prettier -c $(git ls-files "*.yml")
    )
fi
