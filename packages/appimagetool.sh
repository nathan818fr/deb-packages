#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='appimagetool'
  fetch_gh_release 'AppImage/AppImageKit'
}

function __create_pkg() {
  download_gh_release 'appimagetool-(x86_64|aarch64).AppImage' <<< "$GH_RELEASE_META"

  create_pkg_from_binary 'appimagetool' 'appimagetool-*.AppImage' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: devel
Priority: optional
Homepage: https://github.com/AppImage/AppImageKit
Description: CLI tool to package desktop applications as AppImages
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
