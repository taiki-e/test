#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

host=$(rustc -Vv | grep host | sed 's/host: //')
tag=$(curl -LsSf https://api.github.com/repos/rust-embedded/cross/releases/latest | jq -r '.tag_name')
curl -LsSf https://github.com/rust-embedded/cross/releases/latest/download/cross-"${tag}"-"${host}".tar.gz \
  | tar xzf - -C "${HOME}"/.cargo/bin
