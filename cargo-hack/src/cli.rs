use std::{env, fmt, iter::Peekable, mem};

use anyhow::{bail, format_err, Error, Result};

use crate::{rustup, term, Cargo, Feature, Rustup};

pub(crate) struct Args<'a> {
    pub(crate) leading_args: Vec<&'a str>,
    pub(crate) trailing_args: &'a [String],

    pub(crate) subcommand: Option<&'a str>,

    /// --manifest-path <PATH>
    pub(crate) manifest_path: Option<&'a str>,
    /// -p, --package <SPEC>...
    pub(crate) package: Vec<&'a str>,
    /// --exclude <SPEC>...
    pub(crate) exclude: Vec<&'a str>,
    /// --workspace, (--all)
    pub(crate) workspace: bool,
    /// --each-feature
    pub(crate) each_feature: bool,
    /// --feature-powerset
    pub(crate) feature_powerset: bool,
    /// --no-dev-deps
    pub(crate) no_dev_deps: bool,
    /// --remove-dev-deps
    pub(crate) remove_dev_deps: bool,
    /// --ignore-private
    pub(crate) ignore_private: bool,
    /// --ignore-unknown-features
    pub(crate) ignore_unknown_features: bool,
    /// --clean-per-run
    pub(crate) clean_per_run: bool,
    /// --clean-per-version
    pub(crate) clean_per_version: bool,
    /// --version-range and --version-step
    pub(crate) version_range: Option<Vec<String>>,

    // options for --each-feature and --feature-powerset
    /// --optional-deps [DEPS]...
    pub(crate) optional_deps: Option<Vec<&'a str>>,
    /// --include-features
    pub(crate) include_features: Vec<Feature>,
    /// --include-deps-features
    pub(crate) include_deps_features: bool,

    // Note: These values are not always exactly the same as the input.
    // Error messages should not assume that these options have been specified.
    /// --exclude-features <FEATURES>..., --skip <FEATURES>...
    pub(crate) exclude_features: Vec<&'a str>,
    /// --exclude-no-default-features
    pub(crate) exclude_no_default_features: bool,
    /// --exclude-all-features
    pub(crate) exclude_all_features: bool,

    // options for --feature-powerset
    /// --depth <NUM>
    pub(crate) depth: Option<usize>,
    /// --group-features <FEATURES>...
    pub(crate) group_features: Vec<Feature>,

    // options that will be propagated to cargo
    /// --features <FEATURES>...
    pub(crate) features: Vec<&'a str>,

    // propagated (as a part of leading_args) to cargo
    /// --no-default-features
    pub(crate) no_default_features: bool,
    /// -v, --verbose, -vv
    pub(crate) verbose: bool,
    // Note: specifying multiple `--target` flags requires unstable `-Zmultitarget`,
    // so cargo-hack currently only supports a single `--target`.
    /// --target <TRIPLE>...
    pub(crate) target: Option<&'a str>,
}

pub(crate) fn raw() -> RawArgs {
    let mut args = env::args();
    let _ = args.next(); // executable name
    RawArgs(args.collect())
}

pub(crate) struct RawArgs(Vec<String>);

