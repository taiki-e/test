#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "$0")" && pwd)"/..

PROJECT="xarch"

set -x

build() {
    echo "Building docker image for ${1}"
    docker build -t "${PROJECT}/${1}" -f "docker/${1}/Dockerfile" docker/
}

if [[ -z "${1:-}" ]]; then
    for d in docker/*; do
        if [[ -d "$d" ]]; then
            build "${d/docker\//}"
        fi
    done
else
    build "${1}"
fi
