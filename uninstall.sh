#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="radp-bash-framework"
OPT_YES=false

# ============================================================================
# Logging
# ============================================================================

log() {
  printf "%s\n" "$*"
}

err() {
  printf "radp-bash-framework uninstall: %s\n" "$*" >&2
}

die() {
  err "$@"
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# Usage
# ============================================================================

usage() {
  cat <<'EOF'
radp-bash-framework uninstaller

Usage:
  uninstall.sh [OPTIONS]
  curl -fsSL .../uninstall.sh | bash -s -- [OPTIONS]

Options:
  --yes           Skip confirmation prompt
  -h, --help      Show this help

Examples:
  bash uninstall.sh
  bash uninstall.sh --yes
EOF
}

# ============================================================================
# Argument Parsing
# ============================================================================

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --yes | -y)
      OPT_YES=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1 (use --help for usage)"
      ;;
    esac
  done
}

# ============================================================================
# Detection
# ============================================================================

# Detect if radp-bash-framework is installed via a package manager
# Returns: homebrew, dnf, yum, rpm, apt, zypper, or empty string
detect_pkm_installed() {
  if have brew && brew list --formula radp-bash-framework &>/dev/null; then
    echo "homebrew"
    return 0
  fi

  if have rpm && rpm -q radp-bash-framework &>/dev/null; then
    if have dnf; then
      echo "dnf"
    elif have yum; then
      echo "yum"
    else
      echo "rpm"
    fi
    return 0
  fi

  if have dpkg && dpkg -s radp-bash-framework &>/dev/null; then
    echo "apt"
    return 0
  fi

  if have zypper && zypper se -i radp-bash-framework &>/dev/null; then
    echo "zypper"
    return 0
  fi

  echo ""
}

# Detect manual installation
# Returns: install directory path, or empty string
detect_manual_installed() {
  local default_dir="$HOME/.local/lib/${REPO_NAME}"

  if [[ -d "${default_dir}" && -f "${default_dir}/.install-method" ]]; then
    echo "${default_dir}"
    return 0
  fi

  # Also check if the symlink points to a manual install
  local link_path="$HOME/.local/bin/radp-bf"
  if [[ -L "${link_path}" ]]; then
    local target
    target="$(readlink -f "${link_path}" 2>/dev/null || readlink "${link_path}")"
    local target_dir
    target_dir="$(dirname "$(dirname "${target}")")"
    if [[ -d "${target_dir}" && "$(basename "${target_dir}")" == "${REPO_NAME}" ]]; then
      echo "${target_dir}"
      return 0
    fi
  fi

  echo ""
}

# ============================================================================
# Uninstall
# ============================================================================

uninstall_pkm() {
  local pkm="$1"

  log "Uninstalling ${REPO_NAME} via ${pkm}..."

  case "${pkm}" in
  homebrew)
    brew uninstall radp-bash-framework
    ;;
  dnf)
    sudo dnf remove -y radp-bash-framework
    ;;
  yum)
    sudo yum remove -y radp-bash-framework
    ;;
  rpm)
    sudo rpm -e radp-bash-framework
    ;;
  apt)
    sudo apt-get remove -y radp-bash-framework
    ;;
  zypper)
    sudo zypper remove -y radp-bash-framework
    ;;
  *)
    err "Don't know how to uninstall via: ${pkm}"
    return 1
    ;;
  esac
}

uninstall_manual() {
  local install_dir="$1"

  log "Removing manual installation at ${install_dir}..."

  # Remove symlinks
  local bin_dir="$HOME/.local/bin"
  local link_name
  for link_name in radp-bf radp-bash-framework; do
    local link_path="${bin_dir}/${link_name}"
    if [[ -L "${link_path}" ]]; then
      rm -f "${link_path}"
      log "Removed symlink ${link_path}"
    fi
  done

  # Remove install directory
  rm -rf "${install_dir}"
  log "Removed ${install_dir}"
}

confirm() {
  local prompt="$1"
  if [[ "${OPT_YES}" == true ]]; then
    return 0
  fi

  printf "%s [y/N] " "${prompt}"
  local reply
  read -r reply
  case "${reply}" in
  y | Y | yes | YES) return 0 ;;
  *) return 1 ;;
  esac
}

# ============================================================================
# Main
# ============================================================================

main() {
  parse_args "$@"

  local pkm_installed manual_dir
  pkm_installed="$(detect_pkm_installed)"
  manual_dir="$(detect_manual_installed)"

  if [[ -z "${pkm_installed}" && -z "${manual_dir}" ]]; then
    log "${REPO_NAME} is not installed"
    exit 0
  fi

  # Show what will be removed
  log "Detected installations:"
  if [[ -n "${pkm_installed}" ]]; then
    log "  - Package manager: ${pkm_installed}"
  fi
  if [[ -n "${manual_dir}" ]]; then
    local ref_info=""
    if [[ -f "${manual_dir}/.install-ref" ]]; then
      ref_info=" (ref: $(cat "${manual_dir}/.install-ref"))"
    fi
    log "  - Manual: ${manual_dir}${ref_info}"
  fi
  log ""

  if ! confirm "Proceed with uninstall?"; then
    log "Cancelled"
    exit 0
  fi

  # Remove package-manager installation
  if [[ -n "${pkm_installed}" ]]; then
    uninstall_pkm "${pkm_installed}" || err "Failed to uninstall via ${pkm_installed}"
  fi

  # Remove manual installation
  if [[ -n "${manual_dir}" ]]; then
    uninstall_manual "${manual_dir}" || err "Failed to remove manual installation"
  fi

  log ""
  log "${REPO_NAME} has been uninstalled"
}

main "$@"
