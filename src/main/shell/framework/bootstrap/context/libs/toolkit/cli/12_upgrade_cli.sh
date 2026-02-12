#!/usr/bin/env bash
#
# Universal CLI upgrade functionality
# Supports all installation methods: portable, manual, ref, homebrew, dnf, yum, apt, zypper
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

  # Unknown version is always considered older
  if [[ "$v1" == "unknown" && "$v2" != "unknown" ]]; then
    return 0
  fi
  if [[ "$v1" == "unknown" || "$v2" == "unknown" ]]; then
    return 1
  fi

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
# Detect installation method
# Checks portable mode first, then reads .install-method file,
# falls back to dynamic detection via package manager queries.
# Outputs:
#   Installation method string: portable, manual, ref, homebrew, rpm, apt, unknown
# Returns:
#   0 - Success
#######################################
radp_cli_detect_install_method() {
  # 1. Portable mode (radp-bf only)
  if radp_cli_is_portable_mode; then
    echo "portable"
    return 0
  fi

  local app_root="${RADP_APP_ROOT:-}"
  [[ -z "$app_root" ]] && app_root="$(dirname "${gr_fw_root_path:-}")"

  # 2. Read .install-method file
  if [[ -n "$app_root" && -f "$app_root/.install-method" ]]; then
    local method
    method="$(cat "$app_root/.install-method")"

    # 3. Distinguish "ref" from "manual"
    if [[ "$method" == "manual" && -f "$app_root/.install-ref" ]]; then
      local ref
      ref="$(cat "$app_root/.install-ref")"
      # If ref is NOT a semver tag, it's a ref install (branch/SHA)
      if [[ ! "$ref" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        echo "ref"
        return 0
      fi
    fi

    echo "$method"
    return 0
  fi

  # 4. Dynamic fallback: detect via package manager
  local repo_info
  repo_info="$(radp_cli_get_repo_info 2>/dev/null)" || true
  local package_name="${repo_info##*/}"

  if [[ -n "$package_name" ]]; then
    if command -v brew >/dev/null 2>&1 && brew list "$package_name" >/dev/null 2>&1; then
      echo "homebrew"
      return 0
    fi
    if command -v rpm >/dev/null 2>&1 && rpm -q "$package_name" >/dev/null 2>&1; then
      echo "rpm"
      return 0
    fi
    if command -v dpkg >/dev/null 2>&1 && dpkg -s "$package_name" >/dev/null 2>&1; then
      echo "apt"
      return 0
    fi
  fi

  echo "unknown"
}

#######################################
# Get repository info (owner/repo) from .install-repo
# Outputs:
#   Repository string (e.g., xooooooooox/homelabctl)
# Returns:
#   0 - Success
#   1 - Not found
#######################################
radp_cli_get_repo_info() {
  local app_root="${RADP_APP_ROOT:-}"
  [[ -z "$app_root" ]] && app_root="$(dirname "${gr_fw_root_path:-}")"

  if [[ -n "$app_root" && -f "$app_root/.install-repo" ]]; then
    cat "$app_root/.install-repo"
    return 0
  fi

  # Fallback for portable radp-bf
  if radp_cli_is_portable_mode; then
    echo "$__RADP_BF_REPO"
    return 0
  fi

  radp_log_error "Cannot determine repository info (.install-repo not found)"
  return 1
}

#######################################
# Get current installed version
# Checks .install-version, gr_app_version, portable version in order
# Outputs:
#   Version string (e.g., v0.7.21)
# Returns:
#   0 - Success
#######################################
radp_cli_get_current_version() {
  local app_root="${RADP_APP_ROOT:-}"
  [[ -z "$app_root" ]] && app_root="$(dirname "${gr_fw_root_path:-}")"

  # 1. Check .install-version file
  if [[ -n "$app_root" && -f "$app_root/.install-version" ]]; then
    cat "$app_root/.install-version"
    return 0
  fi

  # 2. Check gr_app_version (set by app's version.sh when version command runs)
  if [[ -n "${gr_app_version:-}" ]]; then
    echo "$gr_app_version"
    return 0
  fi

  # 3. Extract gr_app_version from commands/version.sh file directly
  #    (same pattern used by banner.sh and 07_app.sh)
  if [[ -n "$app_root" ]]; then
    local version_sh="$app_root/src/main/shell/commands/version.sh"
    if [[ -f "$version_sh" ]]; then
      local extracted
      extracted="$(sed -n 's/^declare -gr gr_app_version="\([^"]*\)".*/\1/p' "$version_sh" 2>/dev/null | head -n 1)"
      if [[ -n "$extracted" ]]; then
        echo "$extracted"
        return 0
      fi
    fi
  fi

  # 4. Portable version
  if radp_cli_is_portable_mode; then
    echo "${RADP_BF_PORTABLE_VERSION:-unknown}"
    return 0
  fi

  echo "unknown"
}

#######################################
# Get latest release version from GitHub for this CLI
# Arguments:
#   1 - repo (optional): owner/repo, defaults to .install-repo
#   2 - version (optional): specific version to target
# Outputs:
#   Version string (e.g., v0.7.22)
# Returns:
#   0 - Success
#   1 - Failed
#######################################
radp_cli_get_latest_release_version() {
  local repo="${1:-}"
  local target_version="${2:-}"

  # If specific version requested, just return it
  if [[ -n "$target_version" ]]; then
    echo "$target_version"
    return 0
  fi

  if [[ -z "$repo" ]]; then
    if ! repo="$(radp_cli_get_repo_info)"; then
      return 1
    fi
  fi

  local api_url="https://api.github.com/repos/${repo}/releases/latest"
  local response
  local version

  if ! response=$(curl -fsSL --connect-timeout 10 --max-time 30 \
    -H "Accept: application/vnd.github.v3+json" \
    "$api_url" 2>/dev/null); then
    radp_log_error "Failed to fetch release information from GitHub"
    return 1
  fi

  # Extract tag_name
  if command -v yq >/dev/null 2>&1; then
    version=$(echo "$response" | yq -r '.tag_name' 2>/dev/null)
  else
    version=$(echo "$response" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*": *"\([^"]*\)".*/\1/')
  fi

  if [[ -z "$version" ]]; then
    radp_log_error "Failed to parse version from GitHub response"
    return 1
  fi

  echo "$version"
}

#######################################
# Upgrade the CLI to the latest version (or a specified version)
# Supports all installation methods.
#
# Options:
#   --check          Only check for updates
#   --force          Force upgrade even if at latest
#   --yes, -y        Skip confirmation prompt
#   --version <ver>  Target specific version (default: latest)
#   --help, -h       Show usage
# Returns:
#   0 - Success
#   1 - Failed
#######################################
radp_cli_upgrade_self() {
  local check_only=false
  local force=false
  local skip_confirm=false
  local target_version=""

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
      --yes|-y)
        skip_confirm=true
        shift
        ;;
      --version)
        target_version="${2:-}"
        if [[ -z "$target_version" ]]; then
          radp_log_error "--version requires a value"
          return 1
        fi
        shift 2
        ;;
      --help|-h)
        __radp_cli_upgrade_self_usage
        return 0
        ;;
      *)
        radp_log_error "Unknown option: $1"
        __radp_cli_upgrade_self_usage
        return 1
        ;;
    esac
  done

  # Detect install method
  local install_method
  install_method="$(radp_cli_detect_install_method)"
  radp_log_debug "Detected install method: $install_method"

  if [[ "$install_method" == "unknown" ]]; then
    radp_log_error "Cannot determine installation method"
    radp_log_info "Please reinstall using a supported method (manual, homebrew, dnf, apt, etc.)"
    return 1
  fi

  # Get repo info
  local repo
  if ! repo="$(radp_cli_get_repo_info)"; then
    return 1
  fi
  local package_name="${repo##*/}"
  local cli_name
  cli_name="$(basename "${0:-}")"

  # Get current version
  local current_version
  current_version="$(radp_cli_get_current_version)"
  echo "Current version: $current_version"
  echo "Install method:  $install_method"

  # Get latest version
  echo "Checking for updates..."
  local latest_version
  if ! latest_version="$(radp_cli_get_latest_release_version "$repo" "$target_version")"; then
    return 1
  fi
  echo "Latest version:  $latest_version"

  # Check if update is needed
  if ! radp_cli_version_lt "$current_version" "$latest_version"; then
    if [[ "$force" != "true" ]]; then
      echo "Already up to date."
      return 0
    fi
    echo "Forcing upgrade to $latest_version"
  else
    echo "Update available: $current_version -> $latest_version"
  fi

  # If check only, we're done
  if [[ "$check_only" == "true" ]]; then
    return 0
  fi

  # Confirm upgrade
  if [[ "$skip_confirm" != "true" ]]; then
    echo ""
    echo "Upgrade $cli_name from $current_version to $latest_version?"
    echo "  Method: $install_method"
    echo ""
    printf "Proceed? [y/N] "
    local answer
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      radp_log_info "Upgrade cancelled"
      return 0
    fi
  fi

  # Dispatch to method-specific handler
  case "$install_method" in
    portable)
      __radp_cli_upgrade_portable "$latest_version" "$force"
      ;;
    manual)
      __radp_cli_upgrade_manual "$repo" "$latest_version"
      ;;
    ref)
      __radp_cli_upgrade_ref "$repo"
      ;;
    homebrew)
      __radp_cli_upgrade_homebrew "$package_name"
      ;;
    rpm)
      __radp_cli_upgrade_rpm "$package_name"
      ;;
    apt)
      __radp_cli_upgrade_apt "$package_name"
      ;;
    *)
      radp_log_error "Unsupported install method for upgrade: $install_method"
      return 1
      ;;
  esac
}

