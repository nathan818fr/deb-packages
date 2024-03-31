#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='podlet'
  fetch_gh_release 'k9withabone/podlet'
}

function __create_pkg() {
  download_gh_release 'podlet-x86_64-unknown-linux-gnu.tar.xz' <<< "$GH_RELEASE_META"
  tar -xvf podlet-x86_64-unknown-linux-gnu.tar.xz --wildcards 'podlet-*/podlet' -O > 'podlet-linux-amd64'
  rm -- ./*.tar.xz

  create_pkg_from_binary 'podlet' 'podlet-linux-*' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: utils
Priority: optional
Homepage: https://github.com/k9withabone/podlet
Description: Generate podman quadlet files from a podman command, compose file, or existing object
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
