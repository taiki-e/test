#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
cd "$(dirname "$0")"/..

failed=0

git config user.name "Taiki Endo"
git config user.email "te316e89@gmail.com"

cargo run --manifest-path tools/codegen/Cargo.toml
git add -N tools
if ! git diff --exit-code -- tools; then
    git add tools
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
