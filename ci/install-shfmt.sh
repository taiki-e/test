#!/bin/bash

set -euo pipefail

go get -u github.com/mvdan/sh/cmd/shfmt
export PATH=${PATH}:${HOME}/go/bin
echo "##[add-path]${HOME}/go/bin"

shfmt --version
