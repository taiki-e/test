#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -eEuo pipefail
IFS=$'\n\t'
cd "$(dirname "$0")"/..

# shellcheck disable=SC2154
trap 's=$?; echo >&2 "$0: error on line "${LINENO}": ${BASH_COMMAND}"; exit ${s}' ERR

# https://github.com/rust-lang/rustup/blob/HEAD/rustup-init.sh
ostype=$(uname -s)
if [[ "${ostype}" == "Linux" ]] && [[ "$(uname -o)" == "Android" ]]; then
    ostype=Android
fi
if [[ "${ostype}" == "SunOS" ]] && [[ "$(/usr/bin/uname -o)" == "illumos" ]]; then
    ostype=illumos
fi
case "${ostype}" in
    Linux) ostype=linux ;;
    Android) ostype=android ;;
    Darwin) ostype=macos ;;
    FreeBSD) ostype=freebsd ;;
    NetBSD) ostype=netbsd ;;
    OpenBSD) ostype=openbsd ;;
    DragonFly) ostype=dragonfly ;;
    illumos) ostype=illumos ;;
    SunOS) ostype=solaris ;;
    MINGW* | MSYS* | CYGWIN* | Windows_NT) ostype=windows ;;
    *) echo "error: unrecognized os type ${ostype} for \`\$(uname -s)\`" ;;
esac

set -x

type -P bash
type -P sed
type -P grep
type -P awk
echo
echo >&2

bash --version
git --version
jq --version
shfmt --version
case "${ostype}" in
    solaris) ;; # TODO
    *) shellcheck --version ;;
esac
npm --version
node --version
case "${ostype}" in
    netbsd) python3.11 --version ;;
    *) python3 --version ;;
esac
case "${ostype}" in
    solaris) ;; # TODO
    *)
        rustc -vV
        cargo -vV
        case "${ostype}" in
            # OpenBSD/DragonFlyBSD targets are tier 3 targets, so install Rust from package manager instead of rustup.
            # rustup doesn't support host tools on Solaris. https://github.com/rust-lang/rustup/issues/2987
            openbsd | dragonfly | solaris) ;;
            *) rustup --version ;;
        esac
        ;;
esac
case "${ostype}" in
    openbsd) ;; # TODO
    *) clang-format --version ;;
esac
