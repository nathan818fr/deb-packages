#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='act'
  fetch_gh_release 'nektos/act'
}

function __create_pkg() {
  download_gh_release 'act_Linux_(x86_64|arm64)\.tar\.gz' <<< "$GH_RELEASE_META"
  tar -xvf act_Linux_x86_64.tar.gz 'act' -O > 'act-linux-amd64'
  tar -xvf act_Linux_arm64.tar.gz 'act' -O > 'act-linux-arm64'
  rm -- ./*.tar.gz

  create_pkg_from_binary 'act' 'act-linux-*' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Conflicts: artemis
Section: utils
Priority: optional
Homepage: https://nektosact.com/
Description: CLI tool to run GitHub Actions locally
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
