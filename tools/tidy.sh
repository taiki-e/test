#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
# shellcheck disable=SC2046
set -eEuo pipefail
IFS=$'\n\t'
cd "$(dirname "$0")"/..

# shellcheck disable=SC2154
trap 's=$?; echo >&2 "$0: error on line "${LINENO}": ${BASH_COMMAND}"; exit ${s}' ERR

# USAGE:
#    ./tools/tidy.sh
#
# Note: This script requires the following tools:
# - git
# - jq
# - shfmt
# - shellcheck
# - npm (node 18+)
# - python 3.5+
# - cargo, rustfmt (if Rust code exists)
# - clang-format (if C/C++ code exists)
#
# This script is shared with other repositories, so there may also be
# checks for files not included in this repository, but they will be
# skipped if the corresponding files do not exist.

check_diff() {
    if [[ -n "${CI:-}" ]]; then
        if ! git --no-pager diff --exit-code "$@"; then
            should_fail=1
        fi
    else
        if ! git --no-pager diff --exit-code "$@" &>/dev/null; then
            should_fail=1
        fi
    fi
}
check_config() {
    if [[ ! -e "$1" ]]; then
        error "could not found $1 in the repository root"
    fi
}
check_install() {
    for tool in "$@"; do
        if ! type -P "${tool}" &>/dev/null; then
            if [[ "${tool}" == "python3" ]]; then
                for p in '3.12' '3.11' '3.10' '3.9' '3.8' '3.7' '3.6' '3.5' ''; do
                    if type -P "python${p}" &>/dev/null; then
                        tool=''
                        break
                    fi
                done
                if [[ -z "${tool}" ]]; then
                    continue
                fi
            fi
            error "'${tool}' is required to run this check"
            return 1
        fi
    done
}
error() {
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::error::$*"
    else
        echo >&2 "error: $*"
    fi
    should_fail=1
}
warn() {
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::warning::$*"
    else
        echo >&2 "warning: $*"
    fi
}
info() {
    echo >&2 "info: $*"
}
ls_files() {
    comm -23 <(git ls-files "$@" | LC_ALL=C sort) <(git ls-files --deleted "$@" | LC_ALL=C sort)
}
venv() {
    local bin="$1"
    shift
    "${venv_bin}/${bin}${exe}" "$@"
}
venv_install_yq() {
    py_suffix=''
    for p in '3' '3.12' '3.11' '3.10' '3.9' '3.8' '3.7' '3.6' '3.5' ''; do
        if type -P "python${p}" &>/dev/null; then
            py_suffix=${p}
            break
        fi
    done
    exe=''
    venv_bin=.venv/bin
    case "$(uname -s)" in
        MINGW* | MSYS* | CYGWIN* | Windows_NT)
            exe=.exe
            venv_bin=.venv/Scripts
            ;;
    esac
    if [[ ! -d .venv ]]; then
        "python${py_suffix}" -m venv .venv
    fi
    if [[ ! -e "${venv_bin}/yq${exe}" ]]; then
        info "installing yq to ./.venv using pip${py_suffix}"
        venv "pip${py_suffix}" install yq
    fi
}

