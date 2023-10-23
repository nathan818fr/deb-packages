#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='oxipng'
  fetch_gh_release 'shssoichiro/oxipng'
}

function __create_pkg() {
  download_gh_release 'oxipng-.+-(x86_64|aarch64)-unknown-linux-gnu.tar.gz' <<< "$GH_RELEASE_META"
  tar -xvf oxipng-*-x86_64-unknown-linux-gnu.tar.gz --wildcards 'oxipng-*/oxipng' -O > 'oxipng-linux-amd64'
  tar -xvf oxipng-*-aarch64-unknown-linux-gnu.tar.gz --wildcards 'oxipng-*/oxipng' -O > 'oxipng-linux-arm64'
  rm -- ./*.tar.gz

  create_pkg_from_binary 'oxipng' 'oxipng-linux-*' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: graphics
Priority: optional
Homepage: https://github.com/shssoichiro/oxipng
Description: A multithreaded PNG optimizer written in Rust
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
