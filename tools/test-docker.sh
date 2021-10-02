#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "$0")" && pwd)"/..

set -x

run() {
    ./tools/build-docker.sh "$1"

    echo "Testing $1"
    time cross test --workspace --target "${1/-emulated/}"
}

if [ -z "${1:-}" ]; then
    for d in docker/*; do
        if [[ -d "$d" ]]; then
            target="${d/docker\//}"
            case "${target}" in
                arm* | i586* | i686* | wasm* | x86_64-unknown-linux-gnu)
                    # TODO: rm this branch
                    ;;
                *)
                    run "${target}"
                    ;;
            esac
        fi
    done
else
    run "${1}"
fi
