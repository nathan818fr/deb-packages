#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='cidr-merger'
  fetch_gh_release 'zhanhb/cidr-merger'
}

function __create_pkg() {
  download_gh_release 'cidr-merger-linux-(amd64|arm64)' <<< "$GH_RELEASE_META"

  create_pkg_from_binary 'cidr-merger' 'cidr-merger-linux-*' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: utils
Priority: optional
Homepage: https://github.com/zhanhb/cidr-merger
Description: CLI tool to merge ip/ip cidr/ip range
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
