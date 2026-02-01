#!/usr/bin/env bash
#
# Bundle dependencies for radp-bash-framework portable full version
#
# Downloads and packages:
# - bash (static binary)
# - gnu-getopt (static binary)
# - yq (official binary)
#
# Usage:
#   ./bundle-deps.sh --platform darwin-arm64 --output ./build/deps
#
set -euo pipefail

#######################################
# Constants
#######################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dependency versions (use RADP_* prefix to avoid conflict with bash built-ins)
RADP_BASH_VERSION="${RADP_BASH_VERSION:-5.2.21}"
RADP_YQ_VERSION="${RADP_YQ_VERSION:-v4.44.1}"
RADP_UTIL_LINUX_VERSION="${RADP_UTIL_LINUX_VERSION:-2.39}"

# Download URLs
BASH_STATIC_BASE="https://github.com/robxu9/bash-static/releases/download"
YQ_BASE="https://github.com/mikefarah/yq/releases/download"

# Checksums file
CHECKSUMS_FILE="$SCRIPT_DIR/deps/checksums.txt"

#######################################
# Show usage
#######################################
usage() {
  cat <<'USAGE'
bundle-deps.sh - Bundle dependencies for portable full version

Usage:
  bundle-deps.sh [options]

Options:
  --platform <platform>   Target platform (required)
                         Supported: linux-amd64, linux-arm64, darwin-amd64, darwin-arm64
  --output <dir>         Output directory (required)
  --help                 Show this help

Examples:
  ./bundle-deps.sh --platform darwin-arm64 --output ./build/deps
  ./bundle-deps.sh --platform linux-amd64 --output ./deps
USAGE
}

#######################################
# Log functions
#######################################
log_info() {
  echo "[INFO] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_warn() {
  echo "[WARN] $*" >&2
}

#######################################
# Map platform to architecture names
#######################################
get_platform_info() {
  local platform="$1"
  local var_name="$2"

  case "$platform" in
    linux-amd64)
      case "$var_name" in
        os) echo "linux" ;;
        arch) echo "amd64" ;;
        bash_arch) echo "x86_64" ;;
        yq_name) echo "yq_linux_amd64" ;;
        getopt_arch) echo "x86_64" ;;
      esac
      ;;
    linux-arm64)
      case "$var_name" in
        os) echo "linux" ;;
        arch) echo "arm64" ;;
        bash_arch) echo "aarch64" ;;
        yq_name) echo "yq_linux_arm64" ;;
        getopt_arch) echo "aarch64" ;;
      esac
      ;;
    darwin-amd64)
      case "$var_name" in
        os) echo "darwin" ;;
        arch) echo "amd64" ;;
        bash_arch) echo "x86_64" ;;
        yq_name) echo "yq_darwin_amd64" ;;
        getopt_arch) echo "x86_64" ;;
      esac
      ;;
    darwin-arm64)
      case "$var_name" in
        os) echo "darwin" ;;
        arch) echo "arm64" ;;
        bash_arch) echo "aarch64" ;;
        yq_name) echo "yq_darwin_arm64" ;;
        getopt_arch) echo "aarch64" ;;
      esac
      ;;
    *)
      log_error "Unknown platform: $platform"
      return 1
      ;;
  esac
}

#######################################
# Download with retry
#######################################
download_file() {
  local url="$1"
  local output="$2"
  local max_retries=3
  local retry=0

  log_info "Downloading: $url"

  while [[ $retry -lt $max_retries ]]; do
    if curl -fsSL --connect-timeout 30 --max-time 300 -o "$output" "$url"; then
      return 0
    fi
    retry=$((retry + 1))
    log_warn "Download failed, retry $retry/$max_retries..."
    sleep 2
  done

  log_error "Failed to download: $url"
  return 1
}

#######################################
# Verify checksum
#######################################
verify_checksum() {
  local file="$1"
  local expected="$2"

  if [[ -z "$expected" ]]; then
    log_warn "No checksum available, skipping verification"
    return 0
  fi

  local actual
  if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$file" | cut -d' ' -f1)
  elif command -v shasum >/dev/null 2>&1; then
    actual=$(shasum -a 256 "$file" | cut -d' ' -f1)
  else
    log_warn "No sha256sum/shasum available, skipping verification"
    return 0
  fi

  if [[ "$actual" != "$expected" ]]; then
    log_error "Checksum mismatch!"
    log_error "  Expected: $expected"
    log_error "  Actual:   $actual"
    return 1
  fi

  log_info "Checksum verified"
}

#######################################
# Get expected checksum from file
#######################################
get_expected_checksum() {
  local name="$1"

  if [[ ! -f "$CHECKSUMS_FILE" ]]; then
    echo ""
    return 0
  fi

  grep "^$name " "$CHECKSUMS_FILE" 2>/dev/null | cut -d' ' -f2 || echo ""
}

