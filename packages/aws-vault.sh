#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='aws-vault'
  fetch_gh_release '99designs/aws-vault'
}

function __create_pkg() {
  download_gh_release 'aws-vault-linux-(amd64|arm64)' <<< "$GH_RELEASE_META"

  create_pkg_from_binary 'aws-vault' 'aws-vault-linux-*' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Section: utils
Priority: optional
Homepage: https://github.com/99designs/aws-vault
Description: A vault for securely storing and accessing AWS credentials in development environments
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
