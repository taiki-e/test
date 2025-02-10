#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -CeEuo pipefail
IFS=$'\n\t'
trap -- 's=$?; printf >&2 "%s\n" "${0##*/}:${LINENO}: \`${BASH_COMMAND}\` exit with ${s}"; exit ${s}' ERR
trap -- 'printf >&2 "%s\n" "${0##*/}: trapped SIGINT"; exit 1' SIGINT
cd -- "$(dirname -- "$0")"/../..

bail() {
  if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    printf '::error::%s\n' "$*"
  else
    printf >&2 'error: %s\n' "$*"
  fi
  exit 1
}

# https://github.com/rust-lang/rustup/blob/HEAD/rustup-init.sh
case "$(uname -s)" in
  Linux)
    if [[ "$(uname -o)" == 'Android' ]]; then
      ostype=android
    else
      ostype=linux
    fi
    ;;
  Darwin) ostype=macos ;;
  FreeBSD) ostype=freebsd ;;
  NetBSD) ostype=netbsd ;;
  OpenBSD) ostype=openbsd ;;
  DragonFly) ostype=dragonfly ;;
  SunOS)
    if [[ "$(/usr/bin/uname -o)" == 'illumos' ]]; then
      ostype=illumos
    else
      ostype=solaris
    fi
    ;;
  MINGW* | MSYS* | CYGWIN* | Windows_NT) ostype=windows ;;
  *) bail "unrecognized os type '$(uname -s)' for \`\$(uname -s)\`" ;;
esac

set -x

/usr/bin/uname -o || true
ls -- /usr/xpg4/bin || true
ls -- /usr/xpg6/bin || true
ls -- /usr/xpg7/bin || true
type -P bash
type -P sed
type -P grep
type -P awk
type -P npm
type -P node
printf '\n'
printf >&2 '\n'

bash --version
sed --help 2>&1 || true
grep --help 2>&1 || true
awk --help 2>&1 || true
git --version
jq --version
shfmt --version
shellcheck --version
npm --version
node --version
python3 --version
rustc -vV
cargo -vV
case "${ostype}" in
  # OpenBSD/DragonFly BSD targets are tier 3 targets, so install Rust from package manager instead of rustup.
  # rustup doesn't support host tools on Solaris. https://github.com/rust-lang/rustup/issues/2987
  openbsd | dragonfly | solaris) rustup --version || true ;;
  *) rustup --version ;;
esac
case "${ostype}" in
  openbsd) clang-format --version || type -P clang-format >/dev/null || true ;; # TODO
  # clang-format 3.4.2 exit with 1 on --version flag
  *) clang-format --version || type -P clang-format >/dev/null ;;
esac
