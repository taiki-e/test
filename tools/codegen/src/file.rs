use std::path::{Path, PathBuf};

use anyhow::Result;
use fs_err as fs;
use serde::Serialize;

pub fn root_dir() -> PathBuf {
    let mut dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    dir.pop(); // codegen
    dir.pop(); // tools
    dir
}

pub fn write_json(path: impl AsRef<Path>, value: &impl Serialize) -> Result<()> {
    let path = path.as_ref();
    let mut out = serde_json::to_vec_pretty(value)?;
    out.push(b'\n'); // insert_final_newline
    if path.is_file() && fs::read(&path)? == out {
        return Ok(());
    }
    fs::write(path, out)?;
    Ok(())
}
