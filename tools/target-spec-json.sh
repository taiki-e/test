#!/bin/bash

# Update built-in targets list.
#
# Usage:
#    ./tools/target-spec-json.sh
#
# https://doc.rust-lang.org/nightly/rustc/platform-support.html

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "$0")" && pwd)"/..

for target in $(rustc --print target-list); do
    rustc --print target-spec-json -Z unstable-options --target "${target}" \
        >./target-spec-json/"${target}".json
done