#######################################
# Upgrade portable binary installation
#######################################
__radp_cli_upgrade_portable() {
  local version="$1"
  local force="${2:-false}"

  local full=false
  if radp_cli_is_full_version; then
    full=true
  fi

  local platform
  if ! platform=$(radp_cli_detect_platform); then
    return 1
  fi

  local download_url
  download_url=$(radp_cli_get_download_url "$version" "$platform" "$full")
  radp_log_info "Downloading $download_url ..."

  # Find current executable path
  local current_exe
  current_exe=$(command -v radp-bf 2>/dev/null || echo "")
  if [[ -z "$current_exe" ]]; then
    radp_log_error "Cannot determine current executable path"
    return 1
  fi

  local exe_dir
  exe_dir=$(dirname "$current_exe")
  if [[ ! -w "$exe_dir" ]]; then
    radp_log_error "No write permission to $exe_dir"
    return 1
  fi

  # Download to temp file
  local tmp_file
  tmp_file=$(mktemp)
  trap 'rm -f "$tmp_file"' EXIT

  if ! curl -fsSL --connect-timeout 30 --max-time 300 -o "$tmp_file" "$download_url"; then
    radp_log_error "Failed to download update"
    return 1
  fi

  chmod +x "$tmp_file"

  # Verify
  if ! "$tmp_file" version >/dev/null 2>&1; then
    radp_log_error "Downloaded file verification failed"
    return 1
  fi

  # Atomic replace
  if ! mv "$tmp_file" "$current_exe"; then
    radp_log_error "Failed to replace executable"
    return 1
  fi

  # Clear cache
  local cache_base="${XDG_CACHE_HOME:-$HOME/.cache}/radp-bf"
  if [[ -d "$cache_base" ]]; then
    radp_log_info "Clearing cache..."
    rm -rf "$cache_base"
  fi

  radp_log_info "Successfully upgraded to $version"
}