if [[ $# -gt 0 ]]; then
    cat <<EOF
USAGE:
    $0
EOF
    exit 1
fi

check_install git

# Rust (if exists)
if [[ -n "$(ls_files '*.rs')" ]]; then
    info "checking Rust code style"
    check_config .rustfmt.toml
    if check_install cargo jq python3; then
        # `cargo fmt` cannot recognize files not included in the current workspace and modules
        # defined inside macros, so run rustfmt directly.
        # We need to use nightly rustfmt because we use the unstable formatting options of rustfmt.
        rustc_version=$(rustc -vV | grep -E '^release:' | cut -d' ' -f2)
        if [[ "${rustc_version}" == *"nightly"* ]] || [[ "${rustc_version}" == *"dev"* ]] || ! type -P rustup &>/dev/null; then
            if type -P rustup &>/dev/null; then
                rustup component add rustfmt &>/dev/null
            fi
            info "running \`rustfmt \$(git ls-files '*.rs')\`"
            rustfmt $(ls_files '*.rs')
        else
            rustup component add rustfmt --toolchain nightly &>/dev/null || true
            info "running \`rustfmt +nightly \$(git ls-files '*.rs')\`"
            rustfmt +nightly $(ls_files '*.rs')
        fi
        check_diff $(ls_files '*.rs')
        cast_without_turbofish=$(grep -En '\.cast\(\)' $(ls_files '*.rs') || true)
        if [[ -n "${cast_without_turbofish}" ]]; then
            error "please replace \`.cast()\` with \`.cast::<type_name>()\`:"
            echo "${cast_without_turbofish}"
        fi
        # Sync readme and crate-level doc.
        first=1
        for readme in $(ls_files '*README.md'); do
            if ! grep -Eq '^<!-- tidy:crate-doc:start -->' "${readme}"; then
                continue
            fi
            lib="$(dirname "${readme}")/src/lib.rs"
            if [[ -n "${first}" ]]; then
                first=''
                info "checking readme and crate-level doc are synchronized"
            fi
            if ! grep -Eq '^<!-- tidy:crate-doc:end -->' "${readme}"; then
                bail "missing '<!-- tidy:crate-doc:end -->' comment in ${readme}"
            fi
            if ! grep -Eq '^<!-- tidy:crate-doc:start -->' "${lib}"; then
                bail "missing '<!-- tidy:crate-doc:start -->' comment in ${lib}"
            fi
            if ! grep -Eq '^<!-- tidy:crate-doc:end -->' "${lib}"; then
                bail "missing '<!-- tidy:crate-doc:end -->' comment in ${lib}"
            fi
            new=$(tr <"${readme}" '\n' '\a' | grep -Eo '<!-- tidy:crate-doc:start -->.*<!-- tidy:crate-doc:end -->' | sed -E 's/\&/\\\&/g; s/\\/\\\\/g')
            new=$(tr <"${lib}" '\n' '\a' | awk -v new="${new}" 'gsub("<!-- tidy:crate-doc:start -->.*<!-- tidy:crate-doc:end -->",new)' | tr '\a' '\n')
            echo "${new}" >"${lib}"
            check_diff "${lib}"
        done
        # Make sure that public Rust crates don't contain executables and binaries.
        executables=''
        binaries=''
        metadata=$(cargo metadata --format-version=1 --no-deps)
        has_public_crate=''
        venv_install_yq
        for id in $(jq '.workspace_members[]' <<<"${metadata}"); do
            pkg=$(jq ".packages[] | select(.id == ${id})" <<<"${metadata}")
            publish=$(jq -r '.publish' <<<"${pkg}")
            manifest_path=$(jq -r '.manifest_path' <<<"${pkg}")
            if [[ "$(venv tomlq -c '.lints' "${manifest_path}")" == "null" ]]; then
                error "no [lints] table in ${manifest_path} please add '[lints]' with 'workspace = true'"
            fi
            # Publishing is unrestricted if null, and forbidden if an empty array.
            if [[ "${publish}" == "[]" ]]; then
                continue
            fi
            has_public_crate=1
        done
        if [[ -n "${has_public_crate}" ]]; then
            info "checking public crates don't contain executables and binaries"
            if [[ -f Cargo.toml ]]; then
                root_manifest=$(cargo locate-project --message-format=plain --manifest-path Cargo.toml)
                root_pkg=$(jq ".packages[] | select(.manifest_path == \"${root_manifest}\")" <<<"${metadata}")
                if [[ -n "${root_pkg}" ]]; then
                    publish=$(jq -r '.publish' <<<"${root_pkg}")
                    # Publishing is unrestricted if null, and forbidden if an empty array.
                    if [[ "${publish}" != "[]" ]]; then
                        exclude=$(venv tomlq -r '.package.exclude[]' Cargo.toml)
                        if ! grep -Eq '^/\.\*$' <<<"${exclude}"; then
                            error "top-level Cargo.toml of non-virtual workspace should have 'exclude' field with \"/.*\""
                        fi
                        if [[ -e tools ]] && ! grep -Eq '^/tools$' <<<"${exclude}"; then
                            error "top-level Cargo.toml of non-virtual workspace should have 'exclude' field with \"/tools\" if it exists"
                        fi
                        if [[ -e target-specs ]] && ! grep -Eq '^/target-specs$' <<<"${exclude}"; then
                            error "top-level Cargo.toml of non-virtual workspace should have 'exclude' field with \"/target-specs\" if it exists"
                        fi
                    fi
                fi
            fi
            for p in $(ls_files); do
                # Skip directories.
                if [[ -d "${p}" ]]; then
                    continue
                fi
                # Top-level hidden files/directories and tools/* are excluded from crates.io (ensured by the above check).
                # TODO: fully respect exclude field in Cargo.toml.
                case "${p}" in
                    .* | tools/* | target-specs/*) continue ;;
                esac
                if [[ -x "${p}" ]]; then
                    executables+="${p}"$'\n'
                fi
                # Use diff instead of file because file treats an empty file as a binary
                # https://unix.stackexchange.com/questions/275516/is-there-a-convenient-way-to-classify-files-as-binary-or-text#answer-402870
                if (diff .gitattributes "${p}" || true) | grep -Eq '^Binary file'; then
                    binaries+="${p}"$'\n'
                fi
            done
            if [[ -n "${executables}" ]]; then
                error "file-permissions-check failed: executables are only allowed to be present in directories that are excluded from crates.io"
                echo "======================================="
                echo -n "${executables}"
                echo "======================================="
            fi
            if [[ -n "${binaries}" ]]; then
                error "file-permissions-check failed: binaries are only allowed to be present in directories that are excluded from crates.io"
                echo "======================================="
                echo -n "${binaries}"
                echo "======================================="
            fi
        fi
    fi
elif [[ -e .rustfmt.toml ]]; then
    error ".rustfmt.toml is unused"
fi

# C/C++ (if exists)
if [[ -n "$(ls_files '*.c' '*.h' '*.cpp' '*.hpp')" ]]; then
    info "checking C/C++ code style"
    check_config .clang-format
    if check_install clang-format; then
        info "running \`clang-format -i \$(git ls-files '*.c' '*.h' '*.cpp' '*.hpp')\`"
        clang-format -i $(ls_files '*.c' '*.h' '*.cpp' '*.hpp')
        check_diff $(ls_files '*.c' '*.h' '*.cpp' '*.hpp')
    fi
elif [[ -e .clang-format ]]; then
    error ".clang-format is unused"
fi

# YAML/JavaScript/JSON (if exists)
if [[ -n "$(ls_files '*.yml' '*.yaml' '*.js' '*.json')" ]]; then
    info "checking YAML/JavaScript/JSON code style"
    check_config .editorconfig
    if check_install npm; then
        info "running \`npx -y prettier -l -w \$(git ls-files '*.yml' '*.yaml' '*.js' '*.json')\`"
        npx -y prettier -l -w $(ls_files '*.yml' '*.yaml' '*.js' '*.json')
        check_diff $(ls_files '*.yml' '*.yaml' '*.js' '*.json')
    fi
    # Check GitHub workflows.
    if [[ -d .github/workflows ]]; then
        info "checking GitHub workflows"
        if check_install jq python3; then
            venv_install_yq
            for workflow in .github/workflows/*.yml; do
                # The top-level permissions must be weak as they are referenced by all jobs.
                permissions=$(venv yq -c '.permissions' "${workflow}")
                case "${permissions}" in
                    '{"contents":"read"}' | '{"contents":"none"}') ;;
                    null) error "${workflow}: top level permissions not found; it must be 'contents: read' or weaker permissions" ;;
                    *) error "${workflow}: only 'contents: read' and weaker permissions are allowed at top level; if you want to use stronger permissions, please set job-level permissions" ;;
                esac
                # Make sure the 'needs' section is not out of date.
                if grep -Eq '# tidy:needs' "${workflow}" && ! grep -Eq '# *needs: \[' "${workflow}"; then
                    # shellcheck disable=SC2207
                    jobs_actual=($(venv yq '.jobs' "${workflow}" | jq -r 'keys_unsorted[]'))
                    unset 'jobs_actual[${#jobs_actual[@]}-1]'
                    # shellcheck disable=SC2207
                    jobs_expected=($(venv yq -r '.jobs."ci-success".needs[]' "${workflow}"))
                    if [[ "${jobs_actual[*]}" != "${jobs_expected[*]+"${jobs_expected[*]}"}" ]]; then
                        printf -v jobs '%s, ' "${jobs_actual[@]}"
                        sed -Ei "s/needs: \[.*\] # tidy:needs/needs: [${jobs%, }] # tidy:needs/" "${workflow}"
                        check_diff "${workflow}"
                        error "${workflow}: please update 'needs' section in 'ci-success' job"
                    fi
                fi
            done
        fi
    fi
fi
if [[ -n "$(ls_files '*.yaml' | (grep -E -v '\.markdownlint-cli2\.yaml' || true))" ]]; then
    error "please use '.yml' instead of '.yaml' for consistency"
    ls_files '*.yaml' | (grep -E -v '\.markdownlint-cli2\.yaml' || true)
fi

# TOML (if exists)
if [[ -n "$(ls_files '*.toml' | (grep -E -v '\.taplo\.toml' || true))" ]]; then
    info "checking TOML style"
    check_config .taplo.toml
    if check_install npm; then
        info "running \`npx -y @taplo/cli fmt \$(git ls-files '*.toml')\`"
        RUST_LOG=warn npx -y @taplo/cli fmt $(ls_files '*.toml')
        check_diff $(ls_files '*.toml')
    fi
elif [[ -e .taplo.toml ]]; then
    error ".taplo.toml is unused"
fi

# Markdown (if exists)
if [[ -n "$(ls_files '*.md')" ]]; then
    info "checking Markdown style"
    check_config .markdownlint-cli2.yaml
    if check_install npm; then
        info "running \`npx -y markdownlint-cli2 \$(git ls-files '*.md')\`"
        npx -y markdownlint-cli2 $(ls_files '*.md')
    fi
elif [[ -e .markdownlint-cli2.yaml ]]; then
    error ".markdownlint-cli2.yaml is unused"
fi
if [[ -n "$(ls_files '*.markdown')" ]]; then
    error "please use '.md' instead of '.markdown' for consistency"
    ls_files '*.markdown'
fi

# Shell scripts
info "checking Shell scripts"
files=()
for f in $(ls_files '*.sh'); do
    if grep -Eq '(^|\(| )(grep|sed) -E' "${f}"; then
        files+=("${f}")
    fi
done
res=$(grep -En '(^|\(| )(grep|sed) ([^-]|-[^E])' "${files[@]}" | (grep -E -v '^[^ ]+: *#' || true) | LC_ALL=C sort || true)
if [[ -n "${res}" ]]; then
    error "error: please always use ERE (-E flag) for grep/sed for code consistency within a file"
    # error "for grep/sed, we recommend always using ERE (-E flag) which is used as default in most regex libraries:"
    echo "======================================="
    echo "${res}"
    echo "======================================="
fi
if check_install shfmt; then
    check_config .editorconfig
    info "running \`shfmt -l -w \$(git ls-files '*.sh')\`"
    shfmt -l -w $(ls_files '*.sh')
    check_diff $(ls_files '*.sh')
fi
if check_install shellcheck; then
    check_config .shellcheckrc
    info "running \`shellcheck \$(git ls-files '*.sh')\`"
    if ! shellcheck $(ls_files '*.sh'); then
        should_fail=1
    fi
    if [[ -n "$(ls_files '*Dockerfile')" ]]; then
        # SC2154 doesn't seem to work on dockerfile.
        info "running \`shellcheck -e SC2148,SC2154,SC2250 \$(git ls-files '*Dockerfile')\`"
        if ! shellcheck -e SC2148,SC2154,SC2250 $(ls_files '*Dockerfile'); then
            should_fail=1
        fi
    fi
    # Check scripts in other files.
    # TODO: action.yml, .cirrus.yml
    if [[ -d .github/workflows ]]; then
        info "running \`shellcheck -e SC2086,SC2129\` for scripts in .github/workflows/*.yml"
        if check_install jq python3; then
            venv_install_yq
            for workflow in .github/workflows/*.yml; do
                default_shell=$(venv yq -r -c '.defaults.run.shell' "${workflow}")
                if [[ "${default_shell}" == "null" ]]; then
                    bail "default shell must be set in ${workflow}"
                fi
                for job in $(venv yq -c '.jobs | to_entries | .[]' "${workflow}"); do
                    dir="tmp/tidy/shell/${workflow//\//_}"
                    name=$(jq -r '.key' <<<"${job}")
                    job=$(jq -r '.value' <<<"${job}")
                    n=1
                    if [[ "$(jq -r '.steps' <<<"${job}")" == "null" ]]; then
                        continue # caller of reusable workflow
                    fi
                    job_default_shell=$(venv yq -r -c '.defaults.run.shell' <<<"${job}")
                    if [[ "${job_default_shell}" == "null" ]]; then
                        job_default_shell="${default_shell}"
                    fi
                    for step in $(jq -c '.steps[]' <<<"${job}"); do
                        run=$(jq -r '.run' <<<"${step}")
                        prepare=null
                        if [[ "${run}" != "null" ]]; then
                            shell=$(jq -r '.shell' <<<"${step}")
                            if [[ "${shell}" == "null" ]]; then
                                shell="${job_default_shell}"
                            fi
                        else
                            run=$(jq -r '.with.run' <<<"${step}")
                            if [[ "${run}" == "null" ]]; then
                                ((n++))
                                continue
                            fi
                            prepare=$(jq -r '.with.prepare' <<<"${step}")
                            shell=$(jq -r '.with.shell' <<<"${step}")
                            if [[ "${shell}" == "null" ]]; then
                                shell='sh'
                            fi
                        fi
                        case "${shell}" in
                            sh* | bash*) ;;
                            *) continue ;;
                        esac
                        mkdir -p "${dir}"
                        emit_and_shellcheck() {
                            local text=$1
                            local path=$2
                            if [[ "${text}" == "null" ]]; then
                                return
                            fi
                            echo "#!/usr/bin/env ${shell}"$'\n'"${text}" >"${path}"
                            # Use python because sed doesn't support .*?.
                            "python${py_suffix}" <<EOF
import re
with open('${path}', 'r') as f:
    text = f.read()
text = re.sub(r"\\\${{.*?}}", "\${__GHA_SYNTAX__}", text)
with open('${path}', "w") as f:
    f.write(text)
EOF
                            if ! shellcheck -e "SC2086,SC2129" "${path}"; then
                                should_fail=1
                            fi
                        }
                        emit_and_shellcheck "${run}" "${dir}/${name//\//_}__step${n}__run.sh"
                        emit_and_shellcheck "${prepare}" "${dir}/${name//\//_}__step${n}__prepare.sh"
                        ((n++))
                    done
                done
            done
        fi
    fi
fi

# License check
# TODO: This check is still experimental and does not track all files that should be tracked.
if [[ -f tools/.tidy-check-license-headers ]]; then
    info "checking license headers (experimental)"
    failed_files=''
    for p in $(eval $(<tools/.tidy-check-license-headers)); do
        case "$(basename "${p}")" in
            *.stderr | *.expanded.rs) continue ;; # generated files
            *.sh | *.py | *.rb | *Dockerfile) prefix=("# ") ;;
            *.rs | *.c | *.h | *.cpp | *.hpp | *.s | *.S | *.js) prefix=("// " "/* ") ;;
            *.ld | *.x) prefix=("/* ") ;;
            # TODO: More file types?
            *) continue ;;
        esac
        # TODO: The exact line number is not actually important; it is important
        # that it be part of the top-level comments of the file.
        line=1
        if IFS= LC_ALL=C read -rd '' -n3 shebang <"${p}" && [[ "${shebang}" == '#!/' ]]; then
            line=2
        elif [[ "${p}" == *"Dockerfile" ]] && IFS= LC_ALL=C read -rd '' -n9 syntax <"${p}" && [[ "${syntax}" == '# syntax=' ]]; then
            line=2
        fi
        header_found=''
        for pre in "${prefix[@]}"; do
            # TODO: check that the license is valid as SPDX and is allowed in this project.
            if [[ "$(grep -En "${pre//\*/\\*}SPDX-License-Identifier: " "${p}")" == "${line}:${pre}SPDX-License-Identifier: "* ]]; then
                header_found=1
                break
            fi
        done
        if [[ -z "${header_found}" ]]; then
            failed_files+="${p}:${line}"$'\n'
        fi
    done
    if [[ -n "${failed_files}" ]]; then
        error "license-check failed: please add SPDX-License-Identifier to the following files"
        echo "======================================="
        echo -n "${failed_files}"
        echo "======================================="
    fi
