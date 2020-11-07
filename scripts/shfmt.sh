#!/bin/bash

# Format all shell scripts with `shfmt`.
#
# Usage:
#    bash scripts/shfmt.sh
#

set -euo pipefail
IFS=$'\n\t'

if [[ -z "${CI:-}" ]]; then
  shfmt -l -w ./**/*.sh
else
  shfmt -d ./**/*.sh
fi
