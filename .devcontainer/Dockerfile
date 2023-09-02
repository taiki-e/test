# https://github.com/devcontainers/images/tree/HEAD/src/rust
FROM mcr.microsoft.com/devcontainers/rust:bookworm

RUN sudo apt-get update && sudo apt-get install -y \
        bash-completion \
    && rustup toolchain add nightly --profile minimal \
        --component rustfmt,clippy,rust-src \
        2>&1 \
    && rustup default nightly 2>&1