fi

# Spell check (if config exists)
if [[ -f .cspell.json ]]; then
    info "spell checking"
    project_dictionary=.github/.cspell/project-dictionary.txt
    if [[ "$(uname -s)" == "SunOS" ]] && [[ "$(/usr/bin/uname -o)" == "illumos" ]]; then
        warn "this check is skipped on illumos due to upstream bug (dictionaries are not loaded correctly)"
    elif check_install npm jq python3; then
        has_rust=''
        if [[ -n "$(ls_files '*Cargo.toml')" ]]; then
            venv_install_yq
            has_rust=1
            dependencies=''
            for manifest_path in $(ls_files '*Cargo.toml'); do
                if [[ "${manifest_path}" != "Cargo.toml" ]] && [[ "$(venv tomlq -c '.workspace' "${manifest_path}")" == "null" ]]; then
                    continue
                fi
                metadata=$(cargo metadata --format-version=1 --no-deps --manifest-path "${manifest_path}")
                for id in $(jq '.workspace_members[]' <<<"${metadata}"); do
                    dependencies+="$(jq ".packages[] | select(.id == ${id})" <<<"${metadata}" | jq -r '.dependencies[].name')"$'\n'
                done
            done
            # shellcheck disable=SC2001
            dependencies=$(sed -E 's/[0-9_-]/\n/g' <<<"${dependencies}" | LC_ALL=C sort -f -u)
        fi
        config_old=$(<.cspell.json)
        config_new=$(grep -E -v '^ *//' <<<"${config_old}" | jq 'del(.dictionaries[] | select(index("organization-dictionary") | not))' | jq 'del(.dictionaryDefinitions[] | select(.name == "organization-dictionary" | not))')
        trap -- 'echo "${config_old}" >.cspell.json; echo >&2 "$0: trapped SIGINT"; exit 1' SIGINT
        echo "${config_new}" >.cspell.json
        dependencies_words=''
        if [[ -n "${has_rust}" ]]; then
            dependencies_words=$(npx -y cspell stdin --no-progress --no-summary --words-only --unique <<<"${dependencies}" || true)
        fi
        all_words=$(npx -y cspell --no-progress --no-summary --words-only --unique $(ls_files | (grep -E -v "${project_dictionary//\./\\.}" || true)) || true)
        echo "${config_old}" >.cspell.json
        trap - SIGINT
        cat >.github/.cspell/rust-dependencies.txt <<EOF
