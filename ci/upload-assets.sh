#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "${0}")" && pwd)"/..

if [[ "${GITHUB_REF:?}" != "refs/tags/"* ]]; then
  echo "GITHUB_REF should start with 'refs/tags/'"
  exit 1
fi
tag="${GITHUB_REF#refs/tags/}"

export CARGO_PROFILE_RELEASE_LTO=true
host=$(rustc -Vv | grep host | sed 's/host: //')

PACKAGE="rust-test"
cd rust
cargo build --bin "${PACKAGE}" --release
cd ..

assets=("${PACKAGE}-${host}.tar.gz")
cd target/release
case "${OSTYPE}" in
  linux* | darwin*)
    strip "${PACKAGE}"
    tar czf ../../"${assets[0]}" "${PACKAGE}"
    ;;
  cygwin* | msys*)
    assets+=("${PACKAGE}-${host}.zip")
    tar czf ../../"${assets[0]}" "${PACKAGE}".exe
    7z a ../../"${assets[1]}" "${PACKAGE}".exe
    ;;
  *)
    echo "unrecognized OSTYPE: ${OSTYPE}"
    exit 1
    ;;
esac
cd ../..

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "GITHUB_TOKEN not set, skipping deploy"
  exit 1
else
  gh release upload "${tag}" "${assets[@]}" --clobber
fi
