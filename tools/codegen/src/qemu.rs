use std::collections::BTreeMap;

use anyhow::Result;
use duct::cmd;
use semver::Version;

use super::*;

const QEMU_VERSION: Version = Version::new(6, 1, 0);

const QEMU_BIN: &[&str] = &[
    "qemu-system-aarch64",
    // "qemu-system-alpha",
    "qemu-system-arm",
    // "qemu-system-avr",
    // "qemu-system-cris",
    // "qemu-system-hppa",
    // "qemu-system-i386",
    // "qemu-system-m68k",
    // "qemu-system-microblaze",
    // "qemu-system-microblazeel",
    "qemu-system-mips",
    "qemu-system-mips64",
    "qemu-system-mips64el",
    "qemu-system-mipsel",
    // "qemu-system-nios2",
    // "qemu-system-or1k",
    "qemu-system-ppc",
    "qemu-system-ppc64",
    // "qemu-system-riscv32",
    "qemu-system-riscv64",
    // "qemu-system-rx",
    "qemu-system-s390x",
    // "qemu-system-sh4",
    // "qemu-system-sh4eb",
    // "qemu-system-sparc",
    // "qemu-system-sparc64",
    // "qemu-system-tricore",
    "qemu-system-x86_64",
    // "qemu-system-xtensa",
    // "qemu-system-xtensaeb",
];

pub fn gen() -> Result<()> {
    let version = cmd!("qemu-system-x86_64", "--version").read()?;
    let version: Version =
        version.lines().find_map(|s| s.strip_prefix("QEMU emulator version ")).unwrap().parse()?;
    if version != QEMU_VERSION {
        eprintln!("warning: expected qemu version {}, but found {}", QEMU_VERSION, version);
    }

    let mut map = BTreeMap::new();

    for &qemu_system in QEMU_BIN {
        let mut cpus = BTreeMap::new();
        let arch = qemu_system.strip_prefix("qemu-system-").unwrap();
        let text = cmd!(qemu_system, "-cpu", "help").read()?;

        match arch {
            "aarch64" | "arm" | "riscv64" => {
                let prefix = match arch {
                    "aarch64" | "arm" => "  ",
                    "riscv64" => "",
                    _ => unreachable!(),
                };
                for s in text.lines() {
                    if let Some(s) = s.strip_prefix(prefix) {
                        cpus.insert(s.to_owned(), "".to_owned());
                    }
                }
            }
            "x86_64" | "ppc" | "ppc64" | "s390x" => {
                let prefix = match arch {
                    "x86_64" => "x86 ",
                    "ppc" | "ppc64" => "PowerPC ",
                    "s390x" => "s390 ",
                    _ => unreachable!(),
                };
                for s in text.lines() {
                    if let Some(s) = s.strip_prefix(prefix) {
                        let (name, desc) = s.split_once(" ").unwrap();
                        cpus.insert(name.to_owned(), desc.trim().to_owned());
                    }
                }
            }
            "mips" | "mipsel" | "mips64" | "mips64el" => {
                for s in text.lines() {
                    if let Some(s) = s.strip_prefix("MIPS '") {
                        cpus.insert(s.strip_suffix('\'').unwrap().to_owned(), "".to_owned());
                    }
                }
            }
            _ => {
                eprintln!("`{} -cpu help`:\n{}", qemu_system, text);
                todo!()
            }
        }

        for k in cpus.keys() {
            assert!(!k.contains(char::is_whitespace));
        }
        map.insert(arch, cpus);
    }

    write_json(root_dir().join("tools/qemu-cpu.json"), &map)?;
    Ok(())
}
