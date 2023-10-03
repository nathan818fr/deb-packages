#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='flowy'
  fetch_gh_release 'nathan818fr/flowy'
}

function __create_pkg() {
  download_gh_release 'flowy-linux-(amd64|arm64)' <<< "$GH_RELEASE_META"

  create_pkg_from_binary 'flowy' 'flowy-linux-*' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: utils
Priority: optional
Homepage: https://github.com/nathan818fr/flowy
Description: A dynamic wallpaper changer
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
