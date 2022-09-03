use std::{env, fs, path::Path, process::Command, str};

fn main() {
    let rustc = env::var_os("RUSTC").unwrap_or_else(|| "rustc".into());
    let output = Command::new(rustc).args(["-W", "help"]).output().unwrap();
    let new = str::from_utf8(&output.stdout).unwrap();
    let manifest_dir = Path::new(env!("CARGO_MANIFEST_DIR"));
    let expected_path = &manifest_dir.join("lint.txt");
    fs::write(expected_path, new).unwrap();
}
