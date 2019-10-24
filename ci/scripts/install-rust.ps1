#Requires -Version 6

$ErrorActionPreference = "stop"

# rustup set profile minimal
rustup toolchain install $env:RUST_TOOLCHAIN --no-self-update
rustup default $env:RUST_TOOLCHAIN

echo "Query rust and cargo versions:"
rustup -V
rustc -Vv
cargo -Vv
