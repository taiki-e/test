#!/bin/bash

# Format all shell scripts with `shfmt`.
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

# Shell Script
if [[ "${1:-fmt}" == "check" ]]; then
    shfmt -i 4 -ci -d ./ci/scripts/*.sh
else
    shfmt -i 4 -ci -l -w ./ci/scripts/*.sh
fi
