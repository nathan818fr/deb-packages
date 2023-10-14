#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2317
function __prepare_pkg() {
  PKG_NAME='noisetorch'
  fetch_gh_release 'noisetorch/NoiseTorch'
}

function __create_pkg() {
  download_gh_release 'NoiseTorch_(x64)_.+\.tgz' <<< "$GH_RELEASE_META"
  tar -xvf NoiseTorch_x64_*.tgz './.local/share' --strip-components=2
  tar -xvf NoiseTorch_x64_*.tgz './.local/bin/noisetorch' -O > 'noisetorch-amd64'
  rm -- ./*.tgz

  function __callback() {
    local pkg_dir="$1"

    cat << 'EOF' >> "${pkg_dir}/DEBIAN/postinst"
#!/bin/sh
set -e
setcap CAP_SYS_RESOURCE=+ep /usr/bin/noisetorch
EOF
    chmod 755 "${pkg_dir}/DEBIAN/postinst"

    local applications_dir="${pkg_dir}/usr/share/applications"
    mkdir -p -- "$applications_dir"
    cat << 'EOF' > "${applications_dir}/noisetorch.desktop"
[Desktop Entry]
Name=NoiseTorch
Comment=Create a virtual microphone that suppresses noise, in any application
Categories=Audio;AudioVideo;Utility;
Exec=/usr/bin/noisetorch
Terminal=false
Type=Application
Icon=noisetorch
EOF

    local icon_dir="${pkg_dir}/usr/share/icons/hicolor/256x256/apps"
    mkdir -p -- "$icon_dir"
    cp -- "./share/icons/hicolor/256x256/apps/noisetorch.png" "${icon_dir}/noisetorch.png"
  }
  create_pkg_from_binary 'noisetorch' 'noisetorch-*' __callback << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: sound
Priority: optional
Homepage: https://github.com/noisetorch/NoiseTorch
Description: Real-time microphone noise suppression
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
