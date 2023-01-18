# https://github.com/devcontainers/images/tree/HEAD/src/rust
FROM mcr.microsoft.com/devcontainers/rust:bullseye

RUN rustup toolchain add nightly \
        --component rustfmt,clippy,rust-src \
        2>&1 \
    && rustup default nightly 2>&1
