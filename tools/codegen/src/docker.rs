use std::collections::{BTreeMap, BTreeSet};

use indoc::formatdoc;

use super::*;
use crate::target_spec::*;

const WASMTIME_VERSION: &str = "0.30.0";
const UBUNTU_VERSION: &str = "20.04";

static TARGETS: &[&str] = &[
    "aarch64-unknown-linux-gnu",
    "arm-unknown-linux-gnueabi",
    "arm-unknown-linux-gnueabihf",
    "armv5te-unknown-linux-gnueabi",
    "armv7-unknown-linux-gnueabi",
    "armv7-unknown-linux-gnueabihf",
    "i586-unknown-linux-gnu",
    "i686-unknown-linux-gnu",
    "mips-unknown-linux-gnu",
    "mips64-unknown-linux-gnuabi64",
    "mips64el-unknown-linux-gnuabi64",
    "mipsel-unknown-linux-gnu",
    "powerpc-unknown-linux-gnu",
    "powerpc64-unknown-linux-gnu",
    "powerpc64le-unknown-linux-gnu",
    "riscv64gc-unknown-linux-gnu",
    "s390x-unknown-linux-gnu",
    "sparc64-unknown-linux-gnu",
    "thumbv7neon-unknown-linux-gnueabihf",
    "wasm32-wasi",
    "x86_64-unknown-linux-gnu",
    "x86_64-unknown-linux-gnux32",
];

// TODO:
// https://github.com/rust-lang/rust/blob/f06f9bbd3a2b0a2781decd6163b14f71dd59bf7f/src/ci/docker/host-x86_64/dist-various-1/Dockerfile
// https://github.com/rust-lang/rust/blob/218a96cae06ed1a47549a81c09c3655fbcae1363/src/ci/docker/host-x86_64/dist-various-2/Dockerfile
// https://github.com/rust-lang/rust/blob/218a96cae06ed1a47549a81c09c3655fbcae1363/src/ci/docker/scripts/cross-apt-packages.sh
const APT_PACKAGES_COMMON: &[&str] = &[
    "ca-certificates",
    "file",
    "make",
    // "binutils",
    // "cmake",
    "curl",
    // "git",
    // "libtool",
    // "pkg-config",
    // "m4",
];

pub fn gen() -> Result<()> {
    let out_dir = &workspace_root().join("docker");

    let targets: BTreeSet<_> = TARGET_TIER
        .tier1
        .iter()
        .chain(&TARGET_TIER.tier2_host)
        .chain(&TARGET_TIER.tier2)
        .map(String::as_str)
        .filter(|&triple| !TARGETS.contains(&triple))
        .filter(|&triple| {
            let spec = &TARGET_SPEC[triple];
            spec.os == linux && spec.env.as_deref() == Some("gnu") || spec.os == wasi
        })
        .collect();
    eprintln!("missing arch: {}", serde_json::to_string_pretty(&targets).unwrap());

    for &triple in TARGETS {
        let out_dir = &out_dir.join(triple);
        fs::create_dir_all(out_dir)?;
        let dockerfile = dockerfile(triple)?;
        fs::write(
            out_dir.join("Dockerfile"),
            dockerfile.build(format!("ubuntu:{}", UBUNTU_VERSION)),
        )?;
    }

    Ok(())
}

impl TargetEndian {
    fn arch_suffix(&self, arch: TargetArch) -> &'static str {
        use TargetEndian::*;
        match (self, arch) {
            // armeb
            (big, arm) => "eb",
            // aarch64_be
            (big, aarch64) => "_be",
            // mipsel, mips64el
            (little, mips | mips64) => "el",
            // powerpc64le, ppc64le
            (little, powerpc64) => "le",
            _ => "",
        }
    }
}

fn gnu_linker_base_name(spec: &TargetSpec) -> String {
    format!(
        "{}{}-{}-{}{}",
        spec.arch,
        spec.target_endian.arch_suffix(spec.arch),
        spec.os,
        spec.env.as_deref().unwrap_or_default(),
        spec.abi.as_deref().unwrap_or_default(),
    )
}

