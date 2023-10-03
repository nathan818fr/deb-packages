#!/usr/bin/env bash
# shellcheck disable=SC2034
function __prepare_pkg() {
  PKG_NAME='docker-credential-secretservice'
  fetch_gh_release 'docker/docker-credential-helpers'
}

function __create_pkg() {
  download_gh_release 'docker-credential-secretservice-.+\.linux-(amd64|arm64)' <<< "$GH_RELEASE_META"

  create_pkg_from_binary 'docker-credential-secretservice' 'docker-credential-secretservice-*' << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Depends: libsecret-1-0
Section: utils
Priority: optional
Homepage: https://github.com/docker/docker-credential-helpers
Description: A credential helper backend which uses libsecret to keep Docker credentials safe
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
