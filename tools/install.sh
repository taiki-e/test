#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC2154
trap 's=$?; echo >&2 "$0: Error on line "${LINENO}": ${BASH_COMMAND}"; exit ${s}' ERR

# Install cargo-hack.
#
# Note: This script only intends to use in the CI environment.
# We recommend using `cargo install` for local installations.

package="${PACKAGE:?}"
repository="${REPOSITORY:-"taiki-e/${package}"}"
target="${TARGET:-"$(rustc -Vv | grep host | sed 's/host: //')"}"
outdir="${OUTDIR:-"${HOME}/.cargo/bin"}"

set -x

curl -LsSf "https://github.com/${repository}/releases/latest/download/${package}-${target}.tar.gz" \
    | tar xzf - -C "${outdir}"
