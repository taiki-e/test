#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

PACKAGE="rust-test"

cd "$(cd "$(dirname "${0}")" && pwd)"/..

if [[ "${GITHUB_REF:?}" != "refs/tags/"* ]]; then
  echo "GITHUB_REF should start with 'refs/tags/'"
  exit 1
fi
tag="${GITHUB_REF#refs/tags/}"

host=$(rustc -Vv | grep host | sed 's/host: //')
target="${1:-${host}}"
cargo="cargo"
if [[ "${host}" != "${target}" ]]; then
  if [[ "${target}" =~ windows ]]; then
    rustup target add "${target}"
  else
    cargo="cross"
    cargo install cross
  fi
fi

export CARGO_PROFILE_RELEASE_LTO=true

$cargo build --bin "${PACKAGE}" --release --target "${target}"

assets=("${PACKAGE}-${target}.tar.gz")
cd target/"${target}"/release
case "${OSTYPE}" in
  linux* | darwin*)
    strip "${PACKAGE}"
    tar czf ../../"${assets[0]}" "${PACKAGE}"
    ;;
  cygwin* | msys*)
    assets+=("${PACKAGE}-${target}.zip")
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
