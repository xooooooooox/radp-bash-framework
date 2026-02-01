#!/usr/bin/env bash
#
# Self-update functionality for radp-bf portable version
#

#######################################
# GitHub repository for releases
#######################################
declare -gr __RADP_BF_REPO="xooooooooox/radp-bash-framework"
declare -gr __RADP_BF_API_URL="https://api.github.com/repos/${__RADP_BF_REPO}/releases/latest"

#######################################
# Check if running in portable mode
# Returns:
#   0 - Running in portable mode
#   1 - Not in portable mode
#######################################
radp_cli_is_portable_mode() {
  [[ "${RADP_BF_PORTABLE:-}" == "1" ]]
}

#######################################
# Get current portable version
# Returns:
#   Version string (e.g., v0.6.32)
#######################################
radp_cli_get_portable_version() {
  if radp_cli_is_portable_mode; then
    echo "${RADP_BF_PORTABLE_VERSION:-unknown}"
  else
    radp_get_fw_install_version
  fi
}

#######################################
# Get latest release version from GitHub
# Arguments:
#   None
# Outputs:
#   Version string (e.g., v0.6.33)
# Returns:
#   0 - Success
#   1 - Failed to get latest version
#######################################
radp_cli_get_latest_version() {
  local response
  local version

  # Try to fetch latest release info
  if ! response=$(curl -fsSL --connect-timeout 10 --max-time 30 \
    -H "Accept: application/vnd.github.v3+json" \
    "$__RADP_BF_API_URL" 2>/dev/null); then
    radp_log_error "Failed to fetch release information from GitHub"
    return 1
  fi

  # Extract tag_name using yq or grep
  if command -v yq >/dev/null 2>&1; then
    version=$(echo "$response" | yq -r '.tag_name' 2>/dev/null)
  else
    # Fallback to grep/sed
    version=$(echo "$response" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*": *"\([^"]*\)".*/\1/')
  fi

  if [[ -z "$version" ]]; then
    radp_log_error "Failed to parse version from GitHub response"
    return 1
  fi

  echo "$version"
}

#######################################
# Detect current platform
# Outputs:
#   Platform string (e.g., darwin-arm64, linux-amd64)
#######################################
radp_cli_detect_platform() {
  local os
  local arch

  # Detect OS
  case "$(uname -s)" in
    Darwin) os="darwin" ;;
    Linux) os="linux" ;;
    *)
      radp_log_error "Unsupported OS: $(uname -s)"
      return 1
      ;;
  esac

  # Detect architecture
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      radp_log_error "Unsupported architecture: $(uname -m)"
      return 1
      ;;
  esac

  echo "${os}-${arch}"
}

#######################################
# Get download URL for portable binary
# Arguments:
#   1 - version (e.g., v0.6.33)
#   2 - platform (e.g., darwin-arm64)
#   3 - full (true/false) - whether to get full version
# Outputs:
#   Download URL
#######################################
radp_cli_get_download_url() {
  local version="$1"
  local platform="$2"
  local full="${3:-false}"

  local base_url="https://github.com/${__RADP_BF_REPO}/releases/download/${version}"
  local filename="radp-bf-portable"

  if [[ "$full" == "true" ]]; then
    filename="radp-bf-portable-full"
  fi

  filename="${filename}-${platform}"

  echo "${base_url}/${filename}"
}

#######################################
# Compare versions
# Arguments:
#   1 - version1
#   2 - version2
# Returns:
#   0 - version1 < version2 (update available)
#   1 - version1 >= version2 (no update needed)
#######################################
radp_cli_version_lt() {
  local v1="${1#v}"
  local v2="${2#v}"

  # Use sort -V for version comparison
  if [[ "$(printf '%s\n%s' "$v1" "$v2" | sort -V | head -n1)" == "$v1" ]] && [[ "$v1" != "$v2" ]]; then
    return 0
  fi
  return 1
}

#######################################
# Check if bundled deps version is used
# Returns:
#   0 - Using bundled deps (full version)
#   1 - Not using bundled deps (standard version)
#######################################
radp_cli_is_full_version() {
  [[ -n "${RADP_BF_BUNDLED_DEPS:-}" ]]
}

