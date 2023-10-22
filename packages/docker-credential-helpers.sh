#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2317
function __prepare_pkg() {
  PKG_NAME='docker-credential-helpers'
  fetch_gh_release 'docker/docker-credential-helpers'
  set_pkg_version_revision '0.8.0' '1'
}

function __create_pkg() {
  download_gh_release 'docker-credential-(secretservice|pass)-.+\.linux-(amd64|arm64)' <<< "$GH_RELEASE_META"

  function __callback() {
    local pkg_dir="$1" binary_file="$3"

    cp -T -- "${binary_file//secretservice/pass}" "${pkg_dir}/usr/bin/docker-credential-pass"
    chmod 755 -- "${pkg_dir}/usr/bin/docker-credential-pass"
  }
  create_pkg_from_binary 'docker-credential-secretservice' 'docker-credential-secretservice-*' __callback << EOF
Maintainer: Nathan Poirier <nathan@poirier.io>
Depends: libsecret-1-0
Suggests: pass
Conflicts: golang-docker-credential-helpers
Replaces: golang-docker-credential-helpers
Provides: golang-docker-credential-helpers
Section: utils
Priority: optional
Homepage: https://github.com/docker/docker-credential-helpers
Description: A credential helper backend which uses libsecret to keep Docker credentials safe
EOF
}

# shellcheck source=.toolkit.sh
source "$(dirname "$(realpath -m "$0")")/.toolkit.sh"
