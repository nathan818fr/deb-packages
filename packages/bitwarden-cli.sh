#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='bitwarden-cli'
  fetch_gh_release 'bitwarden/clients' 'cli-(?<version>.+)'
}

function __create_pkg() {
  download_gh_release 'bw-linux-.+\.zip' <<< "$GH_RELEASE_META"
  unzip -o bw-linux-*.zip 'bw' && mv 'bw' 'bitwarden-amd64'
  rm -- ./*.zip

  local exe
  exe="$(get_arch_exe 'bitwarden')"
  # note: only zsh completion is available
  # https://github.com/bitwarden/clients/blob/ee2f2e1fb13f3039bcc26b14e6a93f0ba0217686/apps/cli/src/commands/completion.command.ts#L19
  "$exe" completion --shell 'zsh' \
    | sed -E 's/^#compdef.+$/#compdef _bitwarden bitwarden/; s/_bw/_bitwarden/g;' \
      > 'bitwarden.zsh-completion'

  create_pkg_from_binary 'bitwarden' 'bitwarden-*' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: utils
Priority: optional
Homepage: https://bitwarden.com/help/cli/
Description: CLI tool to access and manage a Bitwarden vault.
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
