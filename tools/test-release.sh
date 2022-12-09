#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC2154
trap 's=$?; echo >&2 "$0: Error on line "${LINENO}": ${BASH_COMMAND}"; exit ${s}' ERR

tag="${1:-v0.0.0}"
git tag -d "${tag}" || true
gh release delete "${tag}" -y || true
git push --delete origin "${tag}" || true
git tag "${tag}" && git push origin --tags
