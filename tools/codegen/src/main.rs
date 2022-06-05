#![warn(rust_2018_idioms, single_use_lifetimes)]
#![allow(
    clippy::single_match,
    clippy::too_many_arguments,
    clippy::trivially_copy_pass_by_ref,
    clippy::type_complexity
)]
#![feature(map_first_last)]

mod file;
mod target_spec;

use anyhow::Result;
use fs_err as fs;
use once_cell::sync::Lazy;

use crate::file::*;

fn main() -> Result<()> {
    target_spec::gen()?;
    Lazy::force(&target_spec::TARGET_SPEC);
    Lazy::force(&target_spec::TARGET_TIER);

    Ok(())
}
