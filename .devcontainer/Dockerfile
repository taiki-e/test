FROM mcr.microsoft.com/vscode/devcontainers/rust:1

RUN apt-get update \
    && rustup toolchain install nightly --component rustfmt,clippy 2>&1 \
    && rustup default nightly 2>&1
