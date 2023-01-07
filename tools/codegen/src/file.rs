use std::path::{Path, PathBuf};

use anyhow::Result;
use fs_err as fs;
use serde::Serialize;

pub fn workspace_root() -> PathBuf {
    let mut dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    dir.pop(); // codegen
    dir.pop(); // tools
    dir
}

pub fn write_json(path: impl AsRef<Path>, value: &impl Serialize) -> Result<()> {
    let mut out = serde_json::to_vec_pretty(value)?;
    out.push(b'\n'); // insert_final_newline
    write(path.as_ref(), out)
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