fn libc_arch_name(spec: &TargetSpec) -> String {
    use TargetEndian::*;
    let arch_suffix = match (spec.target_endian, spec.arch) {
        // mipsel, mips64el, ppc64el
        (little, mips | mips64 | powerpc64 | arm) => "el",
        (little, _) | (big, mips | mips64 | powerpc | powerpc64 | s390x | sparc64) => "",
        _ => todo!("{:?}", spec),
    };

    let abi = spec.abi.as_deref().unwrap_or_default();
    match spec.arch {
        powerpc | s390x | riscv64 | sparc64 => spec.arch.to_string(),
        aarch64 => "arm64".into(),
        arm => {
            // arm, armel, armhf
            let abi = abi.strip_prefix("eabi").unwrap_or(abi);
            let suffix = if abi.is_empty() { arch_suffix } else { abi };
            format!("arm{}", suffix)
        }
        mips | mips64 => format!("{}{}", spec.arch, arch_suffix),
        powerpc64 => format!("{}{}", spec.arch.to_string().replace("powerpc", "ppc"), arch_suffix),
        _ => todo!("{}", spec.arch),
    }
}

fn qemu_arch_name(spec: &TargetSpec) -> String {
    match spec.arch {
        powerpc | powerpc64 => format!(
            "{}{}",
            spec.arch.to_string().replace("powerpc", "ppc"),
            spec.target_endian.arch_suffix(spec.arch)
        ),
        _ => format!("{}{}", spec.arch, spec.target_endian.arch_suffix(spec.arch)),
    }
}

