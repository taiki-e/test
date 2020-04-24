#!/bin/bash

# Format all shell scripts with `shfmt`.
#
# Usage:
#
#    $ bash ci/shfmt.sh
#
# To print a diff and exit 1 if code is not formatted, but without changing any
# files, use:
#
#    $ bash ci/shfmt.sh check
#

set -euo pipefail

if [[ "${1:-fmt}" == "check" ]]; then
    shfmt -i 4 -ci -d ./ci/*.sh
else
    shfmt -i 4 -ci -l -w ./ci/*.sh
fi
