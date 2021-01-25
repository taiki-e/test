#!/bin/bash

# Format all rust code with `rustfmt`.
#
# Usage:
#    ./scripts/rustfmt.sh
#

set -euo pipefail
IFS=$'\n\t'

if [[ -z "${CI:-}" ]]; then
  # shellcheck disable=SC2046
  rustfmt --edition 2018 $(git ls-files '*rs')
else
  # shellcheck disable=SC2046
  rustfmt --check --edition 2018 $(git ls-files '*rs')
fi
