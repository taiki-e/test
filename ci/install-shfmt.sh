#!/bin/bash

set -euo pipefail

GO111MODULE=on go get mvdan.cc/sh/v3/cmd/shfmt
export PATH=${PATH}:${HOME}/go/bin
echo "##[add-path]${HOME}/go/bin"

shfmt --version
