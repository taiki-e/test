// use std::process::Command;
use xarch_test::process::Command;

#[test]
fn test() {
    assert!(dbg!(Command::new(dbg!(env!("CARGO_BIN_EXE_test"))).status().unwrap()).success());
}