fn dockerfile(triple: &'static str) -> Result<Dockerfile> {
    let mut dockerfile = Dockerfile::new();
    dockerfile.run_apt();
    dockerfile.new_line();

    let spec = &TARGET_SPEC[triple];
    let env_triple_lower = &*triple.replace('-', "_");
    let env_triple_upper = &*env_triple_lower.to_ascii_uppercase();

    for &p in APT_PACKAGES_COMMON {
        dockerfile.apt_install(p);
    }

    match spec.os {
        linux => {
            match spec.env.as_deref() {
                Some("gnu") => {
                    let libc = "libc6-dev";
                    dockerfile.apt_install("g++");
                    dockerfile.apt_install(libc);
                    if spec.arch == x86 || spec.arch == x86_64 {
                        dockerfile.apt_install("g++-multilib");
                    } else {
                        let linker_base_name = gnu_linker_base_name(spec);
                        let libc_arch_name = libc_arch_name(spec);
                        let qemu_arch_name = qemu_arch_name(spec);

                        let c_linker = &format!("{}-gcc", linker_base_name);
                        let cpp_linker = &format!("{}-g++", linker_base_name);
                        dockerfile.free_env(
                            format!("CARGO_TARGET_{}_LINKER", env_triple_upper),
                            c_linker,
                        );
                        dockerfile.free_env(format!("CC_{}", env_triple_lower), c_linker);
                        dockerfile.free_env(format!("CXX_{}", env_triple_lower), cpp_linker);
                        dockerfile.free_env("OBJDUMP", format!("{}-objdump", linker_base_name));

                        dockerfile.apt_install(format!("g++-{}", linker_base_name));
                        dockerfile.apt_install(format!("{}-{}-cross", libc, libc_arch_name));

                        dockerfile.apt_install("binfmt-support");
                        dockerfile.free_env("QEMU_LD_PREFIX", format!("/usr/{}", linker_base_name));
                        dockerfile.copy("qemu.sh", "/");
                        dockerfile.run(format!("/qemu.sh {}", qemu_arch_name));
                        // dockerfile.env("QEMU_VERSION", "6.1+dfsg-5");
                        // dockerfile.run(formatdoc!(
                        //     "
                        //     set -x && apt-get update && curl --retry 3 -LsSf \"http://ftp.debian.org/debian/pool/main/q/qemu/qemu-user-static_${{QEMU_VERSION}}_amd64.deb\" \\
                        //         | dpkg --fsys-tarfile - \\
                        //         | tar xvf - --wildcards ./usr/bin/qemu-{0}-static --strip-components=3 \\
                        //         && mv qemu-{0}-static /usr/bin/qemu-{0} \
                        //         && rm -rf /var/lib/apt/lists/*
                        //     ",
                        //     qemu_arch_name
                        // ));

                        // dockerfile.apt_install("qemu-user");
                        let mut qemu_cpu = None; // run `qemu-system-x -cpu help` for list
                        match spec.arch {
                            x86 | x86_64 => unreachable!(),
                            arm  => {
                                //if triple.starts_with("thumbv7neon") {
                                    qemu_cpu = Some("cortex-a8");
                                //}
                            }
                            aarch64 | s390x | riscv64=>{}
                            mips => {
                                // ubuntu's qemu-system-mips package contains qemu-system-mipsel
                                // dockerfile.apt_install(format!("qemu-system-{}", spec.arch));
                            }
                            mips64 => {
                                // qemu triggering a SIGILL on MSA intrinsics if the cpu target is not defined.
                                qemu_cpu = Some("Loongson-3A4000");
                                // dockerfile.apt_install(format!("qemu-system-{}", qemu_arch_name));
                            }
                            sparc64 => {
                                // dockerfile.apt_install(format!("qemu-system-{}", qemu_arch_name));
                            }
                            powerpc | powerpc64 => {
                                // dockerfile.apt_install("qemu-system-ppc");
                                if spec.arch == powerpc64 {
                                    // qemu triggering a SIGILL on vec_subs if the cpu target is not defined.
                                    // https://github.com/rust-lang/stdarch/blob/abd53c913874d1fa7e0d3fb29044392b13c23397/ci/docker/powerpc64le-unknown-linux-gnu/Dockerfile#L8
                                    qemu_cpu = Some("power9")
                                } else {
                                    // https://github.com/rust-lang/stdarch/pull/447
                                    qemu_cpu = Some("Vger")
                                }
                            }
                            _ => todo!(),
                        }

                        let runner = if let Some(cpu) = qemu_cpu {
                            format!("qemu-{} -cpu {}", qemu_arch_name, cpu)
                        } else {
                            format!("qemu-{}", qemu_arch_name)
                        };
                        dockerfile
                            .free_env(format!("CARGO_TARGET_{}_RUNNER", env_triple_upper), runner);
                    }
                }
                _ => todo!(),
            }
        }
        wasi => {
            dockerfile.apt_install("clang");

            dockerfile.env("WASMTIME_VERSION", WASMTIME_VERSION);
            dockerfile.run_curl("https://github.com/bytecodealliance/wasmtime/releases/download/v$WASMTIME_VERSION/wasmtime-v$WASMTIME_VERSION-x86_64-linux.tar.xz");
            dockerfile.path("/wasmtime-v$WASMTIME_VERSION-x86_64-linux");
            dockerfile.free_env(
                format!("CARGO_TARGET_{}_RUNNER", env_triple_upper),
                "wasmtime --enable-simd --enable-threads --",
            );
        }
        _ => todo!("{}", triple),
    }

    Ok(dockerfile)
}

// Dockerfile builder
//
// See also:
// - https://docs.docker.com/engine/reference/builder
// - https://docs.docker.com/develop/develop-images/dockerfile_best-practices
#[derive(Debug, Default)]
struct Dockerfile {
    instructions: Vec<Instruction>,
    apt_packages: BTreeSet<String>,
    free_env: Vec<(String, String)>,
}

