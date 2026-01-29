#!/bin/sh
# Stage 1 module: Bash version check and installation
#
# Functions:
#   __stage1_bash_check     - Check if bash meets version requirement
#   __stage1_bash_install   - Install bash from source

#######################################
# Compare version strings (major.minor format)
# Arguments:
#   1 - current version
#   2 - required version
# Returns:
#   0 - current >= required
#   1 - current < required
#######################################
__stage1_version_ge() {
  __curr="$1"
  __req="$2"

  [ -z "$__req" ] && return 0
  [ -z "$__curr" ] && return 1

  __curr_major="${__curr%%.*}"
  __curr_rest="${__curr#*.}"
  __curr_minor="${__curr_rest%%.*}"
  [ -z "$__curr_minor" ] && __curr_minor=0

  __req_major="${__req%%.*}"
  __req_rest="${__req#*.}"
  __req_minor="${__req_rest%%.*}"
  [ -z "$__req_minor" ] && __req_minor=0

  [ "$__curr_major" -gt "$__req_major" ] && return 0
  [ "$__curr_major" -eq "$__req_major" ] && [ "$__curr_minor" -ge "$__req_minor" ] && return 0
  return 1
}

#######################################
# Get bash version from binary or BASH_VERSION
# Arguments:
#   1 - bash binary path (optional, uses BASH_VERSION if not provided)
# Outputs:
#   Version string (e.g., "5.2.21")
#######################################
__stage1_bash_get_version() {
  __bin="$1"

  if [ -n "$__bin" ]; then
    "$__bin" --version 2>/dev/null | sed -n '1s/.*version[[:space:]]*\([0-9.]*\).*/\1/p'
  elif [ -n "$BASH_VERSION" ]; then
    echo "${BASH_VERSION%%(*}"
  fi
}

#######################################
# Check if bash meets version requirement
# Arguments:
#   1 - required version (e.g., "4.3")
#   2 - bash binary path (optional)
# Returns:
#   0 - meets requirement
#   1 - does not meet requirement
#######################################
__stage1_bash_check() {
  __req_ver="$1"
  __bash_bin="${2:-}"

  __ver="$(__stage1_bash_get_version "$__bash_bin")"
  [ -z "$__ver" ] && return 1

  __stage1_version_ge "$__ver" "$__req_ver"
}

#######################################
# Download file using curl or wget
# Arguments:
#   1 - URL
#   2 - output path
#   3 - mode: "quiet" or "progress"
# Returns:
#   0 - success
#   1 - failed
#######################################
__stage1_download() {
  __url="$1"
  __out="$2"
  __mode="${3:-quiet}"

  if [ "$__mode" = "progress" ]; then
    if command -v curl >/dev/null 2>&1; then
      curl -fL --progress-bar "$__url" -o "$__out"
      return $?
    elif command -v wget >/dev/null 2>&1; then
      wget --progress=dot:mega -O "$__out" "$__url"
      return $?
    fi
  else
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$__url" -o "$__out"
      return $?
    elif command -v wget >/dev/null 2>&1; then
      wget -q -O "$__out" "$__url"
      return $?
    fi
  fi
  return 1
}

#######################################
# Get sudo command if needed
# Outputs:
#   "sudo" or empty string
# Returns:
#   0 - success
#   1 - needs sudo but not available
#######################################
__stage1_get_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    echo ""
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    echo "sudo"
    return 0
  fi

  echo "Error: root or sudo required" >&2
  return 1
}

#######################################
# Install build dependencies for bash
# Arguments:
#   1 - sudo command (or empty)
# Returns:
#   0 - success
#   1 - failed
#######################################
__stage1_install_build_deps() {
  __sudo="$1"

  if command -v apt-get >/dev/null 2>&1; then
    echo "Preflight: installing build dependencies (apt)..." >&2
    $__sudo apt-get update >/dev/null 2>&1
    DEBIAN_FRONTEND=noninteractive $__sudo apt-get install -y \
      build-essential bison libreadline-dev libncurses-dev \
      ca-certificates curl wget tar gzip patch >/dev/null 2>&1
    return $?
  fi

  if command -v dnf >/dev/null 2>&1; then
    echo "Preflight: installing build dependencies (dnf)..." >&2
    $__sudo dnf install -y \
      gcc make bison readline-devel ncurses-devel \
      ca-certificates curl wget tar gzip patch >/dev/null 2>&1
    return $?
  fi

  if command -v yum >/dev/null 2>&1; then
    echo "Preflight: installing build dependencies (yum)..." >&2
    # Fix CentOS 7 repos if needed
    if [ -f /etc/centos-release ] && grep -q "release 7" /etc/centos-release 2>/dev/null; then
      $__sudo sed -i -r \
        -e 's|^mirrorlist=|#mirrorlist=|g' \
        -e 's|^#?baseurl=http://mirror.centos.org|baseurl=https://vault.centos.org|g' \
        /etc/yum.repos.d/CentOS-*.repo 2>/dev/null || true
    fi
    $__sudo yum install -y \
      gcc make bison readline-devel ncurses-devel \
      ca-certificates curl wget tar gzip patch >/dev/null 2>&1
    return $?
  fi

  echo "Error: unsupported package manager" >&2
  return 1
}

