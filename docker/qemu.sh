#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

set -x

ARCH="$1"
# QEMU_VERSION=6.1.0
# http://ftp.debian.org/debian/pool/main/q/qemu
QEMU_VERSION=6.1+dfsg-6

# https://wiki.qemu.org/Hosts/Linux#Building_QEMU_for_Linux
# DEPS=(
#     ca-certificates
#     curl
#     # gcc
#     # libglib2.0-dev
#     # make
#     # ninja-build
#     # xz-utils
#     # zlib1g-dev
# )

# apt-get update
# new_deps=()
# for dep in "${DEPS[@]}"; do
#     if ! dpkg -L "${dep}" &>/dev/null; then
#         new_deps+=("${dep}")
#     fi
# done
# DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${new_deps[@]}"

# curl -fsSL --retry 3 https://download.qemu.org/qemu-"${QEMU_VERSION}".tar.xz | tar xJf -

# pushd "qemu-${QEMU_VERSION}"

# ./configure \
#     --disable-capstone \
#     --disable-docs \
#     --disable-fdt \
#     --disable-kvm \
#     --disable-slirp \
#     --disable-tools \
#     --disable-vnc \
#     --enable-user \
#     --static \
#     --target-list="${ARCH}-linux-user"
# make -j"$(nproc)"
# make install
# make clean

# popd

# if ((${#new_deps[@]})); then
#     apt-get purge -y --auto-remove "${new_deps[@]}"
# fi

dpkg_arch="$(dpkg --print-architecture)"
curl -fsSL --retry 3 "http://ftp.debian.org/debian/pool/main/q/qemu/qemu-user-static_${QEMU_VERSION}_${dpkg_arch##*-}.deb" \
    | dpkg-deb --fsys-tarfile - \
    | tar xvf - --wildcards ./usr/bin/qemu-"${ARCH}"-static --strip-components=3
mv qemu-"${ARCH}"-static /usr/bin/qemu-"${ARCH}"

# rm -rf "qemu-${QEMU_VERSION}"
rm "$0"
