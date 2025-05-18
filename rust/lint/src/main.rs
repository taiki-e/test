// SPDX-License-Identifier: Apache-2.0 OR MIT

use std::{env, fs, path::Path, process::Command};

fn main() {
    let output = Command::new("rustc").args(["-W", "help"]).output().unwrap();
    let new = str::from_utf8(&output.stdout).unwrap();
    let manifest_dir = Path::new(env!("CARGO_MANIFEST_DIR"));
    let expected_path = &manifest_dir.join("lint.txt");
    fs::write(expected_path, new).unwrap();
}
