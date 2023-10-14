#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='buildpacks-pack'
  fetch_gh_release 'buildpacks/pack'
  set_pkg_version_revision '0.31.0' '1' # added shell completions
}

function __create_pkg() {
  download_gh_release 'pack-.+-linux(-arm64)?\.tgz' <<< "$GH_RELEASE_META"
  tar -xvf pack-*-linux.tgz 'pack' -O > 'pack-linux-amd64'
  tar -xvf pack-*-linux-arm64.tgz 'pack' -O > 'pack-linux-arm64'
  rm -- ./*.tgz

  local exe
  exe="$(get_arch_exe 'pack-linux')"
  PACK_HOME="$PWD" "$exe" completion --shell 'bash' && mv 'completion.sh' 'pack.bash-completion'
  PACK_HOME="$PWD" "$exe" completion --shell 'zsh' && mv 'completion.zsh' 'pack.zsh-completion'
  PACK_HOME="$PWD" "$exe" completion --shell 'fish' && mv 'completion.fish' 'pack.fish-completion'

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
