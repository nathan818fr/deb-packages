#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2317
function __prepare_pkg() {
  PKG_NAME='yubico-authenticator'
  fetch_gh_release 'Yubico/yubioath-flutter'
}

function __create_pkg() {
  download_gh_release 'yubico-authenticator-.+-linux\.tar\.gz' <<< "$GH_RELEASE_META"
  mkdir -p 'yubico-authenticator-amd64'
  tar -xvf yubico-authenticator-*-linux.tar.gz --strip-components=1 -C 'yubico-authenticator-amd64'
  rm -- ./*.tar.gz

  function __callback() {
    local pkg_dir="$1" pkg_arch="$2"

    local opt_dir="${pkg_dir}/opt/yubico-authenticator"
    mkdir -p -- "$opt_dir"
    cp -aT -- "./yubico-authenticator-${pkg_arch}" "$opt_dir"
    rm -- "${opt_dir}/desktop_integration.sh"
    rm -r -- "${opt_dir}/linux_support"
    chmod 755 -- "${opt_dir}/authenticator"

    mkdir -p -- "${pkg_dir}/usr/bin"
    cat << 'EOF' > "${pkg_dir}/usr/bin/yubico-authenticator"
#!/bin/sh
exec /opt/yubico-authenticator/authenticator "$@"
EOF
    chmod 755 -- "${pkg_dir}/usr/bin/yubico-authenticator"

    local applications_dir="${pkg_dir}/usr/share/applications"
    mkdir -p -- "$applications_dir"
    cat << 'EOF' > "${applications_dir}/yubico-authenticator.desktop"
[Desktop Entry]
Name=Yubico Authenticator
Comment=Graphical interface for displaying OATH codes with a YubiKey
Keywords=Yubico;Authenticator;YubiKey
Categories=Utility;
Exec=/usr/bin/yubico-authenticator
Terminal=false
Type=Application
Icon=yubico-authenticator
EOF

    local icon_dir="${pkg_dir}/usr/share/icons/hicolor/128x128/apps"
    mkdir -p -- "$icon_dir"
    cp -- "./yubico-authenticator-${pkg_arch}/linux_support/com.yubico.yubioath.png" "${icon_dir}/yubico-authenticator.png"
  }
  create_pkg_raw amd64 __callback << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Depends: pcscd
Section: utils
Priority: optional
Homepage: https://github.com/Yubico/yubioath-flutter
Description: Yubico Authenticator for Desktop
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
