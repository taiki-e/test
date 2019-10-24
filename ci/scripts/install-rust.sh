#!/bin/bash

set -euo pipefail

if [[ "${AGENT_OS}" == "macOS-latest" ]]; then
    curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain $RUST_TOOLCHAIN
    export PATH=$PATH:$HOME/.cargo/bin
    echo "##[add-path]$HOME/.cargo/bin"
else
    # rustup set profile minimal
    rustup toolchain install $RUST_TOOLCHAIN --no-self-update
    rustup default $RUST_TOOLCHAIN
fi

echo "Query rust and cargo versions:"
rustup -V
rustc -Vv
cargo -V