pub(crate) fn parse_args<'a>(raw: &'a RawArgs, cargo: &Cargo, rustup: &Rustup) -> Result<Args<'a>> {
    let mut iter = raw.0.iter();
    let args = &mut iter.by_ref().map(String::as_str).peekable();
    match args.next() {
        Some(a) if a == "hack" => {}
        Some(a) => mini_usage(&format!("expected subcommand 'hack', found argument '{}'", a))?,
        None => {
            println!("{}", Help::short());
            std::process::exit(1);
        }
    }

    let mut leading = Vec::new();
    let mut subcommand: Option<&'a str> = None;

    let mut manifest_path = None;
    let mut color = None;

    let mut package = Vec::new();
    let mut exclude = Vec::new();
    let mut features = Vec::new();

    let mut workspace = None;
    let mut no_dev_deps = false;
    let mut remove_dev_deps = false;
    let mut each_feature = false;
    let mut feature_powerset = false;
    let mut ignore_private = false;
    let mut ignore_unknown_features = false;
    let mut clean_per_run = false;
    let mut clean_per_version = false;
    let mut version_range = None;
    let mut version_step = None;

    let mut optional_deps = None;
    let mut include_features = Vec::new();
    let mut include_deps_features = false;

    let mut exclude_features = Vec::new();
    let mut exclude_no_default_features = false;
    let mut exclude_all_features = false;

    let mut group_features = Vec::new();
    let mut depth = None;

    let mut verbose = false;
    let mut no_default_features = false;
    let mut all_features = false;
    let mut target = None;

    let res = (|| -> Result<()> {
        while let Some(arg) = args.next() {
            // stop at `--`
            // 1. `cargo hack check --no-dev-deps`
            //   first:  `cargo hack check --no-dev-deps` (filtered and passed to `cargo`)
            //   second: (empty)
            // 2. `cargo hack test --each-feature -- --ignored`
            //   first:  `cargo hack test --each-feature` (filtered and passed to `cargo`)
            //   second: `--ignored` (passed directly to `cargo` with `--`)
            if arg == "--" {
                break;
            }

            if !arg.starts_with('-') {
                subcommand.get_or_insert(arg);
                leading.push(arg);
                continue;
            }

            macro_rules! parse_opt {
                ($opt:ident, $propagate:expr, $pat:expr $(,)?) => {
                    if let Some(val) = parse_opt(arg, args, subcommand, $pat, true)? {
                        let val = val.unwrap();
                        if $opt.is_some() {
                            multi_arg($pat, subcommand)?;
                        }
                        $opt = Some(val);
                        if $propagate {
                            leading.push($pat);
                            leading.push(val);
                        }
                        continue;
                    }
                };
            }

            macro_rules! parse_multi_opt {
                ($v:ident, $allow_split:expr, $pat:expr $(,)?) => {
                    if let Some(val) = parse_opt(arg, args, subcommand, $pat, true)? {
                        let val = val.unwrap();
                        if $allow_split {
                            if val.contains(',') {
                                $v.extend(val.split(','));
                            } else {
                                $v.extend(val.split(' '));
                            }
                        } else {
                            $v.push(val);
                        }
                        continue;
                    }
                };
            }

            macro_rules! parse_flag {
                ($flag:ident) => {
                    if mem::replace(&mut $flag, true) {
                        multi_arg(&arg, subcommand)?;
                    } else {
                        continue;
                    }
                };
            }

            parse_opt!(manifest_path, false, "--manifest-path");
            parse_opt!(depth, false, "--depth");
            parse_opt!(color, true, "--color");
            parse_opt!(version_range, false, "--version-range");
            parse_opt!(version_step, false, "--version-step");
            parse_opt!(target, true, "--target");

            parse_multi_opt!(package, false, "--package");
            parse_multi_opt!(package, false, "-p");
            parse_multi_opt!(exclude, false, "--exclude");
            parse_multi_opt!(features, true, "--features");
            parse_multi_opt!(exclude_features, true, "--skip");
            parse_multi_opt!(exclude_features, true, "--exclude-features",);
            parse_multi_opt!(include_features, true, "--include-features",);
            parse_multi_opt!(group_features, false, "--group-features",);

            if let Some(val) = parse_opt(arg, args, subcommand, "--optional-deps", false)? {
                if optional_deps.is_some() {
                    multi_arg(arg, subcommand)?;
                }
                let optional_deps = optional_deps.get_or_insert_with(Vec::new);
                if let Some(val) = val {
                    if val.contains(',') {
                        optional_deps.extend(val.split(','));
                    } else {
                        optional_deps.extend(val.split(' '));
                    }
                }
                continue;
            }

            match &*arg {
                "--workspace" | "--all" => {
                    if let Some(arg) = workspace.replace(arg) {
                        multi_arg(arg, subcommand)?;
                    }
                    continue;
                }
                "--no-dev-deps" => parse_flag!(no_dev_deps),
                "--remove-dev-deps" => parse_flag!(remove_dev_deps),
                "--each-feature" => parse_flag!(each_feature),
                "--feature-powerset" => parse_flag!(feature_powerset),
                "--ignore-private" => parse_flag!(ignore_private),
                "--exclude-no-default-features" => parse_flag!(exclude_no_default_features),
                "--exclude-all-features" => parse_flag!(exclude_all_features),
                "--include-deps-features" => parse_flag!(include_deps_features),
                "--clean-per-run" => parse_flag!(clean_per_run),
                "--clean-per-version" => parse_flag!(clean_per_version),
                "--ignore-unknown-features" => parse_flag!(ignore_unknown_features),
                // allow multiple uses
                "--verbose" | "-v" | "-vv" => {
                    verbose = true;
                    continue;
                }

                // detect similar arg
                "--each-features" => similar_arg(arg, subcommand, "--each-feature", None)?,
                "--features-powerset" => similar_arg(arg, subcommand, "--feature-powerset", None)?,

                // propagated
                "--no-default-features" => no_default_features = true,
                "--all-features" => all_features = true,
                _ => {}
            }

            removed_flags(arg)?;

            leading.push(arg);
        }

        Ok(())
    })();

    term::set_coloring(color)?;

    res?;

    if !exclude.is_empty() && workspace.is_none() {
        // TODO: This is the same behavior as cargo, but should we allow it to be used
        // in the root of a virtual workspace as well?
        requires("--exclude", &["--workspace"])?;
    }
    if ignore_unknown_features {
        if features.is_empty() && include_features.is_empty() && group_features.is_empty() {
            requires("--ignore-unknown-features", &[
                "--features",
                "--include-features",
                "--group-features",
            ])?;
        }
        if !include_features.is_empty() {
            // TODO: implement
            warn!(
                "--ignore-unknown-features for --include-features is not fully implemented and may not work as intended"
            )
        }
        if !group_features.is_empty() {
            // TODO: implement
            warn!(
                "--ignore-unknown-features for --group-features is not fully implemented and may not work as intended"
            )
        }
    }
    if !each_feature && !feature_powerset {
        if optional_deps.is_some() {
            requires("--optional-deps", &["--each-feature", "--feature-powerset"])?;
        } else if !exclude_features.is_empty() {
            requires("--exclude-features (--skip)", &["--each-feature", "--feature-powerset"])?;
        } else if exclude_no_default_features {
            requires("--exclude-no-default-features", &["--each-feature", "--feature-powerset"])?;
        } else if exclude_all_features {
            requires("--exclude-all-features", &["--each-feature", "--feature-powerset"])?;
        } else if !include_features.is_empty() {
            requires("--include-features", &["--each-feature", "--feature-powerset"])?;
        } else if include_deps_features {
            requires("--include-deps-features", &["--each-feature", "--feature-powerset"])?;
        }
    }
    if !feature_powerset {
        if depth.is_some() {
            requires("--depth", &["--feature-powerset"])?;
        } else if !group_features.is_empty() {
            requires("--group-features", &["--feature-powerset"])?;
        }
    }
    if version_range.is_none() {
        if version_step.is_some() {
            requires("--version-step", &["--version-range"])?;
        }
        if clean_per_version {
            requires("--clean-per-version", &["--version-range"])?;
        }
    }

    let depth = depth.map(str::parse::<usize>).transpose()?;
    let group_features =
        group_features.iter().try_fold(Vec::with_capacity(group_features.len()), |mut v, g| {
            let g = if g.contains(',') {
                g.split(',')
            } else if g.contains(' ') {
                g.split(' ')
            } else {
                bail!(
                    "--group-features requires a list of two or more features separated by space \
                     or comma"
                );
            };
            v.push(Feature::group(g));
            Ok(v)
        })?;
    let version_range =
        version_range.map(|range| rustup::version_range(range, version_step)).transpose()?;

    if let Some(subcommand) = subcommand {
        match subcommand {
            "test" | "bench" => {
                if remove_dev_deps {
                    bail!(
                        "--remove-dev-deps may not be used together with {} subcommand",
                        subcommand
                    );
                } else if no_dev_deps {
                    bail!("--no-dev-deps may not be used together with {} subcommand", subcommand);
                }
            }
            // cargo-hack may not be used together with subcommands that do not have the --manifest-path flag.
            "install" => {
                bail!("cargo-hack may not be used together with {} subcommand", subcommand)
            }
            _ => {}
        }
    }

    if let Some(pos) = leading.iter().position(|a| match &**a {
        "--example" | "--examples" | "--test" | "--tests" | "--bench" | "--benches"
        | "--all-targets" => true,
        _ => a.starts_with("--example=") || a.starts_with("--test=") || a.starts_with("--bench="),
    }) {
        if remove_dev_deps {
            conflicts("--remove-dev-deps", leading[pos])?;
        } else if no_dev_deps {
            conflicts("--no-dev-deps", leading[pos])?;
        }
    }

    if !include_features.is_empty() {
        if optional_deps.is_some() {
            conflicts("--include-features", "--optional-deps")?;
        } else if include_deps_features {
            conflicts("--include-features", "--include-deps-features")?;
        }
    }

    if no_dev_deps && remove_dev_deps {
        conflicts("--no-dev-deps", "--remove-dev-deps")?;
    }
    if each_feature && feature_powerset {
        conflicts("--each-feature", "--feature-powerset")?;
    }
    if all_features {
        if each_feature {
            conflicts("--all-features", "--each-feature")?;
        } else if feature_powerset {
            conflicts("--all-features", "--feature-powerset")?;
        }
    }
    if no_default_features {
        if each_feature {
            conflicts("--no-default-features", "--each-feature")?;
        } else if feature_powerset {
            conflicts("--no-default-features", "--feature-powerset")?;
        }
    }

    for f in &exclude_features {
        if features.contains(f) {
            bail!("feature `{}` specified by both --exclude-features and --features", f);
        }
        if optional_deps.as_ref().map_or(false, |d| d.contains(f)) {
            bail!("feature `{}` specified by both --exclude-features and --optional-deps", f);
        }
        if group_features.iter().any(|v| v.matches(f)) {
            bail!("feature `{}` specified by both --exclude-features and --group-features", f);
        }
        if include_features.contains(f) {
            bail!("feature `{}` specified by both --exclude-features and --include-features", f);
        }
    }

    if cargo.version < 41 && include_deps_features {
        bail!("--include-deps-features requires Cargo 1.41 or leter");
    }
    if rustup.version < 23 && version_range.is_some() {
        bail!("--version-range requires rustup 1.23 or leter");
    }

    if subcommand.is_none() {
        if leading.contains(&"-h") {
            println!("{}", Help::short());
            std::process::exit(0);
        } else if leading.contains(&"--help") {
            println!("{}", Help::long());
            std::process::exit(0);
        } else if leading.iter().any(|&a| a == "--version" || a == "-V" || a == "-vV" || a == "-Vv")
        {
            print_version();
            std::process::exit(0);
        } else if leading.contains(&"--list") {
            let mut line = cargo.process();
            line.arg("--list");
            line.exec()?;
            std::process::exit(0);
        } else if !remove_dev_deps {
            // TODO: improve this
            mini_usage("no subcommand or valid flag specified")?
        }
    }

    if no_dev_deps {
        info!(
            "--no-dev-deps removes dev-dependencies from real `Cargo.toml` while cargo-hack is running and restores it when finished"
        );
    }

    exclude_no_default_features |= !include_features.is_empty();
    exclude_all_features |= !include_features.is_empty() || !exclude_features.is_empty();
    exclude_features.extend_from_slice(&features);

    Ok(Args {
        leading_args: leading,
        trailing_args: iter.as_slice(),

        subcommand,

        manifest_path,
        package,
        exclude,
        workspace: workspace.is_some(),
        each_feature,
        feature_powerset,
        no_dev_deps,
        remove_dev_deps,
        ignore_private,
        ignore_unknown_features,
        optional_deps,
        clean_per_run,
        clean_per_version,
        include_features: include_features.into_iter().map(Into::into).collect(),
        include_deps_features,
        version_range,

        depth,
        group_features,

        exclude_features,
        exclude_no_default_features,
        exclude_all_features,

        features,

        no_default_features,
        verbose,
        target,
    })
}

