#!/usr/bin/env bash
# shellcheck disable=SC2207
set -euo pipefail
IFS=$'\n\t'
cd "$(dirname "$0")"/..

# shellcheck disable=SC2154
trap 's=$?; echo >&2 "$0: Error on line "${LINENO}": ${BASH_COMMAND}"; exit ${s}' ERR

# Generates types used by codegen.
#
# USAGE:
#    ./tools/target_spec.sh
#
# This script is intended to called by gen.sh.

file="tools/codegen/src/gen/target_spec.rs"
mkdir -p "$(dirname "${file}")"

target_arch=()
target_os=()
target_env=()
for target in $(rustc --print target-list); do
    target_spec=$(rustc --print target-spec-json -Z unstable-options --target "${target}")
    target_arch+=("$(jq <<<"${target_spec}" -r '.arch')")
    target_os+=("$(jq <<<"${target_spec}" -r '.os')")
    target_env+=("$(jq <<<"${target_spec}" -r '.env')")
done
# sort and dedup
IFS=$'\n'
target_arch=($(LC_ALL=C sort -u <<<"${target_arch[*]}"))
target_os=($(LC_ALL=C sort -u <<<"${target_os[*]}"))
target_env=($(LC_ALL=C sort -u <<<"${target_env[*]}"))
IFS=$'\n\t'

derive='#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, IntoStaticStr)]'
default() {
    cat <<EOF
impl $1 {
    pub fn is_$2(&self) -> bool {
        matches!(self, Self::$2)
    }
}
impl Default for $1 {
    fn default() -> Self {
        Self::$2
    }
}
EOF
}

cat >"${file}" <<EOF
// This file is @generated by $(basename "$0").
// It is not intended for manual editing.

#![allow(non_camel_case_types)]

use serde::{Deserialize, Serialize};
use strum::{Display, IntoStaticStr};

${derive}
pub enum TargetArch {
$(sed <<<"${target_arch[*]}" -E 's/^/    /g; s/$/,/g')
    // Architectures that do not included in builtin targets.
    // See also https://github.com/rust-lang/rust/blob/1.68.0/compiler/rustc_target/src/abi/call/mod.rs#L663
    // and https://github.com/rust-lang/rust/blob/540a50df0fb23127edf0b35b0e497748e24bba1a/src/bootstrap/lib.rs#L132.
    amdgpu,
    asmjs,
    loongarch64,
    nvptx,
    spirv,
    xtensa,
}
pub use TargetArch::*;
impl TargetArch {
    pub fn as_str(self) -> &'static str {
        self.into()
    }
}

${derive}
pub enum TargetOs {
$(sed <<<"${target_os[*]}" -E 's/^/    /g; s/$/,/g; s/null/none/g')
}
pub use TargetOs::*;
impl TargetOs {
    pub fn as_str(self) -> &'static str {
        self.into()
    }
}
$(default TargetOs none)

${derive}
pub enum TargetEnv {
$(sed <<<"${target_env[*]}" -E 's/^/    /g; s/$/,/g; s/null/none/g')
    // Environments that do not included in builtin targets.
    // See also https://github.com/rust-lang/rust/blob/540a50df0fb23127edf0b35b0e497748e24bba1a/src/bootstrap/lib.rs#L130.
    libnx,
}
pub use TargetEnv::*;
impl TargetEnv {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::none => "",
            _ => self.into(),
        }
    }
}
$(default TargetEnv none)

${derive}
pub enum TargetEndian {
    big,
    little,
}
impl TargetEndian {
    pub fn as_str(self) -> &'static str {
        self.into()
    }
}
$(default TargetEndian little)
EOF
