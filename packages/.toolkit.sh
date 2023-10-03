#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2317
set -Eeuo pipefail
shopt -s inherit_errexit

#######################################
# Define utility functions
#######################################

function log_info() {
  printf "%s\n" "$1" >&2
}

function validate_pkg_name() {
  local pkg_name
  pkg_name="$1"

  if [[ ! "$pkg_name" =~ ^[a-z0-9-]+$ ]]; then
    printf "'%s' is not a valid package name\n" "$pkg_name" >&2
    return 1
  fi
}

function validate_pkg_version() {
  local pkg_version
  pkg_version="$1"

  if [[ ! "$pkg_version" =~ ^[a-zA-Z0-9.:~+-]+$ ]]; then
    printf "'%s' is not a valid package version\n" "$pkg_version" >&2
    return 1
  fi
}

function normalize_pkg_version() {
  local version
  version="$1"

  version="${version//[^a-zA-Z0-9.:~+-]/X}"
  if [[ "$version" =~ ^v[A-Z0-9] ]]; then
    version="${version:1}"
  fi
  printf '%s\n' "${version:0:60}"
}

function gh_get_release() {
  local repo target
  repo="$1"
  target="$2"

  curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN:--}" \
    -H 'Accept: application/vnd.github+json' \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    "${GITHUB_API_URL:-https://api.github.com}/repos/${repo}/releases/${target}" \
    | jq -Mr .
}

function gh_upload_release_asset() {
  local upload_url file
  upload_url="$1"
  file="$2"

  curl -fL \
    -X POST \
    -H "Authorization: Bearer ${GITHUB_TOKEN:--}" \
    -H 'Accept: application/vnd.github+json' \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    -H "Content-Type: $(file -b --mime-type "$file")" \
    --data-binary "@${file}" \
    "${upload_url%%\{*}?name=$(basename "$file")"
  # note: the name query parameter is not url-encoded, ok since we only use ascii
}

function gh_delete_release_asset() {
  local repo asset_id
  repo="$1"
  asset_id="$2"

  curl -fsSL \
    -X DELETE \
    -H "Authorization: Bearer ${GITHUB_TOKEN:--}" \
    -H 'Accept: application/vnd.github+json' \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    "${GITHUB_API_URL:-https://api.github.com}/repos/${repo}/releases/assets/${asset_id}" \
    > /dev/null
}

function fetch_gh_release() {
  local repo
  repo="$1"

  # Fetch latest release metadata from GitHub API
  log_info "Fetching latest release metadata for ${repo} ..."
  local release_meta
  release_meta="$(gh_get_release "$repo" 'latest')"

  # Extract version
  local version
  version="$(jq -Mr '.tag_name' <<< "$release_meta")"
  version="$(normalize_pkg_version "$version")"

  # Extact release date
  local published_at
  published_at="$(jq -Mr '.published_at' <<< "$release_meta")"

  # Export variables
  log_info "Latest release for ${repo} is ${version} (published at: ${published_at})"
  GH_RELEASE_META="$release_meta"
  PKG_VERSION="$version"
  PKG_RELEASE_DATE="$published_at"
}

function download_gh_release() {
  local pattern
  pattern="$1"

  # Filter URLs to download
  local download_urls download_url download_name
  download_urls="$(
    jq -Mr \
      --arg pattern "$pattern" \
      '.assets[] | select(.name|test("^(\($pattern))$")) | .browser_download_url'
  )"

  # Download files
  while IFS= read -rd $'\n' download_url; do
    download_name="$download_url"
    download_name="${download_name%%\#*}"
    download_name="${download_name%%\?*}"
    download_name="${download_name##*/}"
    log_info "Downloading ${download_name} ..."
    curl -fL -o "$download_name" -- "$download_url"
  done <<< "$download_urls"
}

function create_pkg_raw() {
  local pkg_name pkg_version pkg_release_date pkg_arch create_pkg_raw_callback control_extra
  pkg_name="${PKG_NAME?PKG_NAME is required}"
  pkg_version="${PKG_VERSION?PKG_VERSION is required}"
  pkg_release_date="${PKG_RELEASE_DATE?PKG_RELEASE_DATE is required}"
  pkg_arch="$1"
  create_pkg_raw_callback="${2:-}"
  control_extra="$(cat)"

  local pkg_dir
  pkg_dir="$(mktemp -d -p "$PWD")"

  mkdir -p -- "${pkg_dir}/DEBIAN"
  cat << EOF > "${pkg_dir}/DEBIAN/control"
Package: ${pkg_name}
Version: ${pkg_version}
Architecture: ${pkg_arch}
${control_extra}
EOF

  if [[ -n "$create_pkg_raw_callback" ]]; then
    "$create_pkg_raw_callback" "$pkg_dir" "$pkg_arch"
  fi

  local size
  size="$(find "$pkg_dir" -path "${pkg_dir}/DEBIAN" -prune -o -type f -exec du -b {} + | awk '{s+=$1} END {printf "%.0f\n", (s/1024)}')"
  printf "Installed-Size: %s\n" "$size" >> "${pkg_dir}/DEBIAN/control"

  SOURCE_DATE_EPOCH="$(date -d "$pkg_release_date" -u +%s)" \
    dpkg-deb --root-owner-group -Zxz -b "$pkg_dir" "${pkg_name}_${pkg_version}_${pkg_arch}.deb"
}

