FROM mcr.microsoft.com/vscode/devcontainers/rust:1

RUN rustup toolchain add nightly --component rustfmt,clippy,rust-src 2>&1 \
    && rustup default nightly 2>&1
