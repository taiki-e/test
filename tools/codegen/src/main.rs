#![warn(rust_2018_idioms, single_use_lifetimes)]
#![allow(clippy::single_match, clippy::too_many_arguments, clippy::type_complexity)]
#![feature(map_first_last)]

mod docker;
mod file;
mod qemu;
mod target_spec;

use std::env;

use anyhow::Result;
use clap::{ArgEnum, Clap};
use fs_err as fs;
use once_cell::sync::Lazy;

use crate::file::*;

#[derive(Clap)]
struct Args {
    #[clap(arg_enum)]
    operations: Vec<Operations>,
}

#[derive(Debug, PartialEq, Eq, ArgEnum)]
enum Operations {
    All,
    TargetSpec,
    Docker,
    Qemu,
}

fn main() -> Result<()> {
    let mut args = Args::parse();
    let is_ci = env::var_os("CI").is_some();
    if is_ci || args.operations.contains(&Operations::All) {
        for &v in Operations::VARIANTS {
            args.operations.push(Operations::from_str(v, false).unwrap());
        }
    } else if args.operations.is_empty() {
        args.operations.push(Operations::Docker);
    }

    if args.operations.contains(&Operations::TargetSpec) {
        target_spec::gen()?;
    }
    Lazy::force(&target_spec::TARGET_SPEC);
    Lazy::force(&target_spec::TARGET_TIER);

    if args.operations.contains(&Operations::Docker) {
        docker::gen()?;
    }
    if args.operations.contains(&Operations::Qemu) {
        qemu::gen()?;
    }

    Ok(())
}
