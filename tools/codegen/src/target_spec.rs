// #[path = "gen/target_spec.rs"]
// mod gen;

use std::collections::BTreeMap;

use duct::cmd;
use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use strum::{Display, IntoStaticStr};

// use self::gen::*;
use super::*;

pub fn gen() -> Result<()> {
    gen_target_spec()?;
    Ok(())
}

pub static TARGET_SPEC: Lazy<BTreeMap<String, TargetSpec>> =
    Lazy::new(|| target_spec_map().unwrap());

pub static TARGET_TIER: Lazy<TargetTier> = Lazy::new(|| target_tier().unwrap());

// creates a full list of target spec
fn gen_target_spec() -> Result<()> {
    let mut map = BTreeMap::new();
    // let mut target_os = BTreeSet::new();
    for triple in target_list()? {
        let text = target_spec_json(&triple)?;
        let value: serde_json::Value = serde_json::from_str(&text)?;
        // if let Some(v) = value.get("os") {
        //     let v = v.as_str().unwrap();
        //     if !target_os.contains(v) {
        //         target_os.insert(v.to_owned());
        //     }
        // }
        map.insert(triple, value);
    }
    write_json(root_dir().join("tools/target-spec.json"), &map)?;
    // target_os.insert("none".into());
    // gen_enums(["TargetOs"], [&target_os])?;
    Ok(())
}

// creates structured spec map
fn target_spec_map() -> Result<BTreeMap<String, TargetSpec>> {
    Ok(serde_json::from_slice(&fs::read(root_dir().join("tools/target-spec.json"))?)?)
}

/// Return a list of all built-in targets.
fn target_list() -> Result<Vec<String>> {
    Ok(cmd!("rustc", "--print", "target-list",)
        .read()?
        .split('\n')
        .filter(|s| !s.is_empty())
        .map(str::to_owned)
        .collect())
}

fn target_spec_json(target: &str) -> Result<String> {
    Ok(cmd!("rustc", "--print", "target-spec-json", "-Z", "unstable-options", "--target", &target)
        .read()?)
}

// fn gen_enums<const N: usize>(name: [&str; N], variants: [&BTreeSet<String>; N]) -> Result<()> {
//     let mut out = quote! {
//         use serde::{Serialize, Deserialize};
//         use strum::{Display, IntoStaticStr};
//     };
//     let attrs = quote! {
//         #[derive(
//             Debug, Clone, Copy, PartialEq, Eq,
//             Serialize, Deserialize,
//             Display, IntoStaticStr,
//         )]
//         #[allow(non_camel_case_types)]
//     };

//     for (name, variants) in name.iter().zip(variants) {
//         let name = format_ident!("{name}");
//         let variants = variants.iter().map(|v| format_ident!("{v}"));
//         out.extend(quote! {
//             #attrs
//             pub enum #name {
//                 #(#variants,)*
//             }
//         });
//     }

//     let outdir = &root_dir().join("tools/codegen/src/gen");
//     fs::create_dir_all(outdir)?;
//     write(outdir.join("target_spec.rs"), out)?;
//     Ok(())
// }

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
    // all target_arch: https://github.com/rust-lang/rust/blob/1.63.0/compiler/rustc_target/src/abi/call/mod.rs#L670-L728
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

#[derive(
    Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize, Display, IntoStaticStr,
)]
#[allow(non_camel_case_types)]
pub enum TargetEndian {
    big,
    #[default]
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

#[derive(
    Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize, Display, IntoStaticStr,
)]
#[allow(non_camel_case_types)]
pub enum TargetOs {
    aix,
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
    #[default]
    none,
    nto,
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
    watchos,
    windows,
    xous,
}
pub use TargetOs::*;

impl TargetOs {
    fn is_none(&self) -> bool {
        matches!(self, Self::none)
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
    Ok(serde_json::from_slice(&fs::read(root_dir().join("tools/target-tier.json"))?)?)
}
