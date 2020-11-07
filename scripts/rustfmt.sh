#!/bin/bash

# Format all rust code with `rustfmt`.
#
# Usage:
#    bash scripts/rustfmt.sh
#

set -euo pipefail
IFS=$'\n\t'

if [[ -z "${CI:-}" ]]; then
  rustfmt --edition 2018 "$(find . -name '*.rs' -print)"
else
  rustfmt --check --edition 2018 "$(find . -name '*.rs' -print)"
fi
