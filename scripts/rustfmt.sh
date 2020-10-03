#!/bin/bash

# Format all rust code with `rustfmt`.
#
# Usage:
#    bash scripts/rustfmt.sh
#
# To print a diff and exit 1 if code is not formatted, but without changing any
# files, use:
#    bash scripts/rustfmt.sh check
#

set -euo pipefail

if [[ "${1:-fmt}" == "check" ]]; then
    rustfmt --check --edition 2018 "$(find . -name '*.rs' -print)"
else
    rustfmt --edition 2018 "$(find . -name '*.rs' -print)"
fi
