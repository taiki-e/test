#!/bin/bash

set -euo pipefail

GO111MODULE=on go get mvdan.cc/sh/v3/cmd/shfmt
echo "${HOME}/go/bin" >>"${GITHUB_PATH}"
