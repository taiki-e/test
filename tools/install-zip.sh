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

curl -LsSf "https://github.com/${repository}/releases/latest/download/${package}-${target}.zip" -o cargo-hack.zip
case "${OSTYPE}" in
    linux* | darwin*)
        unzip cargo-hack.zip -d "${outdir}"
        ;;
    cygwin* | msys*)
        7z x cargo-hack.zip -o"${outdir}"
        ;;
    *)
        error "unrecognized OSTYPE: ${OSTYPE}"
        exit 1
        ;;
esac
