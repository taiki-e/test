#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -CeEuo pipefail
IFS=$'\n\t'
trap -- 's=$?; printf >&2 "%s\n" "${0#./}:${LINENO}: \`${BASH_COMMAND}\` exit with ${s}"; exit ${s}' ERR
cd "$(dirname -- "$0")"/..

tag="${1:-v0.0.0}"
git tag -d "${tag}" || true
gh release delete "${tag}" -y || true
git push --delete origin "${tag}" || true
git tag "${tag}"
git push origin --tags