function create_pkg_from_binary() {
  local binary_name binary_files create_pkg_from_binary_callback control_extra
  binary_name="$1"
  binary_files="$2"
  create_pkg_from_binary_callback="${3:-}"
  control_extra="$(cat)"

  local binary_file pkg_arch
  while IFS= read -rd '' binary_file; do
    case "$(basename "$binary_file")" in
      *amd64*) pkg_arch=amd64 ;;
      *x86_64*) pkg_arch=amd64 ;;
      *arm64*) pkg_arch=arm64 ;;
      *aarch64*) pkg_arch=arm64 ;;
      *aarch_64*) pkg_arch=arm64 ;;
      *) continue ;;
    esac

    function callback_for_create_pkg_raw() {
      local pkg_dir="$1" pkg_arch="$2"
      mkdir -p -- "${pkg_dir}/usr/bin"
      cp -T -- "$binary_file" "${pkg_dir}/usr/bin/${binary_name}"
      chmod 755 -- "${pkg_dir}/usr/bin/${binary_name}"

      if [[ -n "$create_pkg_from_binary_callback" ]]; then
        "$create_pkg_from_binary_callback" "$pkg_dir" "$pkg_arch" "$binary_file"
      fi
    }
    create_pkg_raw "$pkg_arch" callback_for_create_pkg_raw <<< "$control_extra"
  done < <(find . -mindepth 1 -maxdepth 1 -type f -name "$binary_files" -print0)
}

#######################################
# Define runtime functions
#######################################

function is_ghassets() {
  [[ -n "${GITHUB_REPOSITORY:-}" ]]
}

function check_pkg() {
  if is_ghassets; then
    check_pkg_ghassets
  else
    check_pkg_local
  fi
}

function check_pkg_local() {
  if find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type f -name "${PKG_NAME}_${PKG_VERSION}_*.deb" -print -quit | grep -q .; then
    log_info "Package ${PKG_NAME}_${PKG_VERSION}_*.deb already exists locally"
    exit 0
  fi
}

function check_pkg_ghassets() {
  local ghassets_meta
  ghassets_meta="$(gh_get_release "${GITHUB_REPOSITORY}" 'tags/latest')"

  local existing_assets
  existing_assets="$(
    jq -Mr \
      --arg pattern "\Q${PKG_NAME}_${PKG_VERSION}_\E.+\.deb" \
      '[ .assets[].name | select(.|test("^\($pattern)$")) ] | join(", ")' \
      <<< "$ghassets_meta"
  )"
  if [[ -n "$existing_assets" ]]; then
    log_info "Package already exists on GitHub: ${existing_assets}"
    exit 0
  fi

  GHASSETS_LATEST_META="$ghassets_meta"
}

function publish_pkg() {
  if is_ghassets; then
    publish_pkg_ghassets
  else
    publish_pkg_local
  fi
}

function publish_pkg_local() {
  find . -mindepth 1 -maxdepth 1 -type f -name "${PKG_NAME}_${PKG_VERSION}_*.deb" -exec mv -t "$WORK_DIR" -- {} +
}

function publish_pkg_ghassets() {
  local ghassets_latest_meta ghassets_all_meta
  ghassets_latest_meta="$GHASSETS_LATEST_META"
  ghassets_all_meta="$(gh_get_release "${GITHUB_REPOSITORY}" 'tags/all')"

  while IFS= read -rd '' pkg_file; do
    log_info "Uploading ${pkg_file} ..."
    gh_upload_release_asset "$(jq -Mr '.upload_url' <<< "$ghassets_all_meta")" "$pkg_file" > /dev/null
    gh_upload_release_asset "$(jq -Mr '.upload_url' <<< "$ghassets_latest_meta")" "$pkg_file" > /dev/null
  done < <(find . -mindepth 1 -maxdepth 1 -type f -name "${PKG_NAME}_${PKG_VERSION}_*.deb" -print0)

  while IFS=$'\t' read -rd $'\n' asset_id asset_name; do
    log_info "Deleting the outdated ${asset_name} from latest ..."
    gh_delete_release_asset "${GITHUB_REPOSITORY}" "$asset_id" > /dev/null
  done < <(
    jq -Mr \
      --arg pattern "\Q${PKG_NAME}_\E.+\.deb" \
      --arg current "\Q${PKG_NAME}_${PKG_VERSION}_\E.+\.deb" \
      '.assets[] | select((.name|test("^\($pattern)$")) and (.name|test("^\($current)$")|not)) | "\(.id)\t\(.name)"' \
      <<< "$ghassets_latest_meta"
  )

  log_info 'Done'
}

function main() {
  # Create a temp directory for the script execution
  WORK_DIR="$(realpath -m "$PWD")"
  TEMP_DIR="$(umask 077 > /dev/null && realpath -m "$(mktemp -d)")"
  if [[ -d "$TEMP_DIR" ]]; then
    function cleanup_TEMP_DIR() { rm -rf "$TEMP_DIR"; }
    trap cleanup_TEMP_DIR INT TERM EXIT
  fi
  pushd "$TEMP_DIR" > /dev/null
  log_info "Working directory: ${TEMP_DIR}"

  # Run preparation phase
  PKG_NAME='' PKG_VERSION='' PKG_RELEASE_DATE=''
  __prepare_pkg
  validate_pkg_name "${PKG_NAME:?PKG_NAME is required}"
  validate_pkg_version "${PKG_VERSION:?PKG_VERSION is required}"
  true "${PKG_RELEASE_DATE:?PKG_RELEASE_DATE is required}"
  check_pkg

  # Run creation phase
  __create_pkg
  publish_pkg

  exit 0
}

main "$@"
exit "$?"