fn parse_opt<'a>(
    arg: &'a str,
    args: &mut Peekable<impl Iterator<Item = &'a str>>,
    subcommand: Option<&str>,
    pat: &str,
    require_value: bool,
) -> Result<Option<Option<&'a str>>> {
    if arg.starts_with(pat) {
        let rem = &arg[pat.len()..];
        if rem.is_empty() {
            if require_value {
                return Ok(Some(Some(args.next().ok_or_else(|| req_arg(pat, subcommand))?)));
            }
            if args.peek().map_or(true, |s| s.starts_with('-')) {
                Ok(Some(None))
            } else {
                Ok(Some(args.next()))
            }
        } else if rem.starts_with('=') {
            let mut val = &rem[1..];
            if val.starts_with('\'') && val.ends_with('\'')
                || val.starts_with('"') && val.ends_with('"')
            {
                val = &val[1..val.len() - 1];
            }
            Ok(Some(Some(val)))
        } else {
            Ok(None)
        }
    } else {
        Ok(None)
    }
}

// (short flag, long flag, value name, short descriptions, additional descriptions)
type HelpText<'a> = (&'a str, &'a str, &'a str, &'a str, &'a [&'a str]);

const HELP: &[HelpText<'_>] = &[
    ("-p", "--package", "<SPEC>...", "Package(s) to check", &[]),
    ("", "--all", "", "Alias for --workspace", &[]),
    ("", "--workspace", "", "Perform command for all packages in the workspace", &[]),
    ("", "--exclude", "<SPEC>...", "Exclude packages from the check", &[
        "This flag can only be used together with --workspace",
    ]),
    ("", "--manifest-path", "<PATH>", "Path to Cargo.toml", &[]),
    ("", "--features", "<FEATURES>...", "Space-separated list of features to activate", &[]),
    ("", "--each-feature", "", "Perform for each feature of the package", &[
        "This also includes runs with just --no-default-features flag, --all-features flag, and default features.",
    ]),
    ("", "--feature-powerset", "", "Perform for the feature powerset of the package", &[
        "This also includes runs with just --no-default-features flag, --all-features flag, and default features.",
    ]),
    ("", "--optional-deps", "[DEPS]...", "Use optional dependencies as features", &[
        "If DEPS are not specified, all optional dependencies are considered as features.",
        "This flag can only be used together with either --each-feature flag or --feature-powerset flag.",
    ]),
    ("", "--skip", "<FEATURES>...", "Alias for --exclude-features", &[]),
    ("", "--exclude-features", "<FEATURES>...", "Space-separated list of features to exclude", &[
        "To exclude run of default feature, using value `--exclude-features default`.",
        "To exclude run of just --no-default-features flag, using --exclude-no-default-features flag.",
        "To exclude run of just --all-features flag, using --exclude-all-features flag.",
        "This flag can only be used together with either --each-feature flag or --feature-powerset flag.",
    ]),
    ("", "--exclude-no-default-features", "", "Exclude run of just --no-default-features flag", &[
        "This flag can only be used together with either --each-feature flag or --feature-powerset flag.",
    ]),
    ("", "--exclude-all-features", "", "Exclude run of just --all-features flag", &[
        "This flag can only be used together with either --each-feature flag or --feature-powerset flag.",
    ]),
    (
        "",
        "--depth",
        "<NUM>",
        "Specify a max number of simultaneous feature flags of --feature-powerset",
        &[
            "If NUM is set to 1, --feature-powerset is equivalent to --each-feature.",
            "This flag can only be used together with --feature-powerset flag.",
        ],
    ),
    ("", "--group-features", "<FEATURES>...", "Space-separated list of features to group", &[
        "To specify multiple groups, use this option multiple times: `--group-features a,b --group-features c,d`",
        "This flag can only be used together with --feature-powerset flag.",
    ]),
    (
        "",
        "--include-features",
        "<FEATURES>...",
        "Include only the specified features in the feature combinations instead of package features",
        &[
            "This flag can only be used together with either --each-feature flag or --feature-powerset flag.",
        ],
    ),
    ("", "--no-dev-deps", "", "Perform without dev-dependencies", &[
        "Note that this flag removes dev-dependencies from real `Cargo.toml` while cargo-hack is running and restores it when finished.",
    ]),
    (
        "",
        "--remove-dev-deps",
        "",
        "Equivalent to --no-dev-deps flag except for does not restore the original `Cargo.toml` after performed",
        &[],
    ),
    ("", "--ignore-private", "", "Skip to perform on `publish = false` packages", &[]),
    (
        "",
        "--ignore-unknown-features",
        "",
        "Skip passing --features flag to `cargo` if that feature does not exist in the package",
        &["This flag can only be used together with either --features or --include-features."],
    ),
    (
        "",
        "--version-range",
        "<START>..[END]",
        "Perform commands on a specified (inclusive) range of Rust versions",
        &[
            "If the given range is unclosed, the latest stable compiler is treated as the upper bound.",
            "Note that ranges are always inclusive ranges.",
        ],
    ),
    ("", "--version-step", "<NUM>", "Specify the version interval of --version-range", &[
        "This flag can only be used together with --version-range flag.",
    ]),
    ("", "--clean-per-run", "", "Remove artifacts for that package before running the command", &[
        "If used this flag with --workspace, --each-feature, or --feature-powerset, artifacts will be removed before each run.",
        "Note that dependencies artifacts will be preserved.",
    ]),
    ("", "--clean-per-version", "", "Remove artifacts per Rust version", &[
        "Note that dependencies artifacts will also be removed.",
        "This flag can only be used together with --version-range flag.",
    ]),
    ("-v", "--verbose", "", "Use verbose output", &[]),
    ("", "--color", "<WHEN>", "Coloring: auto, always, never", &[
        "This flag will be propagated to cargo.",
    ]),
    ("-h", "--help", "", "Prints help information", &[]),
    ("-V", "--version", "", "Prints version information", &[]),
];

struct Help {
    long: bool,
    term_size: usize,
    print_version: bool,
}

impl Help {
    fn long() -> Self {
        Self {
            long: true,
            term_size: terminal_size::terminal_size().map_or(120, |(width, _)| width.0 as _),
            print_version: true,
        }
    }

    fn short() -> Self {
        Self {
            long: false,
            term_size: terminal_size::terminal_size().map_or(120, |(width, _)| width.0 as _),
            print_version: true,
        }
    }
}

impl fmt::Display for Help {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fn write(
            f: &mut fmt::Formatter<'_>,
            indent: usize,
            require_first_indent: bool,
            term_size: usize,
            desc: &str,
        ) -> fmt::Result {
            if require_first_indent {
                (0..indent).try_for_each(|_| write!(f, " "))?;
            }
            let mut written = 0;
            let size = term_size - indent;
            for s in desc.split(' ') {
                if written + s.len() + 1 >= size {
                    writeln!(f)?;
                    (0..indent).try_for_each(|_| write!(f, " "))?;
                    write!(f, "{}", s)?;
                    written = s.len();
                } else if written == 0 {
                    write!(f, "{}", s)?;
                    written += s.len();
                } else {
                    write!(f, " {}", s)?;
                    written += s.len() + 1;
                }
            }
            Ok(())
        }

        writeln!(
            f,
            "\
{0}{1}\n{2}
USAGE:
    cargo hack [OPTIONS] [SUBCOMMAND]\n
Use -h for short descriptions and --help for more details.\n
OPTIONS:",
            env!("CARGO_PKG_NAME"),
            if self.print_version { concat!(" ", env!("CARGO_PKG_VERSION")) } else { "" },
            env!("CARGO_PKG_DESCRIPTION")
        )?;

        for &(short, long, value_name, desc, additional) in HELP {
            write!(f, "    {:2}{} ", short, if short.is_empty() { " " } else { "," })?;
            if self.long {
                if value_name.is_empty() {
                    writeln!(f, "{}", long)?;
                } else {
                    writeln!(f, "{} {}", long, value_name)?;
                }
                write(f, 12, true, self.term_size, desc)?;
                writeln!(f, ".\n")?;
                for desc in additional {
                    write(f, 12, true, self.term_size, desc)?;
                    writeln!(f, "\n")?;
                }
            } else {
                if value_name.is_empty() {
                    write!(f, "{:32} ", long)?;
                } else {
                    let long = format!("{} {}", long, value_name);
                    write!(f, "{:32} ", long)?;
                }
                write(f, 41, false, self.term_size, desc)?;
                writeln!(f)?;
            }
        }
        if !self.long {
            writeln!(f)?;
        }

        writeln!(
            f,
            "\
Some common cargo commands are (see all commands with --list):
    build       Compile the current package
    check       Analyze the current package and report errors, but don't build object files
    run         Run a binary or example of the local package
    test        Run the tests"
        )
    }
}