impl Dockerfile {
    fn new() -> Self {
        let mut this = Self::default();
        this.comment(header("#", true));
        this.instructions.push(Instruction::Base);
        this.new_line();
        this
    }
    fn comment(&mut self, comment: impl Into<String>) {
        self.instructions.push(Instruction::Comment(comment.into()));
    }
    fn copy(&mut self, from: impl Into<String>, to: impl Into<String>) {
        self.instructions.push(Instruction::Copy(from.into(), to.into()));
    }
    fn run(&mut self, command: impl Into<String>) {
        self.instructions.push(Instruction::Run(command.into()));
    }
    fn run_curl(&mut self, url: impl AsRef<str>) {
        let url = url.as_ref();
        let pipe = if url.ends_with(".tar.xz") {
            self.apt_install("xz-utils");
            " | tar xJf -"
        } else if url.ends_with(".tar.bz2") {
            self.apt_install("bzip2");
            " | tar xjf -"
        } else if url.ends_with(".tar.gz") {
            " | tar xzf -"
        } else {
            todo!()
        };
        self.run(format!("curl --retry 3 -LsSf {}{}", url, pipe));
    }
    fn run_apt(&mut self) {
        self.instructions.push(Instruction::RunApt);
    }
    // See also https://packages.ubuntu.com/en
    fn apt_install(&mut self, package: impl Into<String>) {
        self.apt_packages.insert(package.into());
    }
    fn env(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.instructions.push(Instruction::Env(key.into(), value.into()));
    }
    fn path(&mut self, path: impl AsRef<str>) {
        self.env("PATH", format!("{}:$PATH", path.as_ref()));
    }
    fn free_env(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.free_env.push((key.into(), value.into()));
    }
    fn new_line(&mut self) {
        self.instructions.push(Instruction::NewLine);
    }
    fn build(&self, base: impl AsRef<str>) -> String {
        let fill_env = |buf: &mut String, env: &mut BTreeMap<&String, &String>| {
            let mut first = true;
            while let Some((key, value)) = env.pop_first() {
                if first {
                    first = false;
                    *buf += "ENV "
                } else {
                    *buf += "    "
                }
                *buf += &if value.contains(' ') {
                    // TODO: more accurate escape
                    format!("{}=\"{}\" \\\n", key, value)
                } else {
                    format!("{}={} \\\n", key, value)
                };
            }
            if !first {
                buf.pop(); // '\n'
                buf.pop(); // '\\'
                buf.pop(); // ' '
                *buf += "\n";
            }
        };

        let mut buf = String::new();
        let mut env = BTreeMap::new();
        for instruction in &self.instructions {
            match instruction {
                Instruction::Env(key, value) => {
                    env.insert(key, value);
                }
                Instruction::Base => {
                    Instruction::From(base.as_ref().to_owned()).write(&mut buf);
                }
                Instruction::RunApt => {
                    let apt_packages = self
                        .apt_packages
                        .iter()
                        .map(String::as_str)
                        .intersperse(" \\\n        ")
                        .collect::<String>();
                    Instruction::Run(formatdoc!(
                        "
                        apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \\
                                {} \\
                            && rm -rf /var/lib/apt/lists/*
                        ",
                        apt_packages
                    )).write(&mut buf);
                }
                _ => {
                    fill_env(&mut buf, &mut env);
                    instruction.write(&mut buf);
                }
            }
        }
        fill_env(&mut buf, &mut env);
        Instruction::NewLine.write(&mut buf);
        for (key, value) in &self.free_env {
            env.insert(key, value);
        }
        fill_env(&mut buf, &mut env);
        while buf.ends_with("\n\n") {
            buf.pop();
        }
        buf
    }
}

// Dockerfile instruction
#[derive(Debug)]
enum Instruction {
    Copy(String, String),
    Env(String, String),
    From(String),
    Run(String),

    // The following are aliases of other instructions, not the actual instructions.
    RunApt,

    // The following are options that affect the the format of the output Dockerfile,
    // not the actual instructions.
    Comment(String),
    Base,
    NewLine,
}

impl Instruction {
    fn write(&self, buf: &mut String) {
        match self {
            Instruction::From(from) => {
                *buf += &format!("FROM {}\n", from);
            }
            Instruction::Run(command) => {
                *buf += &format!("RUN {}\n", command);
            }
            Instruction::Copy(from, to) => {
                *buf += &format!("COPY {} {}\n", from, to);
            }
            Instruction::NewLine => {
                while buf.ends_with("\n\n\n") {
                    buf.pop();
                }
                if !buf.ends_with("\n\n") {
                    *buf += "\n";
                }
            }
            Instruction::Comment(s) => {
                for s in s.strip_suffix('\n').unwrap_or(s).lines() {
                    if s.is_empty() || s == "#" {
                        *buf += "#\n";
                        continue;
                    }
                    if !s.starts_with("# ") {
                        *buf += "# ";
                    }
                    *buf += s;
                    *buf += "\n";
                }
                if s.ends_with('\n') {
                    *buf += "\n";
                }
            }
            _ => unreachable!(),
        }
    }
}
