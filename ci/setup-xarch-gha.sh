#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
set -x

QEMU_VERSION=6.1+dfsg-5
WASMTIME_VERSION=0.30.0

target="${1:?}"

set_env() {
    if [[ -n "${NO_RUN:-}" ]]; then
        echo "$1"
    else
        echo "export $1" >>./xarch_env
        echo "$1" >>"${GITHUB_ENV}"
    fi
}
set_path() {
    if [[ -n "${NO_RUN:-}" ]]; then
        echo "PATH=$1:\$PATH"
    else
        echo "export PATH=$1:\$PATH" >>./xarch_env
        echo "$1" >>"${GITHUB_PATH}"
    fi
}

apt_deps=(
    ca-certificates
    file
    curl
    gcc
    g++
    libc6-dev
    make
)

triple_lower="${target//-/_}"
triple_upper=$(tr '[:lower:]' '[:upper:]' <<<"${triple_lower}")

if [[ "$(uname -s)" != "Linux" ]] || [[ -z "${CI:-}" ]]; then
    NO_RUN=1
fi

if [[ -z "${NO_RUN:-}" ]]; then
    rm -f ./xarch_env
    touch ./xarch_env
fi

case "${target}" in
    aarch64-unknown-linux-gnu)
        gcc_triplet=aarch64-linux-gnu
        libc_arch=arm64
        qemu_arch=aarch64
        ;;
    arm*-unknown-linux-gnueabi)
        gcc_triplet=arm-linux-gnueabi
        libc_arch=armel
        qemu_arch=arm
        ;;
    arm*-unknown-linux-gnueabihf | thumb*-unknown-linux-gnueabihf)
        gcc_triplet=arm-linux-gnueabihf
        libc_arch=armhf
        qemu_arch=arm
        if [[ "${target}" == "thumbv7"* ]]; then
            qemu_args=" -cpu cortex-a8"
        fi
        ;;
    mips-unknown-linux-gnu)
        gcc_triplet=mips-linux-gnu
        libc_arch=mips
        qemu_arch=mips
        ;;
    mips64-unknown-linux-gnuabi64)
        gcc_triplet=mips64-linux-gnuabi64
        libc_arch=mips64
        qemu_arch=mips64
        ;;
    mips64el-unknown-linux-gnuabi64)
        gcc_triplet=mips64el-linux-gnuabi64
        libc_arch=mips64el
        qemu_arch=mips64el
        ;;
    mipsel-unknown-linux-gnu)
        gcc_triplet=mipsel-linux-gnu
        libc_arch=mipsel
        qemu_arch=mipsel
        ;;
    powerpc-unknown-linux-gnu)
        gcc_triplet=powerpc-linux-gnu
        libc_arch=powerpc
        qemu_arch=ppc
        qemu_args=" -cpu Vger"
        ;;
    powerpc64-unknown-linux-gnu)
        gcc_triplet=powerpc64-linux-gnu
        libc_arch=ppc64
        qemu_arch=ppc64
        qemu_args=" -cpu power9"
        ;;
    powerpc64le-unknown-linux-gnu)
        gcc_triplet=powerpc64le-linux-gnu
        libc_arch=ppc64el
        qemu_arch=ppc64le
        qemu_args=" -cpu power9"
        ;;
    riscv64gc-unknown-linux-gnu)
        gcc_triplet=riscv64-linux-gnu
        libc_arch=riscv64
        qemu_arch=riscv64
        ;;
    s390x-unknown-linux-gnu)
        gcc_triplet=s390x-linux-gnu
        libc_arch=s390x
        qemu_arch=s390x
        ;;
    sparc64-unknown-linux-gnu)
        gcc_triplet=sparc64-linux-gnu
        libc_arch=sparc64
        qemu_arch=sparc64
        ;;

    wasm32-wasi)
        apt_deps+=(
            xz-utils
        )
        set_env "CARGO_TARGET_${triple_upper}_RUNNER=wasmtime --enable-simd --enable-threads --"

        if [[ -n "${NO_RUN:-}" ]]; then
            echo >&2 "skipped installation due to NO_RUN environment variable is set"
            exit 0
        fi

        sudo apt-get -o Dpkg::Use-Pty=0 update -qq
        DEBIAN_FRONTEND=noninteractive sudo apt-get -o Dpkg::Use-Pty=0 install -y --no-install-recommends "${apt_deps[@]}"

        curl -fsSL --retry 3 "https://github.com/bytecodealliance/wasmtime/releases/download/v${WASMTIME_VERSION}/wasmtime-v${WASMTIME_VERSION}-x86_64-linux.tar.xz" | tar xJf -
        set_path "/wasmtime-v${WASMTIME_VERSION}-x86_64-linux"

        rustup target add "${target}"

        exit 0
        ;;

    *) echo >&2 "unrecognized target '${target}'" && exit 1 ;;
esac

if [[ -n "${qemu_arch:-}" ]]; then
    set_env "CARGO_TARGET_${triple_upper}_RUNNER=qemu-${qemu_arch}${qemu_args:-}"
    apt_deps+=(
        binfmt-support
    )
fi
if [[ -n "${gcc_triplet:-}" ]]; then
    set_env "CARGO_TARGET_${triple_upper}_LINKER=${gcc_triplet}-gcc"
    set_env "CC_${triple_lower}=${gcc_triplet}-gcc"
    set_env "CXX_${triple_lower}=${gcc_triplet}-g++"
    set_env "OBJDUMP=${gcc_triplet}-objdump"
    set_env "STRIP=${gcc_triplet}-strip"
    set_env "QEMU_LD_PREFIX=/usr/${gcc_triplet}"
    apt_deps+=(
        "gcc-${gcc_triplet}"
        "g++-${gcc_triplet}"
    )
fi
if [[ -n "${libc_arch:-}" ]]; then
    apt_deps+=(
        "libc6-dev-${libc_arch}-cross"
    )
fi

if [[ -n "${NO_RUN:-}" ]]; then
    echo >&2 "skipped installation due to NO_RUN environment variable is set"
    exit 0
fi

sudo apt-get -o Dpkg::Use-Pty=0 update -qq
DEBIAN_FRONTEND=noninteractive sudo apt-get -o Dpkg::Use-Pty=0 install -y --no-install-recommends "${apt_deps[@]}"

if [[ -n "${qemu_arch:-}" ]]; then
    dpkg_arch="$(dpkg --print-architecture)"
    curl -fsSL --retry 3 "http://ftp.debian.org/debian/pool/main/q/qemu/qemu-user-static_${QEMU_VERSION}_${dpkg_arch##*-}.deb" \
        | dpkg-deb --fsys-tarfile - \
        | tar xvf - --wildcards ./usr/bin/qemu-"${qemu_arch}"-static --strip-components=3
    sudo mv qemu-"${qemu_arch}"-static /usr/bin/qemu-"${qemu_arch}"
fi

rustup target add "${target}"
