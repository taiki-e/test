#!/bin/bash

# Adapted from https://github.com/rust-lang/rust/blob/218a96cae06ed1a47549a81c09c3655fbcae1363/src/ci/docker/scripts/musl.sh.

set -euo pipefail
IFS=$'\n\t'

TAG="$1"
shift

MUSL=musl-1.1.24

# may have been downloaded in a previous run
if [[ ! -d "$MUSL" ]]; then
    curl --retry 3 -LsSf curl https://www.musl-libc.org/releases/"$MUSL".tar.gz | tar xzf -
fi

cd "$MUSL"
./configure --enable-optimize --enable-debug --disable-shared --prefix=/musl-"$TAG" "$@"
if [[ "$TAG" == "i586" ]] || [[ "$TAG" == "i686" ]]; then
    make -j"$(nproc)" AR=ar RANLIB=ranlib
else
    make -j"$(nproc)"
fi
make install
make clean
