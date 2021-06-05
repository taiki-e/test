# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org).

<!--
Note: In this file, do not use the hard wrap in the middle of a sentence for compatibility with GitHub comment style markdown rendering.
-->

## [Unreleased]

## [0.5.5] - 2021-04-04

- [Add `--clean-per-version` flag.](https://github.com/taiki-e/cargo-hack/pull/120)

## [0.5.4] - 2021-02-27

- [Stop commit of `Cargo.lock`.](https://github.com/taiki-e/cargo-hack/pull/117)
  If you want to use cargo-hack with versions of dependencies at the time of release, please download the compiled binary from GitHub Releases.
  See [#117](https://github.com/taiki-e/cargo-hack/pull/117) for more.

- [Support controls of colored output by `CARGO_TERM_COLOR`.](https://github.com/taiki-e/cargo-hack/pull/110)

- [Do not run `rustup toolchain install` in `--version-range` if the toolchain already has installed.](https://github.com/taiki-e/cargo-hack/pull/109)

## [0.5.3] - 2021-01-05

- Documentation improvements.

- Exclude unneeded files from crates.io.

## [0.5.2] - 2020-12-09

- [Automatically install target if specified when using `--version-range` option](https://github.com/taiki-e/cargo-hack/pull/108).

## [0.5.1] - 2020-12-06

- [Fix compatibility with old cargo of `--version-range` option.](https://github.com/taiki-e/cargo-hack/pull/106)

## [0.5.0] - 2020-12-06

- [Remove deprecated `--skip-no-default-features` flag.](https://github.com/taiki-e/cargo-hack/pull/100) Use `--exclude-no-default-features` flag instead.

- Add `--version-range` option. See [#102](https://github.com/taiki-e/cargo-hack/pull/102) for more.

- [Change some warnings to errors.](https://github.com/taiki-e/cargo-hack/pull/100)

- cargo-hack now handles SIGTERM the same as SIGINT (ctrl-c).

- GitHub Releases binaries containing version numbers are no longer distributed. See [#91](https://github.com/taiki-e/cargo-hack/pull/91) for more.

- Diagnostic improvements.

## [0.4.8] - 2020-12-03

- [Fix an issue that feature combinations exclusion does not work properly when used with `--group-features`.](https://github.com/taiki-e/cargo-hack/pull/99)

## [0.4.7] - 2020-12-03

No public API changes from 0.4.6.

- Distribute `*.tar.gz` file for Windows via GitHub Releases. See [#98](https://github.com/taiki-e/cargo-hack/pull/98) for more.

- Distribute x86_64-unknown-linux-musl binary via GitHub Releases.

## [0.4.6] - 2020-11-30

- [Exclude feature combinations by detecting dependencies of features.](https://github.com/taiki-e/cargo-hack/pull/85) This may significantly reduce the runtime of `--feature-powerset` on projects that have many features. See [#81](https://github.com/taiki-e/cargo-hack/pull/81) for more.

- [Fix an issue where `CARGO_HACK_CARGO_SRC=cross` did not work.](https://github.com/taiki-e/cargo-hack/pull/94)

## [0.4.5] - 2020-11-14

- Fix an issue where `cargo-hack` exits with exit code `0` if no subcommand or valid flag was passed.

- Fix an issue where `--no-default-features` flag was treated as `--exclude-no-default-features` when used together with `--each-feature` or `--feature-powerset`.

## [0.4.4] - 2020-11-13

No public API changes from 0.4.3.

- Remove version number from release binaries. URLs containing version numbers will continue to work, but are deprecated and will be removed in the next major version. See [#91](https://github.com/taiki-e/cargo-hack/pull/91) for more.

- Reduce the size of release binaries.

## [0.4.3] - 2020-11-08

No public API changes from 0.4.2.

Since this release, we have distributed compiled binary files of `cargo-hack` via GitHub release.
See [#89](https://github.com/taiki-e/cargo-hack/pull/89) for more.

## [0.4.2] - 2020-11-03

- [`cargo-hack` no longer include `--all-features` in feature combination if one or more features already excluded.](https://github.com/taiki-e/cargo-hack/pull/86)

- Diagnostic improvements.

## [0.4.1] - 2020-10-24

- [Add `--group-features` option.](https://github.com/taiki-e/cargo-hack/pull/82)

## [0.4.0] - 2020-10-21

- [Remove deprecated `--ignore-non-exist-features` flag.](https://github.com/taiki-e/cargo-hack/pull/62) Use `--ignore-unknown-features` flag instead.

- [Treat `--all-features` flag as one of feature combinations.](https://github.com/taiki-e/cargo-hack/pull/61) See [#42](https://github.com/taiki-e/cargo-hack/pull/42) for details.

- Add `--exclude-all-features` flag. ([#61](https://github.com/taiki-e/cargo-hack/pull/61), [#65](https://github.com/taiki-e/cargo-hack/pull/65)) See [#42](https://github.com/taiki-e/cargo-hack/pull/42) for details.

- [Add `--exclude-features` option. This is an alias of `--skip` option.](https://github.com/taiki-e/cargo-hack/pull/65)

- [Rename `--skip-no-default-features` flag to `--exclude-no-default-features`.](https://github.com/taiki-e/cargo-hack/pull/65)
  The old name can be used as an alias, but is deprecated.

- [Add `--include-features` option.](https://github.com/taiki-e/cargo-hack/pull/66) See [#66](https://github.com/taiki-e/cargo-hack/pull/66) for details.

- [Add `--include-deps-features` option.](https://github.com/taiki-e/cargo-hack/pull/70) See [#29](https://github.com/taiki-e/cargo-hack/pull/29) for details.

- [Fix an issue where using `--features` with `--each-feature` or `--feature-powerset` together would result in the same feature combination being performed multiple times.](https://github.com/taiki-e/cargo-hack/pull/64)

- [Fix handling of default features.](https://github.com/taiki-e/cargo-hack/pull/77)

- [Improve performance by avoiding reading and parsing Cargo manifest.](https://github.com/taiki-e/cargo-hack/pull/73)

- Diagnostic improvements.

## [0.3.14] - 2020-10-10

- [Add `--depth` option.](https://github.com/taiki-e/cargo-hack/pull/59) See [#59](https://github.com/taiki-e/cargo-hack/pull/59) for details.

## [0.3.13] - 2020-09-22

- [Print the command actually executed when error occurred.](https://github.com/taiki-e/cargo-hack/pull/55)

- [`--verbose` flag is no longer propagated to cargo.](https://github.com/taiki-e/cargo-hack/pull/55)

- [Improve compile time by removing some dependencies.](https://github.com/taiki-e/cargo-hack/pull/54)

## [0.3.12] - 2020-09-18

- [Allow only specified optional dependencies to be considered as features.](https://github.com/taiki-e/cargo-hack/pull/51)

## [0.3.11] - 2020-07-11

- [Added `--clean-per-run` flag.](https://github.com/taiki-e/cargo-hack/pull/49) See [#49](https://github.com/taiki-e/cargo-hack/pull/49) for details.

## [0.3.10] - 2020-06-20

- [Fixed an issue where some flags could not handle space-separated list correctly.](https://github.com/taiki-e/cargo-hack/pull/46)

## [0.3.9] - 2020-05-25

- [Fix an issue that `--skip` does not work for optional dependencies.](https://github.com/taiki-e/cargo-hack/pull/43)

## [0.3.8] - 2020-05-21

- [Added `--skip-no-default-features` flag.](https://github.com/taiki-e/cargo-hack/pull/41) See [#38](https://github.com/taiki-e/cargo-hack/pull/38) for details.

## [0.3.7] - 2020-05-20

- [Fixed an issue that runs with default features even if `--skip default` flag passed.](https://github.com/taiki-e/cargo-hack/pull/37)

## [0.3.6] - 2020-05-17

- [Fixed an issue that `--remove-dev-deps` flag does not work properly without subcommand.](https://github.com/taiki-e/cargo-hack/pull/36)

## [0.3.5] - 2020-04-24

- [Added `--optional-deps` flag.](https://github.com/taiki-e/cargo-hack/pull/34) See [#28](https://github.com/taiki-e/cargo-hack/pull/28) for details.

## [0.3.4] - 2020-04-23

- [cargo-hack now prints the total number of feature flag combinations and progress.](https://github.com/taiki-e/cargo-hack/pull/32)

## [0.3.3] - 2020-01-06

- [Added `--skip` option.](https://github.com/taiki-e/cargo-hack/pull/25) See [#24](https://github.com/taiki-e/cargo-hack/pull/24) for details.

## [0.3.2] - 2019-12-09

- [Added `--feature-powerset` flag to perform for the feature powerset.](https://github.com/taiki-e/cargo-hack/pull/23)

- [Reduced compile time of `cargo-hack` to less than half.](https://github.com/taiki-e/cargo-hack/pull/22)

## [0.3.1] - 2019-11-20

- [cargo-hack can now handle ctrl-c signal properly.](https://github.com/taiki-e/cargo-hack/pull/20) Previously there was an issue with interoperability with `--no-dev-deps` flag.

## [0.3.0] - 2019-11-13

- [cargo-hack now works on windows.](https://github.com/taiki-e/cargo-hack/pull/17)

- [Fixed an issue that when `--all`(`--workspace`) and `--package` flags are run in subcrate, the command does not apply to other crates in the workspace.](https://github.com/taiki-e/cargo-hack/pull/17)

- [Banned `--no-dev-deps` flag with builds that require dev-dependencies.](https://github.com/taiki-e/cargo-hack/pull/16)

- [cargo-hack is no longer does not generate temporary backup files.](https://github.com/taiki-e/cargo-hack/pull/14)

## [0.2.1] - 2019-11-03

- Removed warning from `--all`/`--workspace` flag. This is no longer "experimental".

## [0.2.0] - 2019-11-02

- [Implemented `--package` flag.](https://github.com/taiki-e/cargo-hack/pull/12)

- [Implemented `--exclude` flag.](https://github.com/taiki-e/cargo-hack/pull/12)

- [Renamed `--ignore-non-exist-features` flag to `--ignore-unknown-features`.](https://github.com/taiki-e/cargo-hack/pull/10)
  The old name can be used as an alias, but is deprecated.

## [0.1.1] - 2019-11-01

- Fixed some issues on Windows.

## [0.1.0] - 2019-10-30

Initial release

[Unreleased]: https://github.com/taiki-e/cargo-hack/compare/v0.5.5...HEAD
[0.5.5]: https://github.com/taiki-e/cargo-hack/compare/v0.5.4...v0.5.5
[0.5.4]: https://github.com/taiki-e/cargo-hack/compare/v0.5.3...v0.5.4
[0.5.3]: https://github.com/taiki-e/cargo-hack/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/taiki-e/cargo-hack/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/taiki-e/cargo-hack/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/taiki-e/cargo-hack/compare/v0.4.8...v0.5.0
[0.4.8]: https://github.com/taiki-e/cargo-hack/compare/v0.4.7...v0.4.8
[0.4.7]: https://github.com/taiki-e/cargo-hack/compare/v0.4.6...v0.4.7
[0.4.6]: https://github.com/taiki-e/cargo-hack/compare/v0.4.5...v0.4.6
[0.4.5]: https://github.com/taiki-e/cargo-hack/compare/v0.4.4...v0.4.5
[0.4.4]: https://github.com/taiki-e/cargo-hack/compare/v0.4.3...v0.4.4
[0.4.3]: https://github.com/taiki-e/cargo-hack/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/taiki-e/cargo-hack/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/taiki-e/cargo-hack/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/taiki-e/cargo-hack/compare/v0.3.14...v0.4.0
[0.3.14]: https://github.com/taiki-e/cargo-hack/compare/v0.3.13...v0.3.14
[0.3.13]: https://github.com/taiki-e/cargo-hack/compare/v0.3.12...v0.3.13
[0.3.12]: https://github.com/taiki-e/cargo-hack/compare/v0.3.11...v0.3.12
[0.3.11]: https://github.com/taiki-e/cargo-hack/compare/v0.3.10...v0.3.11
[0.3.10]: https://github.com/taiki-e/cargo-hack/compare/v0.3.9...v0.3.10
[0.3.9]: https://github.com/taiki-e/cargo-hack/compare/v0.3.8...v0.3.9
[0.3.8]: https://github.com/taiki-e/cargo-hack/compare/v0.3.7...v0.3.8
[0.3.7]: https://github.com/taiki-e/cargo-hack/compare/v0.3.6...v0.3.7
[0.3.6]: https://github.com/taiki-e/cargo-hack/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/taiki-e/cargo-hack/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/taiki-e/cargo-hack/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/taiki-e/cargo-hack/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/taiki-e/cargo-hack/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/taiki-e/cargo-hack/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/taiki-e/cargo-hack/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/taiki-e/cargo-hack/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/taiki-e/cargo-hack/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/taiki-e/cargo-hack/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/taiki-e/cargo-hack/releases/tag/v0.1.0