#######################################
# Upgrade manual installation via install.sh
#######################################
__radp_cli_upgrade_manual() {
  local repo="$1"
  local version="$2"

  local app_root="${RADP_APP_ROOT:-}"
  [[ -z "$app_root" ]] && app_root="$(dirname "${gr_fw_root_path:-}")"

  local install_url="https://raw.githubusercontent.com/${repo}/${version}/install.sh"
  radp_log_info "Downloading installer from $install_url ..."

  local installer
  if ! installer=$(curl -fsSL --connect-timeout 10 --max-time 30 "$install_url" 2>/dev/null); then
    radp_log_error "Failed to download install.sh"
    return 1
  fi

  radp_log_info "Running installer (mode=manual, install-dir=$app_root) ..."
  echo "$installer" | bash -s -- --mode manual --install-dir "$app_root"
}

#######################################
# Upgrade ref-based installation via install.sh
#######################################
__radp_cli_upgrade_ref() {
  local repo="$1"

  local app_root="${RADP_APP_ROOT:-}"
  [[ -z "$app_root" ]] && app_root="$(dirname "${gr_fw_root_path:-}")"

  # Read original ref
  local ref=""
  if [[ -f "$app_root/.install-ref" ]]; then
    ref="$(cat "$app_root/.install-ref")"
  fi

  if [[ -z "$ref" ]]; then
    radp_log_error "Cannot determine original ref"
    return 1
  fi

  # For ref installs, fetch latest from default branch
  local install_url="https://raw.githubusercontent.com/${repo}/${ref}/install.sh"
  radp_log_info "Downloading installer from $install_url ..."

  local installer
  if ! installer=$(curl -fsSL --connect-timeout 10 --max-time 30 "$install_url" 2>/dev/null); then
    radp_log_error "Failed to download install.sh"
    return 1
  fi

  radp_log_info "Running installer (ref=$ref, install-dir=$app_root) ..."
  echo "$installer" | bash -s -- --ref "$ref" --install-dir "$app_root"
}