// This file is @generated by $(basename "$0").
// It is not intended for manual editing.
EOF
        if [[ -n "${dependencies_words}" ]]; then
            echo $'\n'"${dependencies_words}" >>.github/.cspell/rust-dependencies.txt
        fi
        check_diff .github/.cspell/rust-dependencies.txt
        if ! grep -Eq '^\.github/\.cspell/rust-dependencies.txt linguist-generated' .gitattributes; then
            error "you may want to mark .github/.cspell/rust-dependencies.txt linguist-generated"
        fi

        info "running \`npx -y cspell --no-progress --no-summary \$(git ls-files)\`"
        if ! npx -y cspell --no-progress --no-summary $(ls_files); then
            error "spellcheck failed: please fix uses of above words or add to ${project_dictionary} if correct"
        fi

        # Make sure the project-specific dictionary does not contain duplicated words.
        for dictionary in .github/.cspell/*.txt; do
            if [[ "${dictionary}" == "${project_dictionary}" ]]; then
                continue
            fi
            case "$(uname -s)" in
                # NetBSD uniq doesn't support -i flag.
                NetBSD) dup=$(sed -E -e '/^$/d' -e '/^\/\//d' "${project_dictionary}" "${dictionary}" | LC_ALL=C sort -f | tr '[:upper:]' '[:lower:]' | uniq -d) ;;
                *) dup=$(sed -E -e '/^$/d' -e '/^\/\//d' "${project_dictionary}" "${dictionary}" | LC_ALL=C sort -f | LC_ALL=C uniq -d -i) ;;
            esac
            if [[ -n "${dup}" ]]; then
                error "duplicated words in dictionaries; please remove the following words from ${project_dictionary}"
                echo "======================================="
                echo "${dup}"
                echo "======================================="
            fi
        done

        # Make sure the project-specific dictionary does not contain unused words.
        unused=''
        for word in $(grep -E -v '^//.*' "${project_dictionary}" || true); do
            if ! grep -Eq -i "^${word}$" <<<"${all_words}"; then
                unused+="${word}"$'\n'
            fi
        done
        if [[ -n "${unused}" ]]; then
            error "unused words in dictionaries; please remove the following words from ${project_dictionary}"
            echo "======================================="
            echo -n "${unused}"
            echo "======================================="
        fi
    fi
fi

if [[ -n "${should_fail:-}" ]]; then
    exit 1
fi