#######################################
# Install bash from source
# Arguments:
#   1 - required version (for reference)
#   2 - version to install (e.g., "5.2.21")
# Globals:
#   gw_fw_requirements_bash_reexec - Set to new bash path on success
# Returns:
#   0 - success
#   1 - failed
#######################################
__stage1_bash_install() {
  __req_ver="$1"
  __install_ver="${2:-5.2}"

  # Parse version
  __major="${__install_ver%%.*}"
  __rest="${__install_ver#*.}"
  __minor="${__rest%%.*}"
  __rest2="${__rest#*.}"
  __patch="${__rest2%%.*}"
  [ "$__patch" = "$__rest" ] && __patch=0
  [ -z "$__minor" ] && __minor=0
  [ -z "$__patch" ] && __patch=0
  __base_ver="${__major}.${__minor}"

  echo "Preflight: installing bash $__install_ver from source..." >&2

  # Get sudo
  __sudo="$(__stage1_get_sudo)" || return 1

  # Install build dependencies
  __stage1_install_build_deps "$__sudo" || return 1

  # Create temp directory
  __tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t "bash_build")
  [ -d "$__tmpdir" ] || return 1

  # Cleanup on exit
  trap 'rm -rf "$__tmpdir"' EXIT INT TERM

  # Download source
  __tarball="bash-${__base_ver}.tar.gz"
  __tarpath="$__tmpdir/$__tarball"
  __url="https://ftp.gnu.org/gnu/bash/$__tarball"
  __mirror="https://mirrors.kernel.org/gnu/bash/$__tarball"

  echo "Preflight: downloading bash source..." >&2
  if ! __stage1_download "$__url" "$__tarpath" "progress"; then
    if ! __stage1_download "$__mirror" "$__tarpath" "progress"; then
      echo "Error: failed to download bash source" >&2
      return 1
    fi
  fi

  # Extract
  tar -xzf "$__tarpath" -C "$__tmpdir" || return 1
  __srcdir="$__tmpdir/bash-${__base_ver}"
  [ -d "$__srcdir" ] || return 1

  # Apply patches if needed
  if [ "$__patch" -gt 0 ]; then
    echo "Preflight: applying patches..." >&2
    __patch_prefix="bash${__major}${__minor}"
    __patch_url="https://ftp.gnu.org/gnu/bash/bash-${__base_ver}-patches"
    __i=1
    while [ "$__i" -le "$__patch" ]; do
      __pfile="${__patch_prefix}-$(printf '%03d' "$__i")"
      __ppath="$__tmpdir/$__pfile"
      if __stage1_download "$__patch_url/$__pfile" "$__ppath" "quiet"; then
        (cd "$__srcdir" && patch -p0 < "$__ppath") || true
      fi
      __i=$((__i + 1))
    done
  fi

  # Build
  echo "Preflight: configuring..." >&2
  (cd "$__srcdir" && ./configure --prefix=/usr/local >/dev/null 2>&1) || return 1

  __jobs=1
  command -v nproc >/dev/null 2>&1 && __jobs=$(nproc)

  echo "Preflight: building (jobs=$__jobs)..." >&2
  (cd "$__srcdir" && make -j "$__jobs" >/dev/null 2>&1) || return 1

  echo "Preflight: installing to /usr/local/bin/bash..." >&2
  (cd "$__srcdir" && $__sudo make install >/dev/null 2>&1) || return 1

  # Verify and set reexec path
  if [ -x /usr/local/bin/bash ]; then
    gw_fw_requirements_bash_reexec="/usr/local/bin/bash"
    echo "Preflight: bash installed successfully" >&2
    return 0
  fi

  return 1
}
