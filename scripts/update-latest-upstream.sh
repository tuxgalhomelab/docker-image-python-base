#!/usr/bin/env bash

set -e -o pipefail

script_parent_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
git_repo_dir="$(realpath "${script_parent_dir:?}/..")"

ARGS_FILE="${git_repo_dir:?}/config/ARGS"

git_repo_get_all_tags() {
    git_repo="${1:?}"
    git -c 'versionsort.suffix=-' ls-remote \
        --exit-code \
        --refs \
        --sort='version:refname' \
        --tags \
        ${git_repo:?} '*.*.*' | \
        cut --delimiter='/' --fields=3
}

git_repo_latest_tag() {
    git_repo="${1:?}"
    # Strip out any strings that begin with 'v' before identifying the highest semantic version.
    highest_sem_ver_tag=$(git_repo_get_all_tags ${git_repo:?} | sed -E s'#^v(.*)$#\1#g' | sed '/-/!{s/$/_/}' | sort --version-sort | sed 's/_$//'| tail -1)
    # Identify the correct tag for the semantic version of interest.
    git_repo_get_all_tags ${git_repo:?} | grep -E "${highest_sem_ver_tag//./\\.}$" | cut --delimiter='/' --fields=3
}

get_config_arg() {
    arg="${1:?}"
    sed -n -E "s/^${arg:?}=(.*)\$/\\1/p" ${ARGS_FILE:?}
}

set_config_arg() {
    arg="${1:?}"
    val="${2:?}"
    sed -i -E "s/^${arg:?}=(.*)\$/${arg:?}=${val:?}/" ${ARGS_FILE:?}
}

pkg="pyenv"
repo_url="https://github.com/pyenv/pyenv.git"
tags_url_prefix="https://github.com/pyenv/pyenv/archive/refs/tags"
config_ver_key="PYENV_VERSION"
config_checksum_key="PYENV_SHA256_CHECKSUM"

existing_upstream_ver=$(get_config_arg ${config_ver_key:?})
latest_upstream_ver=$(git_repo_latest_tag ${repo_url:?})

if [[ "${existing_upstream_ver:?}" == "${latest_upstream_ver:?}" ]]; then
    echo "Existing config is already up to date and pointing to the latest upstream ${pkg:?} version '${latest_upstream_ver:?}'"
else
    sha256_checksum="$(curl --silent --location ${tags_url_prefix:?}/${latest_upstream_ver:?}.tar.gz | sha256sum | cut --delimiter=' ' --fields=1)"
    echo "Updating ${pkg:?} ${config_ver_key:?} '${existing_upstream_ver:?}' -> '${latest_upstream_ver:?}'"
    set_config_arg "${config_ver_key:?}" "${latest_upstream_ver:?}"
    set_config_arg "${config_checksum_key:?}" "${sha256_checksum:?}"
    git add ${ARGS_FILE:?}
    git commit -m "feat: Bump upstream ${pkg:?} version to ${latest_upstream_ver:?}."
fi
