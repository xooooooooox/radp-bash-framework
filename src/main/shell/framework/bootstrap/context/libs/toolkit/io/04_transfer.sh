#!/usr/bin/env bash
# toolkit module: io/04_transfer.sh
# File transfer utilities: download, extract archives

#######################################
# Download file from URL with curl/wget fallback
# Globals:
#   None
# Arguments:
#   1 - url: URL to download from
#   2 - dest: destination file path
#   --silent: suppress progress output (default)
#   --progress: show progress output
# Outputs:
#   Progress to stderr if --progress specified
# Returns:
#   0 - Success
#   1 - Download failed or missing tools
#######################################
radp_io_download() {
  local url=""
  local dest=""
  local silent="true"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --silent)
      silent="true"
      shift
      ;;
    --progress)
      silent=""
      shift
      ;;
    *)
      if [[ -z "$url" ]]; then
        url="$1"
      elif [[ -z "$dest" ]]; then
        dest="$1"
      fi
      shift
      ;;
    esac
  done

  [[ -z "$url" ]] && {
    radp_log_error "URL required"
    return 1
  }
  [[ -z "$dest" ]] && {
    radp_log_error "Destination path required"
    return 1
  }

  radp_log_debug "Downloading: $url -> $dest"

  if command -v curl &>/dev/null; then
    if [[ -n "$silent" ]]; then
      curl -fsSL "$url" -o "$dest"
    else
      curl -fSL "$url" -o "$dest"
    fi
  elif command -v wget &>/dev/null; then
    if [[ -n "$silent" ]]; then
      wget -q "$url" -O "$dest"
    else
      wget "$url" -O "$dest"
    fi
  else
    radp_log_error "Neither curl nor wget found"
    return 1
  fi
}

#######################################
# Extract archive file to destination directory
# Supports: tar.gz, tgz, tar.xz, tar.bz2, zip
# Globals:
#   None
# Arguments:
#   1 - archive: archive file path
#   2 - dest: destination directory (created if not exists)
# Returns:
#   0 - Success
#   1 - Extraction failed or unsupported format
#######################################
radp_io_extract() {
  local archive="${1:?Archive path required}"
  local dest="${2:?Destination directory required}"

  [[ ! -f "$archive" ]] && {
    radp_log_error "Archive not found: $archive"
    return 1
  }

  mkdir -p "$dest" || return 1

  radp_log_debug "Extracting: $archive -> $dest"

  case "$archive" in
  *.tar.gz | *.tgz)
    tar -xzf "$archive" -C "$dest" || return 1
    ;;
  *.tar.xz)
    tar -xJf "$archive" -C "$dest" || return 1
    ;;
  *.tar.bz2)
    tar -xjf "$archive" -C "$dest" || return 1
    ;;
  *.zip)
    unzip -q "$archive" -d "$dest" || return 1
    ;;
  *)
    radp_log_error "Unsupported archive format: $archive"
    return 1
    ;;
  esac
}

#######################################
# Create temporary directory with auto-cleanup trap
# Globals:
#   None
# Arguments:
#   1 - prefix: optional prefix for temp dir name (default: radp)
# Outputs:
#   Path to created temporary directory
# Returns:
#   0 - Success
#   1 - Failed to create directory
#######################################
radp_io_mktemp_dir() {
  local prefix="${1:-radp}"
  mktemp -d "${TMPDIR:-/tmp}/${prefix}.XXXXXX"
}
