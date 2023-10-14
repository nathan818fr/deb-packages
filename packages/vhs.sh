#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='vhs'
  fetch_gh_release 'charmbracelet/vhs'
}

function __create_pkg() {
  download_gh_release 'vhs_.+_Linux_(x86_64|arm64).tar.gz' <<< "$GH_RELEASE_META"
  tar -xvf vhs_*_Linux_x86_64.tar.gz 'vhs' -O > 'vhs-linux-amd64'
  tar -xvf vhs_*_Linux_arm64.tar.gz 'vhs' -O > 'vhs-linux-arm64'
  rm -- ./*.tar.gz

  create_pkg_from_binary 'vhs' 'vhs-linux-*' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Depends: ffmpeg, ttyd
Section: utils
Priority: optional
Homepage: https://charm.sh/
Description: A tool for recording terminal GIFs
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
