#!/bin/bash

set -euxo pipefail
IFS=$'\n\t'

ARCH="$1"
QEMU_VERSION=6.1.0

# https://wiki.qemu.org/Hosts/Linux#Building_QEMU_for_Linux
DEPS=(
    ca-certificates
    curl
    gcc
    libglib2.0-dev
    make
    ninja-build
    xz-utils
    zlib1g-dev
)

apt-get update
new_deps=()
for dep in "${DEPS[@]}"; do
    if ! dpkg -L "${dep}" &>/dev/null; then
        new_deps+=("${dep}")
    fi
done
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${new_deps[@]}"

curl --retry 3 -LsSf curl https://download.qemu.org/qemu-"${QEMU_VERSION}".tar.xz | tar xJf -

pushd "qemu-${QEMU_VERSION}"

./configure \
    --disable-capstone \
    --disable-docs \
    --disable-fdt \
    --disable-kvm \
    --disable-slirp \
    --disable-tools \
    --disable-vnc \
    --enable-user \
    --static \
    --target-list="${ARCH}-linux-user"
make -j"$(nproc)"
make install
make clean

if ((${#new_deps[@]})); then
    apt-get purge -y --auto-remove "${new_deps[@]}"
fi

popd

rm -rf "qemu-${QEMU_VERSION}"
rm "$0"
