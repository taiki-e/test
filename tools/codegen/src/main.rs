// SPDX-License-Identifier: Apache-2.0 OR MIT

#![allow(clippy::trivially_copy_pass_by_ref, clippy::wildcard_imports)]

mod file;
mod target_spec;

use anyhow::Result;

use crate::file::*;

fn main() -> Result<()> {
    target_spec::gen()?;

    Ok(())
}