fn print_version() {
    println!("{0} {1}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"))
}

// Note: When adding a flag here, update the test with the same name in `tests/test.rs` file.

fn removed_flags(flag: &str) -> Result<()> {
    let alt = match flag {
        "--ignore-non-exist-features" => "--ignore-unknown-features",
        "--skip-no-default-features" => "--exclude-no-default-features",
        _ => return Ok(()),
    };
    bail!("{} was removed, use {} instead", flag, alt)
}

fn mini_usage(msg: &str) -> Result<()> {
    bail!(
        "\
{}

USAGE:
    cargo hack [OPTIONS] [SUBCOMMAND]

For more information try --help",
        msg,
    )
}

fn get_help(flag: &str) -> Option<&HelpText<'_>> {
    HELP.iter().find(|&(s, l, ..)| *s == flag || *l == flag)
}

fn req_arg(flag: &str, subcommand: Option<&str>) -> Error {
    let arg = get_help(flag).map_or_else(|| flag.to_string(), |arg| format!("{} {}", arg.1, arg.2));
    format_err!(
        "\
The argument '{}' requires a value but none was supplied

USAGE:
    cargo hack{} {}

For more information try --help
",
        flag,
        subcommand.map_or_else(String::new, |subcommand| String::from(" ") + subcommand),
        arg,
    )
}

