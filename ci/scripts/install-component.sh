#!/bin/bash

set -euo pipefail

set +e
if rustup component add $RUST_COMPONENT; then
    set -e
else
    set -e
    # If the component is unavailable on the latest nightly,
    # use the latest toolchain with the component available.
    # Refs: https://github.com/rust-lang/rustup-components-history#the-web-part
    target=$(curl -sSf https://rust-lang.github.io/rustup-components-history/x86_64-unknown-linux-gnu/$RUST_COMPONENT)
    echo "'$RUST_COMPONENT' is unavailable on the toolchain '$RUST_TOOLCHAIN', use the toolchain 'nightly-$target' instead"
    rustup toolchain install nightly-$target --no-self-update
    rustup default nightly-$target
    rustup component add $RUST_COMPONENT

    echo "Query rust and cargo versions:"
    rustup -V
    rustc -Vv
    cargo -V
fi

echo "Query component versions:"
case $RUST_COMPONENT in
    clippy) cargo clippy -V ;;
    rustfmt) rustfmt -V ;;
esac
