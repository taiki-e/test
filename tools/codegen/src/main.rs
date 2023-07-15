#![warn(rust_2018_idioms, single_use_lifetimes)]
#![allow(
    clippy::single_match,
    clippy::too_many_arguments,
    clippy::trivially_copy_pass_by_ref,
    clippy::type_complexity
)]

mod file;
mod target_spec;

use anyhow::Result;

use crate::file::*;

fn main() -> Result<()> {
    target_spec::gen()?;

    Ok(())
}