fn multi_arg(flag: &str, subcommand: Option<&str>) -> Result<()> {
    let arg = get_help(flag).map_or_else(|| flag.to_string(), |arg| format!("{} {}", arg.1, arg.2));
    bail!(
        "\
The argument '{}' was provided more than once, but cannot be used multiple times

USAGE:
    cargo hack{} {}

For more information try --help
",
        flag,
        subcommand.map_or_else(String::new, |subcommand| String::from(" ") + subcommand),
        arg,
    )
}

fn similar_arg(
    arg: &str,
    subcommand: Option<&str>,
    expected: &str,
    value: Option<&str>,
) -> Result<()> {
    bail!(
        "\
Found argument '{0}' which wasn't expected, or isn't valid in this context
        Did you mean {2}?

USAGE:
    cargo{1} {2} {3}

For more information try --help
",
        arg,
        subcommand.map_or_else(String::new, |subcommand| String::from(" ") + subcommand),
        expected,
        value.unwrap_or_default()
    )
}

// `flag` requires one of `requires`.
fn requires(flag: &str, requires: &[&str]) -> Result<()> {
    let with = match requires.len() {
        0 => unreachable!(),
        1 => requires[0].to_string(),
        2 => format!("either {} or {}", requires[0], requires[1]),
        _ => {
            let mut with = String::new();
            for f in requires.iter().take(requires.len() - 1) {
                with += f;
                with += ", ";
            }
            with += "or ";
            with += requires.last().unwrap();
            with
        }
    };
    bail!("{} can only be used together with {}", flag, with);
}

