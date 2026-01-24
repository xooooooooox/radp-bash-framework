#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="xooooooooox"
REPO_NAME="radp-bash-framework"
tmp_dir=""

log() {
  printf "%s\n" "$*"
}

err() {
  printf "radp-bash-framework install: %s\n" "$*" >&2
}

die() {
  err "$@"
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

detect_fetcher() {
  if have curl; then
    echo "curl"
    return 0
  fi
  if have wget; then
    echo "wget"
    return 0
  fi
  if have fetch; then
    echo "fetch"
    return 0
  fi
  return 1
}

fetch_url() {
  local tool="$1"
  local url="$2"
  local out="$3"

  case "${tool}" in
  curl)
    curl -fsSL "${url}" -o "${out}"
    ;;
  wget)
    wget -qO "${out}" "${url}"
    ;;
  fetch)
    fetch -qo "${out}" "${url}"
    ;;
  *)
    return 1
    ;;
  esac
}

fetch_text() {
  local tool="$1"
  local url="$2"

  case "${tool}" in
  curl)
    curl -fsSL "${url}"
    ;;
  wget)
    wget -qO- "${url}"
    ;;
  fetch)
    fetch -qo- "${url}"
    ;;
  *)
    return 1
    ;;
  esac
}

resolve_ref() {
  local manual_ref="${RADP_BF_REF:-}"
  local manual_version="${RADP_BF_VERSION:-}"

  if [[ -n "${manual_ref}" ]]; then
    echo "${manual_ref}"
    return 0
  fi

  if [[ -n "${manual_version}" ]]; then
    echo "${manual_version}"
    return 0
  fi

  local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
  local json
  json="$(fetch_text "${FETCH_TOOL}" "${api_url}" || true)"
  if [[ -z "${json}" ]]; then
    die "Failed to fetch latest release; set RADP_BF_VERSION or RADP_BF_REF."
  fi

  local tag
  tag="$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"${json}")"
  tag="${tag%%$'\n'*}"
  if [[ -z "${tag}" ]]; then
    die "Failed to parse latest tag; set RADP_BF_VERSION or RADP_BF_REF."
  fi
  echo "${tag}"
}

cleanup() {
  if [[ -n "${tmp_dir:-}" ]]; then
    rm -rf "${tmp_dir}"
  fi
}

main() {
  FETCH_TOOL="$(detect_fetcher)" || die "Requires curl, wget, or fetch."

  local install_dir="${RADP_BF_INSTALL_DIR:-$HOME/.local/lib/${REPO_NAME}}"
  local bin_dir="${RADP_BF_BIN_DIR:-$HOME/.local/bin}"
  local ref
  ref="$(resolve_ref)"

  if [[ -z "${install_dir}" || "${install_dir}" == "/" ]]; then
    die "Unsafe install dir: ${install_dir}"
  fi
  if [[ "${RADP_BF_ALLOW_ANY_DIR:-0}" != "1" ]]; then
    if [[ "$(basename "${install_dir}")" != "${REPO_NAME}" ]]; then
      die "Install dir must end with ${REPO_NAME} (set RADP_BF_ALLOW_ANY_DIR=1 to override)."
    fi
  fi

  local tar_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/${ref}.tar.gz"
  tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t "${REPO_NAME}")"
  local tarball="${tmp_dir}/${REPO_NAME}.tar.gz"
  trap cleanup EXIT

  log "Downloading ${tar_url}"
  if ! fetch_url "${FETCH_TOOL}" "${tar_url}" "${tarball}"; then
    die "Failed to download ${tar_url}"
  fi

  local tar_listing
  tar_listing="$(tar -tzf "${tarball}")"
  local root_dir="${tar_listing%%/*}"
  if [[ -z "${root_dir}" ]]; then
    die "Unable to read archive structure."
  fi

  tar -xzf "${tarball}" -C "${tmp_dir}"
  local src_root="${tmp_dir}/${root_dir}"
  if [[ ! -d "${src_root}/src/main/shell/bin" || ! -d "${src_root}/src/main/shell/framework" ]]; then
    die "Archive layout unexpected; missing src/main/shell."
  fi

  rm -rf "${install_dir}"
  mkdir -p "${install_dir}"
  cp -R "${src_root}/src/main/shell/bin" "${install_dir}/"
  cp -R "${src_root}/src/main/shell/framework" "${install_dir}/"

  chmod 0755 "${install_dir}/bin/radp-bf"
  find "${install_dir}/framework" -type f -name "*.sh" -exec chmod 0755 {} \;

  mkdir -p "${bin_dir}"
  local target="${install_dir}/bin/radp-bf"
  local link_path
  for link_name in radp-bf radp-bash-framework; do
    link_path="${bin_dir}/${link_name}"
    if [[ -e "${link_path}" && ! -L "${link_path}" ]]; then
      die "Refusing to overwrite existing file: ${link_path}"
    fi
    ln -sf "${target}" "${link_path}"
  done

  log "Installed to ${install_dir}"
  log "Ensure ${bin_dir} is in your PATH."
  log "Run: source \"\$(radp-bf --print-run)\""
}

main "$@"
