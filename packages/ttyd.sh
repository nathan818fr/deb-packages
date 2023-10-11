#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='ttyd'
  fetch_gh_release 'tsl0922/ttyd'
}

function __create_pkg() {
  download_gh_release 'ttyd.(x86_64|aarch64)' <<< "$GH_RELEASE_META"

  create_pkg_from_binary 'ttyd' 'ttyd.*' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: utils
Priority: optional
Homepage: https://tsl0922.github.io/ttyd/
Description: CLI tool for sharing terminal over the web
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
