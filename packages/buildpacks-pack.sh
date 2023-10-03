#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='buildpacks-pack'
  fetch_gh_release 'buildpacks/pack'
}

function __create_pkg() {
  download_gh_release 'pack-.+-linux(-arm64)?\.tgz' <<< "$GH_RELEASE_META"
  tar -xvf pack-*-linux.tgz pack -O > pack-linux-amd64
  tar -xvf pack-*-linux-arm64.tgz pack -O > pack-linux-arm64
  rm -- ./*.tgz

  create_pkg_from_binary 'pack' 'pack-linux-*' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: devel
Priority: optional
Homepage: https://github.com/buildpacks/pack
Description: CLI tool for building apps using Cloud Native Buildpacks
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