#######################################
# Self-update command implementation
# Arguments:
#   --check    Only check for updates, don't download
#   --force    Force update even if current version
#   --full     Download full version with bundled deps
# Returns:
#   0 - Success
#   1 - Failed or no update available
#######################################
radp_cli_self_update() {
  local check_only=false
  local force=false
  local full=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --check)
        check_only=true
        shift
        ;;
      --force)
        force=true
        shift
        ;;
      --full)
        full=true
        shift
        ;;
      --help|-h)
        radp_cli_self_update_usage
        return 0
        ;;
      *)
        radp_log_error "Unknown option: $1"
        radp_cli_self_update_usage
        return 1
        ;;
    esac
  done

  # Check if running in portable mode
  if ! radp_cli_is_portable_mode; then
    radp_log_error "self-update is only available for portable installations"
    radp_log_info "For package manager installations, use your package manager to update"
    radp_log_info "  Homebrew: brew upgrade radp-bash-framework"
    radp_log_info "  DNF:      sudo dnf upgrade radp-bash-framework"
    radp_log_info "  APT:      sudo apt update && sudo apt upgrade radp-bash-framework"
    return 1
  fi

  # Detect if currently using full version
  if radp_cli_is_full_version; then
    full=true
  fi

  # Get current and latest versions
  local current_version
  local latest_version

  current_version=$(radp_cli_get_portable_version)
  radp_log_info "Current version: $current_version"

  radp_log_info "Checking for updates..."
  if ! latest_version=$(radp_cli_get_latest_version); then
    return 1
  fi
  radp_log_info "Latest version: $latest_version"

  # Check if update is needed
  if ! radp_cli_version_lt "$current_version" "$latest_version"; then
    if [[ "$force" != "true" ]]; then
      radp_log_info "Already up to date"
      return 0
    fi
    radp_log_info "Forcing update to $latest_version"
  else
    radp_log_info "Update available: $current_version -> $latest_version"
  fi

  # If check only, we're done
  if [[ "$check_only" == "true" ]]; then
    if radp_cli_version_lt "$current_version" "$latest_version"; then
      echo "Update available: $latest_version"
      return 0
    fi
    return 0
  fi

  # Detect platform
  local platform
  if ! platform=$(radp_cli_detect_platform); then
    return 1
  fi
  radp_log_info "Platform: $platform"

  # Get download URL
  local download_url
  download_url=$(radp_cli_get_download_url "$latest_version" "$platform" "$full")
  radp_log_info "Download URL: $download_url"

  # Find current executable path
  local current_exe="${BASH_SOURCE[0]}"
  # For portable, we need to find the actual portable binary
  if [[ -n "${RADP_BF_PORTABLE_ROOT:-}" ]]; then
    # The portable binary that was executed
    # We need to find it from the process
    current_exe=$(command -v radp-bf 2>/dev/null || echo "")
    if [[ -z "$current_exe" ]]; then
      radp_log_error "Cannot determine current executable path"
      radp_log_info "Please update manually by downloading from:"
      radp_log_info "  $download_url"
      return 1
    fi
  fi

  # Check write permissions
  local exe_dir
  exe_dir=$(dirname "$current_exe")
  if [[ ! -w "$exe_dir" ]]; then
    radp_log_error "No write permission to $exe_dir"
    radp_log_info "Try running with sudo or update manually"
    return 1
  fi

  # Download new version to temp file
  radp_log_info "Downloading update..."
  local tmp_file
  tmp_file=$(mktemp)
  trap 'rm -f "$tmp_file"' EXIT

  if ! curl -fsSL --connect-timeout 30 --max-time 300 -o "$tmp_file" "$download_url"; then
    radp_log_error "Failed to download update"
    return 1
  fi

  # Make executable
  chmod +x "$tmp_file"

  # Verify download (basic check)
  if ! "$tmp_file" version >/dev/null 2>&1; then
    radp_log_error "Downloaded file verification failed"
    return 1
  fi

  # Replace current executable
  radp_log_info "Installing update..."
  if ! mv "$tmp_file" "$current_exe"; then
    radp_log_error "Failed to replace executable"
    return 1
  fi

  # Clear cache for new version
  local cache_base="${XDG_CACHE_HOME:-$HOME/.cache}/radp-bf"
  if [[ -d "$cache_base" ]]; then
    radp_log_info "Clearing cache..."
    rm -rf "$cache_base"
  fi

  radp_log_info "Successfully updated to $latest_version"
  radp_log_info "Run 'radp-bf version' to verify"
}

#######################################
# Show self-update usage
#######################################
radp_cli_self_update_usage() {
  cat <<'USAGE'
radp-bf self-update - Update radp-bf to the latest version

Usage:
  radp-bf self-update [options]

Options:
  --check    Only check for updates, don't download
  --force    Force update even if already at latest version
  --full     Download full version with bundled dependencies
  -h, --help Show this help

Examples:
  radp-bf self-update           # Update to latest version
  radp-bf self-update --check   # Check for available updates
  radp-bf self-update --full    # Update to full version

Note: self-update is only available for portable installations.
For package manager installations, use your package manager:
  Homebrew: brew upgrade radp-bash-framework
  DNF:      sudo dnf upgrade radp-bash-framework
  APT:      sudo apt update && sudo apt upgrade radp-bash-framework
USAGE
}
