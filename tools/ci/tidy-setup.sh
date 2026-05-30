#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
set -CeEuo pipefail
IFS=$'\n\t'
trap -- 's=$?; printf >&2 "%s\n" "${0##*/}:${LINENO}: \`${BASH_COMMAND}\` exit with ${s}"; exit ${s}' ERR
trap -- 'printf >&2 "%s\n" "${0##*/}: trapped SIGINT"; exit 1' SIGINT
cd -- "$(dirname -- "$0")"/../..

retry() {
  for i in {1..10}; do
    if "$@"; then
      return 0
    else
      sleep "${i}"
    fi
  done
  "$@"
}
g() {
  set +x
  IFS=' '
  cmd="$*"
  IFS=$'\n\t'
  printf '::group::%s\n' "${cmd#retry }"
  "$@"
  printf '::endgroup::\n'
  set -x
}
bail() {
  if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    printf '::error::%s\n' "$*"
  else
    printf >&2 'error: %s\n' "$*"
  fi
  exit 1
}

if ! type -P sudo >/dev/null; then
  sudo() { "$@"; }
fi

set -x

# https://github.com/rust-lang/rustup/blob/HEAD/rustup-init.sh
case "$(uname -s)" in
  # Linux)
  #   if [[ "$(uname -o)" == 'Android' ]]; then
  #     ostype=android
  #   else
  #     ostype=linux
  #   fi
  #   ;;
  # Darwin) ostype=macos ;;
  FreeBSD)
    # ostype=freebsd
    # Refs: https://www.freshports.org/
    retry sudo pkg install -y git jq npm python3 devel/uv shfmt hs-ShellCheck llvm
    retry curl --proto '=https' --tlsv1.2 -fsSL --retry 10 https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain nightly --no-modify-path
    export PATH="${HOME}/.cargo/bin:${PATH}"
    retry curl --proto '=https' --tlsv1.2 -fsSL --retry 10 "https://github.com/taiki-e/parse-dockerfile/releases/latest/download/parse-dockerfile-x86_64-unknown-freebsd.tar.gz" | tar xzf - -C "${HOME}/.cargo/bin"
    cargo install zizmor --debug --locked
    rm -rf -- /tmp/cargo-install* # cargo install artifacts
    # min-release-age and allow-git requires npm 11.10+
    npm --version
    sudo npm install --location=global npm@11.11.0
    ;;
  NetBSD)
    # ostype=netbsd
    retry sudo pkgin update
    # Refs: https://ftp.netbsd.org/pub/pkgsrc/packages/NetBSD/x86_64/
    # uv from package manager is old
    retry sudo pkgin -y install mozilla-rootcerts-openssl git jq nodejs shfmt shellcheck clang
    sudo pkgin clean
    sudo ln -s -- /usr/pkg/bin/python3.13 /usr/pkg/bin/python3
    sudo ln -s -- /usr/pkg/bin/uv-3.13 /usr/pkg/bin/uv
    sudo ln -s -- /usr/pkg/bin/uvx-3.13 /usr/pkg/bin/uvx
    export PATH="${HOME}/.local/bin:${PATH}"
    retry curl --proto '=https' --tlsv1.2 -fsSL --retry 10 https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain nightly --no-modify-path
    export PATH="${HOME}/.cargo/bin:${PATH}"
    cargo install parse-dockerfile --debug
    rm -rf -- /tmp/cargo-install* # cargo install artifacts
    # Failed to install due to jemalloc build error,
    # and "No space left on device" error: https://github.com/cross-platform-actions/action/issues/111
    # cargo install zizmor --debug --locked --git https://github.com/taiki-e/zizmor.git --branch dev
    # rm -rf -- /tmp/cargo-install* # cargo install artifacts
    # min-release-age and allow-git requires npm 11.10+
    npm --version
    sudo npm install --location=global npm@11.11.0
    ;;
  OpenBSD)
    # ostype=openbsd
    # Refs: https://openbsd.app/?search=
    # OpenBSD targets are tier 3 targets, so install Rust from package manager instead of rustup.
    # uv from package manager is old
    retry sudo pkg_add git jq node shfmt shellcheck rust rust-rustfmt clang-tools-extra
    export PATH="${HOME}/.cargo/bin:${PATH}"
    cargo install parse-dockerfile --debug
    rm -rf -- /tmp/cargo-install* # cargo install artifacts
    # Failed to install due to jemalloc build error,
    # fixed in https://github.com/zizmorcore/zizmor/pull/1812
    cargo install zizmor --debug --locked --git https://github.com/taiki-e/zizmor.git --branch dev
    rm -rf -- /tmp/cargo-install* # cargo install artifacts
    # min-release-age and allow-git requires npm 11.10+
    npm --version
    # Failed due to "npm error Cannot find module 'promise-retry'"
    sudo npm install --location=global npm@11.11.0
    ;;
  DragonFly)
    # ostype=dragonfly
    retry pkg upgrade -y # needed to avoid Undefined symbol "uv_library_shutdown" error
    # DragonFly BSD targets are tier 3 targets, so install Rust from package manager instead of rustup.
    # Refs: https://avalon.dragonflybsd.org/dports/dragonfly:6.4:x86:64/LATEST/All/
    retry pkg install -y bash git jq npm-node20 python3 hs-ShellCheck rust llvm
    # go and shfmt not available in 6.4 packages since 2025-03-17.
    go_version=1.24.13 # https://go.dev/dl
    mkdir -p -- "${HOME}/go"
    retry curl --proto '=https' --tlsv1.2 -fsSL --retry 10 "https://go.dev/dl/go${go_version}.dragonfly-amd64.tar.gz" | tar xzf - -C "${HOME}/go"
    export PATH="${HOME}/go/go/bin:${PATH}"
    go version
    export GOPATH="${HOME}/go"
    export PATH="${GOPATH}/bin:${PATH}"
    go install mvdan.cc/sh/v3/cmd/shfmt@v3.11.0
    export PATH="${HOME}/.cargo/bin:${PATH}"
    cargo install parse-dockerfile --debug
    rm -rf -- /tmp/cargo-install* # cargo install artifacts
    # rustc installed from package manager is 1.85, latest uv requires 1.92.
    # Failed to install due to sys-info build error,
    # cargo install uv --debug --locked --git https://github.com/astral-sh/uv.git --rev 4ed9c5791ba9d5c304aae14b920d612af26dc2d3 # 0.7.15
    # rustc installed from package manager is 1.85, latest zizmor requires 1.88 and 1.85 compatible version (1.11.0) doesn't support config that we use.
    # cargo install zizmor --debug --locked
    rm -rf -- /tmp/cargo-install* # cargo install artifacts
    # min-release-age and allow-git requires npm 11.10+
    npm --version
    npm install --location=global npm@11.11.0
    ;;
  MidnightBSD)
    # ostype=midnight
    ;;
  SunOS)
    if [[ "$(/usr/bin/uname -o)" == 'illumos' ]]; then
      # ostype=illumos
      if [[ "$(/usr/bin/uname -a)" == 'omnios' ]]; then
        # Refs: https://omnios.org/info/ipsrepos
        retry sudo pkg install developer/versioning/git gnu-tar jq runtime/node-24 runtime/python-313 developer/clang-21
        export PATH="${HOME}/.local/bin:${PATH}"
        retry curl --proto '=https' --tlsv1.2 -fsSL --retry 10 -o bootstrap.tar.gz https://pkgsrc.SmartOS.org/packages/SmartOS/bootstrap/bootstrap-2024Q4-x86_64.tar.gz
        sudo tar xzpf bootstrap.tar.gz -C /
        export PATH="/opt/local/sbin:/opt/local/bin:${PATH}"
        # Refs: https://pkgsrc.smartos.org/packages/SmartOS/2024Q4/x86_64/All/
        retry sudo pkgin -y install shfmt shellcheck
        retry curl --proto '=https' --tlsv1.2 -fsSL --retry 10 https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain nightly --no-modify-path
        export PATH="${HOME}/.cargo/bin:${PATH}"
        # Use gtar instead of tar because "tar: directory checksum error" error
        retry curl --proto '=https' --tlsv1.2 -fsSL --retry 10 "https://github.com/taiki-e/parse-dockerfile/releases/latest/download/parse-dockerfile-x86_64-unknown-illumos.tar.gz" | gtar xzf - -C "${HOME}/.cargo/bin"
        # Failed to install due to jemalloc build error,
        # and "No space left on device" error: https://github.com/cross-platform-actions/action/issues/111
        # unset RUSTFLAGS
        # cargo install uv --debug --locked --git https://github.com/taiki-e/uv.git --branch dev
        # rm -rf -- /tmp/cargo-install* # cargo install artifacts
        # Failed to install due to jemalloc build error,
        # and "No space left on device" error: https://github.com/cross-platform-actions/action/issues/111
        # cargo install zizmor --debug --locked --git https://github.com/taiki-e/zizmor.git --branch dev
        rm -rf -- /tmp/cargo-install* # cargo install artifacts
        # min-release-age and allow-git requires npm 11.10+
        npm --version
        sudo npm install --location=global npm@11.11.0
      elif [[ "$(/usr/bin/uname -a)" == 'omnios' ]]; then
        # Install Rust from package manager due to "ld.so.1: rustup-init: fatal: libgcc_s.so.1: open failed: No such file or directory" error.
        # Refs: https://pkg.openindiana.org/hipster/en/index.shtml
        retry pkg install developer/versioning/git archiver/gnu-tar test/jq runtime/nodejs runtime/python developer/clang-21 developer/gcc-14 developer/lang/rustc
        retry curl --proto '=https' --tlsv1.2 -fsSL --retry 10 -o bootstrap.tar.gz https://pkgsrc.SmartOS.org/packages/SmartOS/bootstrap/bootstrap-2024Q4-x86_64.tar.gz
        tar xzpf bootstrap.tar.gz -C /
        export PATH="/opt/local/sbin:/opt/local/bin:${PATH}"
        # Refs: https://pkgsrc.smartos.org/packages/SmartOS/2024Q4/x86_64/All/
        retry pkgin -y install shfmt shellcheck
        export PATH="${HOME}/.cargo/bin:${PATH}"
        # Install from source due to "libgcc_s.so.1: open failed: No such file or directory" error.
        cargo install parse-dockerfile --debug
        rm -rf -- /tmp/cargo-install* # cargo install artifacts
        # Failed to install due to jemalloc build error.
        # Install uv from source is very slow.
        # cargo install uv --debug --locked --git https://github.com/taiki-e/uv.git --branch dev
        # rm -rf -- /tmp/cargo-install* # cargo install artifacts
        # Failed to install due to jemalloc build error.
        # Install zizmor from source is very slow.
        # cargo install zizmor --debug --locked --git https://github.com/taiki-e/zizmor.git --branch dev
        # rm -rf -- /tmp/cargo-install* # cargo install artifacts
        # min-release-age and allow-git requires npm 11.10+
        npm --version
        npm install --location=global npm@11.11.0
      fi
    else
      # ostype=solaris
      g ld -z help
      # Refs: http://pkg.oracle.com/solaris/release/en/index.shtml
      g retry pkg install developer/versioning/git jq pkg://solaris/runtime/python-313 runtime/nodejs developer/llvm/clang developer/go
      export GOPATH="${HOME}/go"
      export PATH="${GOPATH}/bin:${PATH}"
      g go install mvdan.cc/sh/v3/cmd/shfmt@v3.11.0
      # TODO: shellcheck
      retry curl --proto '=https' --tlsv1.2 -fsSL --retry 10 https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain nightly --no-modify-path
      export PATH="${HOME}/.cargo/bin:${PATH}"
      retry curl --proto '=https' --tlsv1.2 -fsSL --retry 10 "https://github.com/taiki-e/parse-dockerfile/releases/latest/download/parse-dockerfile-x86_64-unknown-illumos.tar.gz" | tar xzf - -C "${HOME}/.cargo/bin"
      # Failed to install due to jemalloc build error,
      # and uv-unix build error.
      # unset RUSTFLAGS
      # cargo install uv --debug --locked --git https://github.com/taiki-e/uv.git --branch dev
      # rm -rf -- /tmp/cargo-install* # cargo install artifacts
      # Failed to install due to jemalloc build error,
      # and tree-sitter build error.
      # cargo install zizmor --debug --locked --git https://github.com/taiki-e/zizmor.git --branch dev
      # rm -rf -- /tmp/cargo-install* # cargo install artifacts
      # min-release-age and allow-git requires npm 11.10+
      npm --version
      npm install --location=global npm@11.11.0
    fi
    ;;
  # Haiku) ostype=haiku ;;
  # Minix) ostype=minix ;;
  # GNU) ostype=hurd ;;
  # AIX) ostype=aix ;;
  # HP-UX) ostype=hpux ;;
  # MINGW* | MSYS* | CYGWIN* | Windows_NT) ostype=windows ;;
  # *) bail "unrecognized os type '$(uname -s)' for \`\$(uname -s)\`" ;;
esac

git config --global --add safe.directory "${PWD}"
