#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "${0}")" && pwd)"/..

ref="${GITHUB_REF:?}"
tag="${ref#*/tags/}"

export CARGO_PROFILE_RELEASE_LTO=true
host=$(rustc -Vv | grep host | sed 's/host: //')

package="test"
cd rust
cargo build --bin "${package}" --release
cd ..

cd target/release
case "${OSTYPE}" in
  linux* | darwin*)
    strip "${package}"
    asset="${package}-${host}.tar.gz"
    tar czf ../../"${asset}" "${package}"
    ;;
  cygwin* | msys*)
    asset="${package}-${host}.zip"
    7z a ../../"${asset}" "${package}".exe
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
  gh release upload "${tag}" "${asset}" --clobber
fi