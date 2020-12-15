#!/bin/bash

# https://github.com/rust-lang/rust/blob/7e9a36fa8a4ec06daec581e23f390389e05f25e4/src/ci/docker/host-x86_64/dist-various-1/build-rumprun.sh

set -euo pipefail
IFS=$'\n\t'

hide_output() {
  set +x
  on_err="
echo ERROR: An error was encountered with the build.
cat /tmp/build.log
exit 1
"
  # shellcheck disable=SC2064
  trap "${on_err}" ERR
  bash -c "while true; do sleep 30; echo \$(date) - building ...; done" &
  PING_LOOP_PID=$!
  "$@" &>/tmp/build.log
  trap - ERR
  kill ${PING_LOOP_PID}
  rm /tmp/build.log
  set -x
}

git clone https://github.com/rumpkernel/rumprun.git
(
  cd rumprun
  git submodule update --init
  CC=cc hide_output ./build-rr.sh -d /usr/local hw
)
rm -rf ./rumprun

echo "${HOME}/rumprun/bin" >>"${GITHUB_PATH}"
echo "RUMPRUN_TOOLCHAIN_TUPLE=x86_64-rumprun-netbsd" >>"${GITHUB_ENV}"
