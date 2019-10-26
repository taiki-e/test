#![forbid(unsafe_code)]
#![warn(rust_2018_idioms, single_use_lifetimes, unreachable_pub)]
#![warn(clippy::all)]

use std::{
    collections::HashSet,
    env, fs,
    io::{self, Write},
    process::Command,
};

type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;

const USAGE: &str = "\
USAGE:
    ci-tools [SUBCOMMAND]

SUBCOMMANDS:
    remove-dev-deps <PATH>...\t\
        Remove dev-dependencies from passed Cargo.toml
    fmt <PATH>...\t\
        Run `cargo fmt` for passed Cargo.toml
";

fn main() {
    match try_main() {
        Ok(code) => std::process::exit(code),
        Err(e) => {
            eprintln!("{}", e);
            std::process::exit(1)
        }
    }
}

fn try_main() -> Result<i32> {
    let mut options = HashSet::new();
    #[allow(clippy::unnecessary_filter_map)]
    let args: Vec<String> = env::args()
        .skip(1)
        .filter_map(|arg| {
            if arg.starts_with("--") {
                options.insert(arg);
                None
            } else {
                Some(arg)
            }
        })
        .collect();

    if args.is_empty() || args[0] == "help" || options.contains("--help") {
        println!("{}", USAGE);
        return Ok(0);
    }

    let subcmd = &*args[0];
    let args = &args[1..];

    match subcmd {
        "remove-dev-deps" => remove_dev_deps(args),
        "fmt" => {
            if options.contains("--check") {
                check_fmt(args)
            } else {
                run_fmt(args)
            }
        }
        _ => Ok(0),
    }
}

fn remove_dev_deps(files: &[String]) -> Result<i32> {
    for file in files {
        let content = fs::read_to_string(file)?;
        let mut doc: toml_edit::Document = content.parse()?;
        let table = doc.as_table_mut();
        table.remove("dev-dependencies");
        if let Some(table) = table.entry("target").as_table_mut() {
            let keys: Vec<String> = table.iter().map(|(key, _)| key.to_string()).collect();
            for key in keys {
                if let Some(table) = table.entry(&key).as_table_mut() {
                    table.remove("dev-dependencies");
                }
            }
        }
        fs::write(file, doc.to_string_in_original_order())?;
    }
    Ok(0)
}

fn check_fmt(files: &[String]) -> Result<i32> {
    cargo_fmt(files, |cmd| cmd.arg("--").arg("--check"))
}

fn run_fmt(files: &[String]) -> Result<i32> {
    cargo_fmt(files, |cmd| cmd)
}

fn cargo_fmt(files: &[String], f: fn(&mut Command) -> &mut Command) -> Result<i32> {
    for file in files {
        let output = f(Command::new("cargo").arg("fmt").arg("--manifest-path").arg(file))
            .output()
            .expect("failed to run: cargo fmt");
        if !output.status.success() {
            io::stdout().lock().write_all(&output.stdout)?;
            io::stderr().lock().write_all(&output.stderr)?;
            return Ok(1);
        }
    }
    Ok(0)
}
