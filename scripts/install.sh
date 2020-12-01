#!/bin/bash

# Install cargo-hack.
#
# Note: This script only intends to use in the CI environment.
# We recommend using `cargo install` for local installations.

set -euo pipefail
IFS=$'\n\t'

PACKAGE="rust-test"
REPOSITORY="taiki-e/test"

host=$(rustc -Vv | grep host | sed 's/host: //')
outdir="${HOME}/.cargo/bin"

curl -LsSf "https://github.com/${REPOSITORY}/releases/latest/download/${PACKAGE}-${host}.tar.gz" \
  | tar xzf - -C "${outdir}"
