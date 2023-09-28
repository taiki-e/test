# SPDX-License-Identifier: Apache-2.0 OR MIT

# https://github.com/devcontainers/images/tree/HEAD/src/rust
FROM mcr.microsoft.com/devcontainers/rust:bookworm

RUN sudo apt-get -o Acquire::Retries=10 -qq update \
    && sudo apt-get -o Acquire::Retries=10 -o Dpkg::Use-Pty=0 install -y --no-install-recommends \
        bash-completion \
    && rustup toolchain add nightly --profile minimal \
        --component rustfmt,clippy,rust-src \
        2>&1 \
    && rustup default nightly 2>&1
