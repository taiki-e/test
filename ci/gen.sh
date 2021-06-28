#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "$0")" && pwd)"/..

failed=0

git config user.name "Taiki Endo"
git config user.email "te316e89@gmail.com"

./tools/target-spec-json.sh
git add -N target-spec-json
if ! git diff --exit-code -- target-spec-json; then
    git add target-spec-json
    git commit -m "Update target-spec-json"
    failed=1
fi

cargo run --manifest-path rust/lint/Cargo.toml
git add -N rust/lint
if ! git diff --exit-code -- rust/lint; then
    git add rust/lint
    git commit -m "Update lint list"
    failed=1
fi

if [[ "${failed}" == "1" ]]; then
    echo "::set-output name=success::false"
fi
