// SPDX-License-Identifier: Apache-2.0 OR MIT

use std::path::{Path, PathBuf};

use anyhow::Result;
use fs_err as fs;

pub fn workspace_root() -> PathBuf {
    let mut dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    dir.pop(); // codegen
    dir.pop(); // tools
    dir
}

pub fn write(path: impl AsRef<Path>, out: impl AsRef<[u8]>) -> Result<()> {
    let path = path.as_ref();
    let out = out.as_ref();
    if path.is_file() && fs::read(path)? == out {
        return Ok(());
    }
    fs::write(path, out)?;
    Ok(())
}
