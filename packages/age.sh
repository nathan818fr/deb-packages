#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2317
function __prepare_pkg() {
  PKG_NAME='age'
  fetch_gh_release 'FiloSottile/age'
}

function __create_pkg() {
  download_gh_release 'age-v.+-linux-(amd64|arm64)\.tar\.gz' <<<"$GH_RELEASE_META"
  local arch
  for arch in 'amd64' 'arm64'; do
    mkdir -p "age-${arch}"
    tar -xvf "age-"*"-linux-${arch}.tar.gz" --strip-components=1 -C "age-${arch}"

    function __callback() {
      local pkg_dir="$1"

      # Add binary
      install -Dm755 -- "age-${arch}/age" "${pkg_dir}/usr/bin/age"
      install -Dm755 -- "age-${arch}/age-keygen" "${pkg_dir}/usr/bin/age-keygen"

      # Add license
      install -Dm644 -- "age-${arch}/LICENSE" "${pkg_dir}/usr/share/doc/age/LICENSE"
    }
    create_pkg_raw "$arch" __callback <<EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: utils
Priority: optional
Homepage: https://github.com/FiloSottile/age
Description: simple, modern and secure encryption tool
 age features small explicit keys, no config options, and UNIX-style
 composability.
EOF
  done
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
