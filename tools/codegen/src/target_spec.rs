use std::{collections::BTreeMap, sync::OnceLock};

use duct::cmd;
use serde::{Deserialize, Serialize};

use super::*;

#[path = "gen/target_spec.rs"]
mod gen;
pub use gen::*;

pub fn gen() -> Result<()> {
    gen_target_spec()?;
    Ok(())
}

pub fn target_spec() -> &'static BTreeMap<String, TargetSpec> {
    static TARGET_SPEC: OnceLock<BTreeMap<String, TargetSpec>> = OnceLock::new();
    TARGET_SPEC.get_or_init(|| target_spec_map().unwrap())
}

// creates a full list of target spec
fn gen_target_spec() -> Result<()> {
    let mut cfgs = Vec::new();
    for triple in target_list()? {
        cfgs.append(&mut format!("{triple}:\n").into_bytes());
        let cfg_list = cfg_list(&triple)?;
        cfgs.extend(cfg_list.replace("debug_assertions\n", "").replace("\\\\", "\\").into_bytes());
        cfgs.push(b'\n');
        cfgs.push(b'\n');
    }
    write(workspace_root().join("tools/cfg"), &cfgs)?;
    Ok(())
}

// creates structured spec map
fn target_spec_map() -> Result<BTreeMap<String, TargetSpec>> {
    Ok(serde_json::from_slice(&fs::read(workspace_root().join("tools/target-spec.json"))?)?)
}

/// Return a list of all built-in targets.
fn target_list() -> Result<Vec<String>> {
    Ok(cmd!("rustc", "--print", "target-list")
        .read()?
        .split('\n')
        .filter(|s| !s.is_empty())
        .map(str::to_owned)
        .collect())
}

fn cfg_list(target: &str) -> Result<String> {
    Ok(cmd!("rustc", "--print", "cfg", "--target", &target).read()?)
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct TargetSpec {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub abi: Option<String>,
    pub arch: TargetArch,
    #[serde(default, skip_serializing_if = "TargetEnv::is_none")]
    pub env: TargetEnv,
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

pub fn target_tier() -> Result<TargetTier> {
    Ok(serde_json::from_slice(&fs::read(workspace_root().join("tools/target-tier.json"))?)?)
}
