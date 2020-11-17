#!/bin/bash

# Install nightly Rust with a given component.
#
# If the component is unavailable on the latest nightly,
# use the latest toolchain with the component available.
#
# When using stable Rust, this script is basically unnecessary as almost components available.
#
# Refs: https://github.com/rust-lang/rustup-components-history#the-web-part

set -euo pipefail
IFS=$'\n\t'

component="${1:?}"
host=$(rustc -Vv | grep host | sed 's/host: //')
target="${2:-${host}}"

toolchain="${3:-}"
if [[ -z "${toolchain}" ]]; then
  toolchain=nightly-$(curl -sSf https://rust-lang.github.io/rustup-components-history/"${target}"/"${component}")
fi

# shellcheck disable=1090
"$(cd "$(dirname "${0}")" && pwd)"/install-rust.sh "${toolchain}"

rustup component add "${component}"
