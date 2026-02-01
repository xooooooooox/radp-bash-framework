#!/bin/sh
# radp-bf portable bootstrap
# This script extracts and runs the bundled radp-bash-framework
#
# Version: __VERSION__
# Archive starts at line: __ARCHIVE_LINE__
# Full version (bundled deps): __IS_FULL__

set -e

# Configuration
VERSION="__VERSION__"
ARCHIVE_LINE="__ARCHIVE_LINE__"
IS_FULL="__IS_FULL__"

# Cache directory
CACHE_BASE="${XDG_CACHE_HOME:-$HOME/.cache}/radp-bf"
CACHE_DIR="$CACHE_BASE/$VERSION"

# Export portable mode indicator
export RADP_BF_PORTABLE=1
export RADP_BF_PORTABLE_VERSION="$VERSION"

#######################################
# Log functions
#######################################
log_info() {
  echo "[radp-bf] $*" >&2
}

log_error() {
  echo "[radp-bf] ERROR: $*" >&2
}

#######################################
# Extract archive to cache directory
#######################################
extract_archive() {
  log_info "Extracting radp-bf $VERSION..."

  # Create cache directory
  mkdir -p "$CACHE_DIR"

  # Extract archive (skip bootstrap script lines)
  tail -n +"$ARCHIVE_LINE" "$0" | tar xz -C "$CACHE_DIR" 2>/dev/null || {
    log_error "Failed to extract archive"
    rm -rf "$CACHE_DIR"
    exit 1
  }

  # Mark as extracted
  echo "$VERSION" > "$CACHE_DIR/.extracted"

  log_info "Extracted to $CACHE_DIR"
}

#######################################
# Check if extraction is needed
#######################################
needs_extraction() {
  # Check if .extracted marker exists and matches version
  if [ -f "$CACHE_DIR/.extracted" ]; then
    local cached_version
    cached_version=$(cat "$CACHE_DIR/.extracted" 2>/dev/null || echo "")
    if [ "$cached_version" = "$VERSION" ]; then
      return 1  # No extraction needed
    fi
  fi
  return 0  # Extraction needed
}

#######################################
# Clean old cached versions
#######################################
cleanup_old_versions() {
  if [ -d "$CACHE_BASE" ]; then
    # Keep only current version, remove others
    for dir in "$CACHE_BASE"/v*; do
      if [ -d "$dir" ] && [ "$dir" != "$CACHE_DIR" ]; then
        rm -rf "$dir" 2>/dev/null || true
      fi
    done
  fi
}

#######################################
# Setup bundled dependencies (full version only)
#######################################
setup_bundled_deps() {
  if [ "$IS_FULL" = "true" ] && [ -d "$CACHE_DIR/deps" ]; then
    # Prepend bundled deps to PATH
    export PATH="$CACHE_DIR/deps:$PATH"
    # Export indicator for framework to skip dependency checks
    export RADP_BF_BUNDLED_DEPS="$CACHE_DIR/deps"
  fi
}

#######################################
# Find suitable bash
#######################################
find_bash() {
  # For full version, use bundled bash if available
  if [ "$IS_FULL" = "true" ] && [ -x "$CACHE_DIR/deps/bash" ]; then
    echo "$CACHE_DIR/deps/bash"
    return 0
  fi

  # Try common locations for bash 4.3+
  for bash_path in \
    /opt/homebrew/bin/bash \
    /usr/local/bin/bash \
    /usr/bin/bash \
    /bin/bash; do
    if [ -x "$bash_path" ]; then
      echo "$bash_path"
      return 0
    fi
  done

  log_error "bash not found"
  exit 1
}

#######################################
# Handle self-update command
#######################################
handle_self_update() {
  case "${1:-}" in
    self-update)
      # Pass to radp-bf which has the self-update implementation
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

#######################################
# Main entry point
#######################################
main() {
  # Extract if needed
  if needs_extraction; then
    extract_archive
    cleanup_old_versions
  fi

  # Setup bundled dependencies
  setup_bundled_deps

  # Export framework paths for radp-bf
  export RADP_BF_PORTABLE_ROOT="$CACHE_DIR"

  # Find bash and execute radp-bf
  BASH_BIN=$(find_bash)

  # Execute radp-bf with all arguments
  exec "$BASH_BIN" "$CACHE_DIR/bin/radp-bf" "$@"
}

main "$@"
exit 0
# Archive data follows (do not edit below this line)