#######################################
# Download bash static binary
#######################################
download_bash() {
  local platform="$1"
  local output_dir="$2"

  local os
  os=$(get_platform_info "$platform" "os")
  local bash_arch
  bash_arch=$(get_platform_info "$platform" "bash_arch")

  # For macOS, we need to handle differently as robxu9/bash-static doesn't provide macOS binaries
  if [[ "$os" == "darwin" ]]; then
    log_warn "Static bash for macOS is not available from bash-static releases"
    log_warn "The portable full version on macOS will use system bash or Homebrew bash"
    log_info "Creating wrapper script for macOS bash"

    # Create a wrapper that uses homebrew bash or system bash
    cat > "$output_dir/bash" <<'BASH_WRAPPER'
#!/bin/sh
# Wrapper to find suitable bash on macOS
if [ -x /opt/homebrew/bin/bash ]; then
  exec /opt/homebrew/bin/bash "$@"
elif [ -x /usr/local/bin/bash ]; then
  exec /usr/local/bin/bash "$@"
else
  exec /bin/bash "$@"
fi
BASH_WRAPPER
    chmod +x "$output_dir/bash"
    return 0
  fi

  # For Linux, download static bash
  local url="${BASH_STATIC_BASE}/${RADP_BASH_VERSION}/bash-${os}-${bash_arch}"
  local checksum_name="bash-${os}-${bash_arch}-${RADP_BASH_VERSION}"
  local expected_checksum
  expected_checksum=$(get_expected_checksum "$checksum_name")

  local tmp_file
  tmp_file=$(mktemp)

  if ! download_file "$url" "$tmp_file"; then
    rm -f "$tmp_file"
    return 1
  fi

  verify_checksum "$tmp_file" "$expected_checksum" || {
    rm -f "$tmp_file"
    return 1
  }

  mv "$tmp_file" "$output_dir/bash"
  chmod +x "$output_dir/bash"

  log_info "bash downloaded successfully"
}

#######################################
# Download yq binary
#######################################
download_yq() {
  local platform="$1"
  local output_dir="$2"

  local yq_name
  yq_name=$(get_platform_info "$platform" "yq_name")

  local url="${YQ_BASE}/${RADP_YQ_VERSION}/${yq_name}"
  local checksum_name="${yq_name}-${RADP_YQ_VERSION}"
  local expected_checksum
  expected_checksum=$(get_expected_checksum "$checksum_name")

  local tmp_file
  tmp_file=$(mktemp)

  if ! download_file "$url" "$tmp_file"; then
    rm -f "$tmp_file"
    return 1
  fi

  verify_checksum "$tmp_file" "$expected_checksum" || {
    rm -f "$tmp_file"
    return 1
  }

  mv "$tmp_file" "$output_dir/yq"
  chmod +x "$output_dir/yq"

  log_info "yq downloaded successfully"
}

#######################################
# Download or build gnu-getopt
#######################################
download_getopt() {
  local platform="$1"
  local output_dir="$2"

  local os
  os=$(get_platform_info "$platform" "os")

  # For macOS, create a wrapper that uses Homebrew gnu-getopt
  if [[ "$os" == "darwin" ]]; then
    log_warn "Static gnu-getopt for macOS requires Homebrew installation"
    log_info "Creating wrapper script for macOS getopt"

    cat > "$output_dir/getopt" <<'GETOPT_WRAPPER'
#!/bin/sh
# Wrapper to find gnu-getopt on macOS
if [ -x /opt/homebrew/opt/gnu-getopt/bin/getopt ]; then
  exec /opt/homebrew/opt/gnu-getopt/bin/getopt "$@"
elif [ -x /usr/local/opt/gnu-getopt/bin/getopt ]; then
  exec /usr/local/opt/gnu-getopt/bin/getopt "$@"
else
  echo "Error: GNU getopt not found. Install with: brew install gnu-getopt" >&2
  exit 1
fi
GETOPT_WRAPPER
    chmod +x "$output_dir/getopt"
    return 0
  fi

  # For Linux, try to download pre-built static getopt or use system getopt
  # Since there's no official static getopt release, we'll create a wrapper
  # that copies the system getopt or builds from source

  log_info "Creating getopt wrapper for Linux"

  # Check if we're building on the target platform
  local current_arch
  current_arch=$(uname -m)
  local target_arch
  target_arch=$(get_platform_info "$platform" "getopt_arch")

  if [[ "$current_arch" == "$target_arch" ]] && command -v getopt >/dev/null 2>&1; then
    # Try to copy system getopt if it's statically linked or use ldd to check
    local system_getopt
    system_getopt=$(command -v getopt)

    # Check if it's a static binary
    if file "$system_getopt" | grep -q "statically linked"; then
      log_info "Copying statically linked system getopt"
      cp "$system_getopt" "$output_dir/getopt"
      chmod +x "$output_dir/getopt"
      return 0
    fi

    # For dynamically linked getopt, we'll include it anyway
    # The portable version will work on compatible systems
    log_warn "System getopt is dynamically linked, copying anyway"
    cp "$system_getopt" "$output_dir/getopt"
    chmod +x "$output_dir/getopt"
    return 0
  fi

  # Fallback: create a wrapper script
  log_warn "Cannot bundle getopt for cross-platform build"
  log_info "Creating fallback getopt wrapper"

  cat > "$output_dir/getopt" <<'GETOPT_FALLBACK'
#!/bin/sh
# Fallback wrapper for gnu-getopt
# This wrapper tries to find a suitable getopt on the system
for getopt_path in /usr/bin/getopt /bin/getopt; do
  if [ -x "$getopt_path" ]; then
    exec "$getopt_path" "$@"
  fi
done
echo "Error: getopt not found" >&2
exit 1
GETOPT_FALLBACK
  chmod +x "$output_dir/getopt"
}

#######################################
# Main
#######################################
main() {
  local platform=""
  local output_dir=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --platform)
        platform="$2"
        shift 2
        ;;
      --output)
        output_dir="$2"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done

  # Validate arguments
  if [[ -z "$platform" ]]; then
    log_error "--platform is required"
    usage
    exit 1
  fi

  if [[ -z "$output_dir" ]]; then
    log_error "--output is required"
    usage
    exit 1
  fi

  log_info "Bundling dependencies for $platform"

  # Create output directory
  mkdir -p "$output_dir"

  # Download dependencies
  download_bash "$platform" "$output_dir"
  download_yq "$platform" "$output_dir"
  download_getopt "$platform" "$output_dir"

  log_info "Dependencies bundled successfully in $output_dir"

  # List bundled files
  log_info "Bundled files:"
  ls -la "$output_dir"
}

main "$@"
