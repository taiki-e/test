#![doc(test(
    no_crate_inject,
    attr(
        deny(warnings, rust_2018_idioms, single_use_lifetimes),
        allow(dead_code, unused_variables)
    )
))]
#![warn(
    missing_copy_implementations,
    missing_debug_implementations,
    rust_2018_idioms,
    single_use_lifetimes,
    unreachable_pub,
    unsafe_op_in_unsafe_fn
)]
#![cfg_attr(docsrs, feature(doc_cfg))]

use std::env;

use once_cell::sync::Lazy;

const TARGET: Option<&str> = include!(concat!(env!("OUT_DIR"), "/target"));
static RUNNER: Lazy<Option<Vec<String>>> = Lazy::new(|| {
    let target = TARGET?;
    let runner: Vec<_> =
        env::var(format!("CARGO_TARGET_{}_RUNNER", target.replace('-', "_").to_ascii_uppercase()))
            .ok()?
            .split(' ')
            .filter(|s| !s.is_empty())
            .map(str::to_owned)
            .collect();
    if runner.is_empty() {
        None
    } else {
        Some(runner)
    }
});

pub mod process {
    #[cfg(unix)]
    use std::os::unix::process::CommandExt;
    #[cfg(windows)]
    use std::os::windows::process::CommandExt;
    #[doc(no_inline)]
    pub use std::process::{
        abort, exit, id, Child, ChildStderr, ChildStdin, ChildStdout, ExitStatus, Output, Stdio,
    };
    use std::{ffi::OsStr, io, path::Path};

    #[derive(Debug)]
    pub struct Command(std::process::Command);

    impl Command {
        pub fn new<S: AsRef<OsStr>>(program: S) -> Self {
            match &*crate::RUNNER {
                Some(runner) => {
                    let mut cmd = Self(std::process::Command::new(&runner[0]));
                    cmd.args(&runner[1..]);
                    cmd.arg(program.as_ref());
                    cmd
                }
                None => Self(std::process::Command::new(program.as_ref())),
            }
        }

        pub fn arg<S: AsRef<OsStr>>(&mut self, arg: S) -> &mut Self {
            self.0.arg(arg.as_ref());
            self
        }

        pub fn args<I, S>(&mut self, args: I) -> &mut Self
        where
            I: IntoIterator<Item = S>,
            S: AsRef<OsStr>,
        {
            self.0.args(args);
            self
        }

        pub fn env<K, V>(&mut self, key: K, val: V) -> &mut Self
        where
            K: AsRef<OsStr>,
            V: AsRef<OsStr>,
        {
            self.0.env(key.as_ref(), val.as_ref());
            self
        }

        pub fn envs<I, K, V>(&mut self, vars: I) -> &mut Command
        where
            I: IntoIterator<Item = (K, V)>,
            K: AsRef<OsStr>,
            V: AsRef<OsStr>,
        {
            self.0.envs(vars);
            self
        }

        pub fn env_remove<K: AsRef<OsStr>>(&mut self, key: K) -> &mut Command {
            self.0.env_remove(key.as_ref());
            self
        }

        pub fn env_clear(&mut self) -> &mut Command {
            self.0.env_clear();
            self
        }

        pub fn current_dir<P: AsRef<Path>>(&mut self, dir: P) -> &mut Command {
            self.0.current_dir(dir.as_ref());
            self
        }

        pub fn stdin<T: Into<Stdio>>(&mut self, cfg: T) -> &mut Command {
            self.0.stdin(cfg.into());
            self
        }

        pub fn stdout<T: Into<Stdio>>(&mut self, cfg: T) -> &mut Command {
            self.0.stdout(cfg.into());
            self
        }

        pub fn stderr<T: Into<Stdio>>(&mut self, cfg: T) -> &mut Command {
            self.0.stderr(cfg.into());
            self
        }

        pub fn spawn(&mut self) -> io::Result<Child> {
            self.0.spawn()
        }

        pub fn output(&mut self) -> io::Result<Output> {
            self.0.output()
        }

        pub fn status(&mut self) -> io::Result<ExitStatus> {
            self.0.status()
        }
    }

    impl From<Command> for std::process::Command {
        fn from(cmd: Command) -> Self {
            cmd.0
        }
    }

    impl From<std::process::Command> for Command {
        fn from(cmd: std::process::Command) -> Self {
            Self(cmd)
        }
    }

    #[cfg(unix)]
    impl Command {
        pub fn uid(&mut self, id: u32) -> &mut Command {
            self.0.uid(id as _);
            self
        }

        pub fn gid(&mut self, id: u32) -> &mut Command {
            self.0.gid(id as _);
            self
        }

        pub unsafe fn pre_exec<F>(&mut self, f: F) -> &mut Command
        where
            F: FnMut() -> io::Result<()> + Send + Sync + 'static,
        {
            // SAFETY: the safety contract must be upheld by the caller.
            unsafe {
                self.0.pre_exec(f);
            }
            self
        }

        pub fn exec(&mut self) -> io::Error {
            self.0.exec()
        }

        pub fn arg0<S>(&mut self, arg: S) -> &mut Command
        where
            S: AsRef<OsStr>,
        {
            self.0.arg0(arg.as_ref());
            self
        }
    }

    #[cfg(windows)]
    impl Command {
        fn creation_flags(&mut self, flags: u32) -> &mut Command {
            self.0.creation_flags(flags);
            self
        }
    }
}
