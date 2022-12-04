#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

tag="${1:-v0.0.0}"
git tag -d "${tag}" || true
gh release delete "${tag}" -y || true
git push --delete origin "${tag}" || true
git tag "${tag}" && git push origin --tags
