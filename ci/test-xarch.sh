#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "$0")" && pwd)"/..

set -x

run() {
    echo "Testing $1"
    ./ci/setup-xarch-gha.sh "$1"
    cat ./xarch_env
    # shellcheck disable=SC1091
    . ./xarch_env
    time cargo test --workspace --target "${1/-emulated/}"
}

if [ -z "${1:-}" ]; then
    for d in docker/*; do
        if [[ -d "$d" ]]; then
            target="${d/docker\//}"
            case "${target}" in
                arm* | i586* | i686* | wasm* | x86_64*)
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
