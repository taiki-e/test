#!/bin/bash

# https://emscripten.org/docs/getting_started/downloads.html

set -euo pipefail
IFS=$'\n\t'

git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
# shellcheck disable=SC1091
source ./emsdk_env.sh
