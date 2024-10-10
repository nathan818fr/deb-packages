#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2317
function __prepare_pkg() {
  PKG_NAME='adw-gtk3'
  fetch_gh_release 'lassekongo83/adw-gtk3'
}

function __create_pkg() {
  download_gh_release 'adw-gtk3v.+\.tar\.xz' <<< "$GH_RELEASE_META"
  mkdir -p 'adw-gtk3'
  tar -xvf adw-gtk3v*.tar.xz -C 'adw-gtk3'
  rm -- ./*.tar.xz

  function __callback() {
    local pkg_dir="$1" pkg_arch="$2" variant

    mkdir -p -- "${pkg_dir}/usr/share/themes"
    for variant in 'adw-gtk3' 'adw-gtk3-dark'; do
      cp -aT -- "./adw-gtk3/${variant}/" "${pkg_dir}/usr/share/themes/${variant}/"
    done
  }
  create_pkg_raw all __callback << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: misc
Priority: optional
Homepage: https://github.com/lassekongo83/adw-gtk3
Description: The theme from libadwaita ported to GTK-3
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
