#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

ref="${GITHUB_REF:?}"
tag=${ref#*/tags/}
repo="${GITHUB_REPOSITORY:?}"

# valid tag format: (PACKAGE_NAME-)vMAJOR.MINOR.PATCH(-PRERELEASE)(+BUILD_METADATA)
# Refs: https://semver.org
if [[ ! "${tag}" =~ (^|^[a-zA-Z_0-9-]+-)v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z_0-9\.-]+)?(\+[a-zA-Z_0-9\.-]+)?$ ]]; then
  echo "invalid tag format: ${tag}"
  exit 1
elif [[ "${tag}" =~ (^|^[a-zA-Z_0-9-]+-)v[0-9\.]+-[a-zA-Z_0-9\.-]+(\+[a-zA-Z_0-9\.-]+)?$ ]]; then
  prerelease="--prerelease"
fi
package_name=$(echo "${tag}" | sed -r "s/-v[0-9\.]+(-[a-zA-Z_0-9\.-]+)?$//")
version=$(echo "${tag}" | sed -r "s/(^|^[a-zA-Z_0-9-]+-)v//")
date=$(date --utc '+%Y-%m-%d')
if [[ "${package_name}" == "${tag}" ]]; then
  title="${version}"
else
  title="${package_name} ${version}"
  repo="${repo}/${package_name}"
fi
# TODO: this link will be broken when the version yanked if the project adheres to the keep-a-changelog's yanking style.
changelog="https://github.com/${repo}/blob/HEAD/CHANGELOG.md#${version//./}---${date}"
notes="See the [release notes](${changelog}) for details on the changes."

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "GITHUB_TOKEN not set, skipping deploy"
  exit 1
else
  if gh release view "${tag}" &>/dev/null; then
    gh release delete "${tag}" -y
  fi
  gh release create "${tag}" ${prerelease:-} --title "${title}" --notes "${notes}"
fi
