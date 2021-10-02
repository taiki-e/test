#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

"${GOROOT_1_17_X64}"/bin/go install mvdan.cc/sh/v3/cmd/shfmt@latest
echo "${HOME}/go/bin" >>"${GITHUB_PATH}"
