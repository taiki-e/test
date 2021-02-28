#!/bin/bash

# Install cargo-hack.
#
# Note: This script only intends to use in the CI environment.
# We recommend using `cargo install` for local installations.

set -euo pipefail
IFS=$'\n\t'

package="${PACKAGE:?}"
repository="${REPOSITORY:-"taiki-e/$package"}"
target="${TARGET:-"$(rustc -Vv | grep host | sed 's/host: //')"}"
outdir="${OUTDIR:-"${HOME}/.cargo/bin"}"

set -x

curl -LsSf "https://github.com/${repository}/releases/latest/download/${package}-${target}.tar.gz" \
    | tar xzf - -C "${outdir}"