#######################################
# Upgrade via Homebrew
#######################################
__radp_cli_upgrade_homebrew() {
  local package_name="$1"
  radp_log_info "Upgrading via Homebrew..."
  brew upgrade "$package_name"
}

#######################################
# Upgrade via RPM package manager (dnf/yum/zypper)
#######################################
__radp_cli_upgrade_rpm() {
  local package_name="$1"

  if command -v dnf >/dev/null 2>&1; then
    radp_log_info "Upgrading via dnf..."
    sudo dnf upgrade -y "$package_name"
  elif command -v yum >/dev/null 2>&1; then
    radp_log_info "Upgrading via yum..."
    sudo yum upgrade -y "$package_name"
  elif command -v zypper >/dev/null 2>&1; then
    radp_log_info "Upgrading via zypper..."
    sudo zypper refresh && sudo zypper update -y "$package_name"
  else
    radp_log_error "No supported RPM package manager found (dnf, yum, zypper)"
    return 1
  fi
}

#######################################
# Upgrade via APT
#######################################
__radp_cli_upgrade_apt() {
  local package_name="$1"
  radp_log_info "Upgrading via apt..."
  sudo apt-get update && sudo apt-get install --only-upgrade -y "$package_name"
}

#######################################
# Show upgrade usage
#######################################
__radp_cli_upgrade_self_usage() {
  local cli_name
  cli_name="$(basename "${0:-}")"
  cat <<USAGE
${cli_name} upgrade - Upgrade ${cli_name} to the latest version

Usage:
  ${cli_name} upgrade [options]

Options:
  --check          Only check for updates, don't install
  --force          Force upgrade even if already at latest version
  --yes, -y        Skip confirmation prompt
  --version <ver>  Target specific version (default: latest)
  -h, --help       Show this help

Examples:
  ${cli_name} upgrade              # Upgrade to latest version
  ${cli_name} upgrade --check      # Check for available updates
  ${cli_name} upgrade --yes        # Upgrade without confirmation
  ${cli_name} upgrade --version v0.7.20   # Upgrade to specific version

Supported installation methods:
  portable   Download and replace portable binary
  manual     Re-run install.sh from the target version
  ref        Re-run install.sh with original ref (branch/SHA)
  homebrew   brew upgrade <package>
  dnf/yum    sudo dnf/yum upgrade <package>
  apt        sudo apt-get install --only-upgrade <package>
  zypper     sudo zypper update <package>
USAGE
}
