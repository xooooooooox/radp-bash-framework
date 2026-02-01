#!/usr/bin/env bash
# Stage 2 module: yq check and installation
#
# yq is required for YAML configuration parsing.

# Default yq version to install
readonly __YQ_DEFAULT_VERSION="4.44.1"

#######################################
# Check if yq is available
# Returns:
#   0 - available
#   1 - not available
#######################################
__check_yq() {
  command -v yq >/dev/null 2>&1
}

#######################################
# Install yq binary
# Returns:
#   0 - success
#   1 - failed
#######################################
__install_yq() {
  local version="${RADP_YQ_VERSION:-$__YQ_DEFAULT_VERSION}"
  local os arch

  os=$(__stage2_detect_os)
  arch=$(__stage2_detect_arch)

  # yq naming convention
  local yq_os yq_arch
  case "$os" in
    darwin) yq_os="darwin" ;;
    linux)  yq_os="linux" ;;
    *)
      __stage2_log_error "Unsupported OS for yq: $os"
      return 1
      ;;
  esac

  case "$arch" in
    amd64) yq_arch="amd64" ;;
    arm64) yq_arch="arm64" ;;
    arm)   yq_arch="arm" ;;
    386)   yq_arch="386" ;;
    *)
      __stage2_log_error "Unsupported architecture for yq: $arch"
      return 1
      ;;
  esac

  local filename="yq_${yq_os}_${yq_arch}"
  local url="https://github.com/mikefarah/yq/releases/download/v${version}/${filename}"

  __stage2_log_info "Downloading yq v$version..."

  # Create temp directory
  local tmpdir=""
  tmpdir=$(__stage2_make_temp_dir "yq_install") || return 1
  trap 'rm -rf "${tmpdir:-}"' RETURN

  local binpath="$tmpdir/$filename"
  if ! __stage2_download "$url" "$binpath" "quiet"; then
    __stage2_log_error "Failed to download yq from $url"
    return 1
  fi

  chmod +x "$binpath" || return 1

  # Install to /usr/local/bin
  local target_dir="/usr/local/bin"
  local target_bin="$target_dir/yq"

  local sudo_cmd
  sudo_cmd=$(__stage2_get_sudo) || return 1

  if [[ ! -d "$target_dir" ]]; then
    __stage2_log_info "Creating $target_dir..."
    __stage2_run_sudo "$sudo_cmd" mkdir -p "$target_dir" || return 1
  fi

  __stage2_log_info "Installing yq to $target_bin..."
  __stage2_run_sudo "$sudo_cmd" mv "$binpath" "$target_bin" || return 1

  # Verify
  if ! command -v yq >/dev/null 2>&1; then
    __stage2_log_error "yq installed but not in PATH"
    return 1
  fi

  __stage2_log_info "yq installed successfully"
  return 0
}
