#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -eEuo pipefail
IFS=$'\n\t'

# shellcheck disable=SC2154
trap 's=$?; echo >&2 "$0: error on line "${LINENO}": ${BASH_COMMAND}"; exit ${s}' ERR

tag="${1:-v0.0.0}"
git tag -d "${tag}" || true
gh release delete "${tag}" -y || true
git push --delete origin "${tag}" || true
git tag "${tag}" && git push origin --tags
