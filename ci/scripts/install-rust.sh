#!/bin/bash

set -euo pipefail

toolchain="${1:-nightly}"

set +e
if rustup -V 2>/dev/null; then
    set -e
    rustup set profile minimal
    rustup update "${toolchain}" --no-self-update
    rustup default "${toolchain}"
else
    set -e
    curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain "${toolchain}"
    export PATH=${PATH}:${HOME}/.cargo/bin
    echo "##[add-path]${HOME}/.cargo/bin"
fi

echo "Query rust and cargo versions:"
rustup -V
rustc -V
cargo -V
