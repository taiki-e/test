use std::collections::BTreeMap;

use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use strum::{Display, IntoStaticStr};

use super::*;

pub static TARGET_SPEC: Lazy<BTreeMap<String, TargetSpec>> =
    Lazy::new(|| target_spec_map().unwrap());

pub static TARGET_TIER: Lazy<TargetTier> = Lazy::new(|| target_tier().unwrap());

pub fn download() -> Result<()> {
    let target_spec_url =
        "https://raw.githubusercontent.com/taiki-e/test/main/tools/target-spec.json";
    let target_tier_url =
        "https://raw.githubusercontent.com/taiki-e/test/main/tools/target-tier.json";

    fs::write(
        workspace_root().join("tools/target-spec.json"),
        ureq::get(target_spec_url).call()?.into_string()?,
    )?;
    fs::write(
        workspace_root().join("tools/target-tier.json"),
        ureq::get(target_tier_url).call()?.into_string()?,
    )?;

    Ok(())
}

// creates structured spec map
fn target_spec_map() -> Result<BTreeMap<String, TargetSpec>> {
    Ok(serde_json::from_slice(&fs::read(workspace_root().join("tools/target-spec.json"))?)?)
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct TargetSpec {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub abi: Option<String>,
    pub arch: TargetArch,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub env: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub features: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_atomic_width: Option<u32>,
    #[serde(default, skip_serializing_if = "TargetOs::is_none")]
    pub os: TargetOs,
    #[serde(default, skip_serializing_if = "TargetEndian::is_little")]
    pub target_endian: TargetEndian,
    pub target_pointer_width: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, IntoStaticStr)]
#[allow(non_camel_case_types)]
pub enum TargetArch {
    // all target_arch:
    // https://github.com/rust-lang/rust/blob/67365d64bcdfeae1334bf2ff49587c27d1c973f0/compiler/rustc_target/src/abi/call/mod.rs#L638-L685
    aarch64,
    amdgpu,
    arm,
    asmjs,
    avr,
    bpf,
    hexagon,
    m68k,
    mips,
    mips64,
    msp430,
    nvptx,
    nvptx64,
    powerpc,
    powerpc64,
    riscv32,
    riscv64,
    s390x,
    sparc,
    sparc64,
    wasm32,
    wasm64,
    x86_64,
    x86,
}
pub use TargetArch::*;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, IntoStaticStr)]
#[allow(non_camel_case_types)]
pub enum TargetEndian {
    big,
    little,
}

impl TargetEndian {
    pub fn as_str(self) -> &'static str {
        self.into()
    }

    fn is_little(&self) -> bool {
        matches!(self, Self::little)
    }
}

impl Default for TargetEndian {
    fn default() -> Self {
        Self::little
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, IntoStaticStr)]
#[allow(non_camel_case_types)]
pub enum TargetOs {
    android,
    cuda,
    dragonfly,
    emscripten,
    espidf,
    freebsd,
    fuchsia,
    haiku,
    hermit,
    horizon,
    illumos,
    ios,
    l4re,
    linux,
    macos,
    netbsd,
    none,
    openbsd,
    psp,
    redox,
    solaris,
    solid_asp3,
    tvos,
    uefi,
    unknown,
    vxworks,
    wasi,
    windows,
}
pub use TargetOs::*;

impl TargetOs {
    fn is_none(&self) -> bool {
        matches!(self, Self::none)
    }
}

impl Default for TargetOs {
    fn default() -> Self {
        Self::none
    }
}

// https://doc.rust-lang.org/nightly/rustc/target-tier-policy.html
// https://doc.rust-lang.org/nightly/rustc/platform-support.html
// TODO: get the list from rust-lang/rust instead of manually maintaining it.
#[derive(Debug, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct TargetTier {
    // https://doc.rust-lang.org/nightly/rustc/platform-support.html#tier-1-with-host-tools
    pub tier1: Vec<String>,
    // https://doc.rust-lang.org/nightly/rustc/platform-support.html#tier-2-with-host-tools
    pub tier2_host: Vec<String>,
    // https://doc.rust-lang.org/nightly/rustc/platform-support.html#tier-2
    pub tier2: Vec<String>,
    // https://doc.rust-lang.org/nightly/rustc/platform-support.html#tier-3
    pub tier3: Vec<String>,
}

fn target_tier() -> Result<TargetTier> {
    Ok(serde_json::from_slice(&fs::read(workspace_root().join("tools/target-tier.json"))?)?)
}
