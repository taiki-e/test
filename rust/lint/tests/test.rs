use std::{env, fs, path::Path, process::Command, str};

use tempfile::Builder;

#[rustversion::attr(before(2021-02-07), ignore)] // Note: This date is commit-date and the day before the toolchain date.
#[test]
fn check_lint_list() {
    let rustc = env::var_os("RUSTC").unwrap_or_else(|| "rustc".into());
    let output = Command::new(rustc).args(&["-W", "help"]).output().unwrap();
    let new = str::from_utf8(&output.stdout).unwrap();
    assert_diff("lint.txt", new);
}

#[track_caller]
fn assert_diff(expected_path: impl AsRef<Path>, actual: impl AsRef<str>) {
    let actual = actual.as_ref();
    let manifest_dir = Path::new(env!("CARGO_MANIFEST_DIR"));
    let expected_path = &manifest_dir.join(expected_path);
    (|| -> Result<(), Box<dyn std::error::Error>> {
        let expected = fs::read_to_string(expected_path)?;
        if expected != actual {
            if env::var_os("CI").is_some() {
                let outdir = Builder::new().prefix("assert_diff").tempdir()?;
                let actual_path = &outdir.path().join(expected_path.file_name().unwrap());
                fs::write(actual_path, actual)?;
                let status = Command::new("git")
                    .args(&["--no-pager", "diff", "--no-index", "--"])
                    .args(&[expected_path, actual_path])
                    .status()?;
                assert!(!status.success());
                panic!("assertion failed");
            } else {
                fs::write(expected_path, actual)?;
            }
        }
        Ok(())
    })()
    .unwrap_or_else(|e| panic!("{}", e))
}
