#!/usr/bin/env bash
# toolkit module: net/05_github.sh
# GitHub API utilities

#######################################
# Get latest release version from GitHub repository
# Uses GitHub API with curl/wget fallback
# Globals:
#   None
# Arguments:
#   1 - repo: GitHub repository (owner/repo format)
#   --with-v: include leading 'v' if present in tag
# Outputs:
#   Version string (e.g., "1.2.3" or "v1.2.3" with --with-v)
# Returns:
#   0 - Success
#   1 - Failed to fetch or parse
#######################################
radp_net_github_latest_release() {
  local repo=""
  local with_v=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --with-v)
      with_v="true"
      shift
      ;;
    *)
      repo="$1"
      shift
      ;;
    esac
  done

  [[ -z "$repo" ]] && {
    radp_log_error "Repository required (owner/repo format)"
    return 1
  }

  local url="https://api.github.com/repos/${repo}/releases/latest"
  local response

  radp_log_debug "Fetching GitHub release: $url"

  if command -v curl &>/dev/null; then
    response=$(curl -fsSL "$url" 2>/dev/null)
  elif command -v wget &>/dev/null; then
    response=$(wget -qO- "$url" 2>/dev/null)
  else
    radp_log_error "Neither curl nor wget found"
    return 1
  fi

  [[ -z "$response" ]] && {
    radp_log_error "Failed to fetch release info for: $repo"
    return 1
  }

  # Extract tag_name from JSON response
  local tag
  tag=$(echo "$response" | grep -o '"tag_name":[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')

  [[ -z "$tag" ]] && {
    radp_log_error "Failed to parse release tag for: $repo"
    return 1
  }

  # Remove leading 'v' unless --with-v specified
  if [[ -z "$with_v" ]]; then
    tag="${tag#v}"
  fi

  echo "$tag"
}

#######################################
# Download asset from GitHub release
# Globals:
#   None
# Arguments:
#   1 - repo: GitHub repository (owner/repo format)
#   2 - asset_pattern: glob pattern to match asset name
#   3 - dest: destination file path
#   --version <ver>: specific version (default: latest)
# Returns:
#   0 - Success
#   1 - Download failed
#######################################
radp_net_github_download_asset() {
  local repo=""
  local asset_pattern=""
  local dest=""
  local version="latest"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --version)
      version="$2"
      shift 2
      ;;
    *)
      if [[ -z "$repo" ]]; then
        repo="$1"
      elif [[ -z "$asset_pattern" ]]; then
        asset_pattern="$1"
      elif [[ -z "$dest" ]]; then
        dest="$1"
      fi
      shift
      ;;
    esac
  done

  [[ -z "$repo" ]] && {
    radp_log_error "Repository required"
    return 1
  }
  [[ -z "$asset_pattern" ]] && {
    radp_log_error "Asset pattern required"
    return 1
  }
  [[ -z "$dest" ]] && {
    radp_log_error "Destination path required"
    return 1
  }

  # Get version if latest
  if [[ "$version" == "latest" ]]; then
    version=$(radp_net_github_latest_release "$repo" --with-v) || return 1
  fi

  # Ensure version has 'v' prefix for URL
  [[ "$version" != v* ]] && version="v$version"

  local release_url="https://api.github.com/repos/${repo}/releases/tags/${version}"
  local response

  radp_log_debug "Fetching release assets: $release_url"

  if command -v curl &>/dev/null; then
    response=$(curl -fsSL "$release_url" 2>/dev/null)
  elif command -v wget &>/dev/null; then
    response=$(wget -qO- "$release_url" 2>/dev/null)
  else
    radp_log_error "Neither curl nor wget found"
    return 1
  fi

  [[ -z "$response" ]] && {
    radp_log_error "Failed to fetch release: $repo@$version"
    return 1
  }

  # Find matching asset URL
  local asset_url
  asset_url=$(echo "$response" | grep -o '"browser_download_url":[[:space:]]*"[^"]*"' |
    sed 's/.*"\(http[^"]*\)"/\1/' |
    grep -E "$asset_pattern" | head -1)

  [[ -z "$asset_url" ]] && {
    radp_log_error "No asset matching '$asset_pattern' found in $repo@$version"
    return 1
  }

  radp_log_debug "Downloading asset: $asset_url"
  radp_io_download "$asset_url" "$dest"
}
