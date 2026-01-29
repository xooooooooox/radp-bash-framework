#!/usr/bin/env bash
# Stage 2 common library
#
# Provides utility functions for requirement modules.

#######################################
# Log info message
# Arguments:
#   @ - message
# Outputs:
#   Message to stderr
#######################################
__stage2_log_info() {
  echo "Preflight: $*" >&2
}

#######################################
# Log error message
# Arguments:
#   @ - message
# Outputs:
#   Message to stderr
#######################################
__stage2_log_error() {
  echo "Error: $*" >&2
}

#######################################
# Log debug message
# Arguments:
#   @ - message
# Outputs:
#   Message to stderr (only if RADP_DEBUG=true)
#######################################
__stage2_log_debug() {
  [[ "${RADP_DEBUG:-}" == "true" ]] && echo "Debug: $*" >&2
  return 0
}

#######################################
# Get sudo command if needed
# Outputs:
#   "sudo" or empty string
# Returns:
#   0 - success
#   1 - needs sudo but not available
#######################################
__stage2_get_sudo() {
  if [[ $EUID -eq 0 ]]; then
    echo ""
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    echo "sudo"
    return 0
  fi

  __stage2_log_error "Root or sudo required"
  return 1
}

#######################################
# Run command with optional sudo
# Arguments:
#   1 - sudo command (or empty)
#   @ - command and arguments
#######################################
__stage2_run_sudo() {
  local sudo_cmd="$1"
  shift

  if [[ -n "$sudo_cmd" ]]; then
    "$sudo_cmd" "$@"
  else
    "$@"
  fi
}

#######################################
# Download file using curl or wget
# Arguments:
#   1 - URL
#   2 - output path
#   3 - mode: "quiet" (default) or "progress"
# Returns:
#   0 - success
#   1 - failed
#######################################
__stage2_download() {
  local url="$1"
  local out="$2"
  local mode="${3:-quiet}"

  if [[ "$mode" == "progress" ]]; then
    if command -v curl >/dev/null 2>&1; then
      curl -fL --progress-bar "$url" -o "$out"
      return $?
    elif command -v wget >/dev/null 2>&1; then
      wget --progress=dot:mega -O "$out" "$url"
      return $?
    fi
  else
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$url" -o "$out"
      return $?
    elif command -v wget >/dev/null 2>&1; then
      wget -q -O "$out" "$url"
      return $?
    fi
  fi

  __stage2_log_error "No download tool available (curl/wget)"
  return 1
}

#######################################
# Create temporary directory
# Arguments:
#   1 - prefix (optional)
# Outputs:
#   Path to temp directory
# Returns:
#   0 - success
#   1 - failed
#######################################
__stage2_make_temp_dir() {
  local prefix="${1:-radp}"
  local tmpdir

  tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t "$prefix")
  if [[ ! -d "$tmpdir" ]]; then
    __stage2_log_error "Failed to create temp directory"
    return 1
  fi

  echo "$tmpdir"
}

#######################################
# Detect OS type
# Outputs:
#   "darwin", "linux", or "unknown"
#######################################
__stage2_detect_os() {
  case "$(uname -s)" in
    Darwin) echo "darwin" ;;
    Linux)  echo "linux" ;;
    *)      echo "unknown" ;;
  esac
}

#######################################
# Detect architecture
# Outputs:
#   "amd64", "arm64", "arm", "386", or original
#######################################
__stage2_detect_arch() {
  local arch
  arch=$(uname -m)

  case "$arch" in
    x86_64|amd64)       echo "amd64" ;;
    aarch64|arm64)      echo "arm64" ;;
    armv7l|armv6l|arm)  echo "arm" ;;
    i386|i686)          echo "386" ;;
    *)                  echo "$arch" ;;
  esac
}

#######################################
# Detect package manager
# Outputs:
#   "apt", "dnf", "yum", "apk", "brew", or "unknown"
#######################################
__stage2_detect_pm() {
  if [[ "$(__stage2_detect_os)" == "darwin" ]]; then
    echo "brew"
    return
  fi

  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v apk >/dev/null 2>&1; then
    echo "apk"
  else
    echo "unknown"
  fi
}

#######################################
# Install packages via system package manager
# Arguments:
#   @ - package names
# Returns:
#   0 - success
#   1 - failed
#######################################
__stage2_install_packages() {
  local pm
  pm=$(__stage2_detect_pm)

  local sudo_cmd
  sudo_cmd=$(__stage2_get_sudo) || return 1

  case "$pm" in
    apt)
      __stage2_log_info "Installing packages via apt..."
      __stage2_run_sudo "$sudo_cmd" apt-get update -qq >/dev/null 2>&1
      DEBIAN_FRONTEND=noninteractive __stage2_run_sudo "$sudo_cmd" apt-get install -y -qq "$@" >/dev/null 2>&1
      ;;
    dnf)
      __stage2_log_info "Installing packages via dnf..."
      __stage2_run_sudo "$sudo_cmd" dnf install -y -q "$@" >/dev/null 2>&1
      ;;
    yum)
      __stage2_log_info "Installing packages via yum..."
      __stage2_run_sudo "$sudo_cmd" yum install -y -q "$@" >/dev/null 2>&1
      ;;
    apk)
      __stage2_log_info "Installing packages via apk..."
      __stage2_run_sudo "$sudo_cmd" apk add --quiet "$@" >/dev/null 2>&1
      ;;
    brew)
      __stage2_log_info "Installing packages via brew..."
      brew install "$@" >/dev/null 2>&1
      ;;
    *)
      __stage2_log_error "Unsupported package manager"
      return 1
      ;;
  esac
}