fn conflicts(a: &str, b: &str) -> Result<()> {
    bail!("{} may not be used together with {}", a, b);
}

#[cfg(test)]
mod tests {
    use std::{env, path::Path, process::Command};

    use tempfile::Builder;

    use super::Help;

    #[track_caller]
    fn assert_diff(expected_path: impl AsRef<Path>, actual: impl AsRef<str>) {
        let actual = actual.as_ref();
        let manifest_dir = Path::new(env!("CARGO_MANIFEST_DIR"));
        let expected_path = &manifest_dir.join(expected_path);
        let expected = fs::read_to_string(expected_path).unwrap();
        if expected != actual {
            if env::var_os("CI").is_some() {
                let outdir = Builder::new().prefix("assert_diff").tempdir().unwrap();
                let actual_path = &outdir.path().join(expected_path.file_name().unwrap());
                fs::write(actual_path, actual).unwrap();
                let status = Command::new("git")
                    .args(&["--no-pager", "diff", "--no-index", "--"])
                    .args(&[expected_path, actual_path])
                    .status()
                    .unwrap();
                assert!(!status.success());
                panic!("assertion failed");
            } else {
                fs::write(expected_path, actual).unwrap();
            }
        }
    }

    #[test]
    fn long_help() {
        let actual = Help { long: true, term_size: 200, print_version: false }.to_string();
        assert_diff("tests/long-help.txt", actual);
    }

    #[test]
    fn short_help() {
        let actual = Help { long: false, term_size: 200, print_version: false }.to_string();
        assert_diff("tests/short-help.txt", actual);
    }
}
