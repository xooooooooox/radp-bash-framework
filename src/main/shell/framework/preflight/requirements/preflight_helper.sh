#!/bin/sh

#######################################
# Resolve sudo command if needed
# Globals:
#   None
# Arguments:
#   1 - err_msg: error message when sudo missing
# Outputs:
#   sudo command or empty string
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__fw_requirements_resolve_sudo() {
  __err_msg=${1:-"Error: Installing requires root or sudo."}
  if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
      echo "sudo"
      return 0
    fi
    echo "$__err_msg" >&2
    return 1
  fi
  echo ""
  return 0
}

#######################################
# Run command with optional sudo
# Globals:
#   None
# Arguments:
#   1 - sudo_cmd: sudo command or empty
#   @ - command and args
# Outputs:
#   None
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__fw_requirements_run_with_sudo() {
  __sudo_cmd=${1:-}
  shift
  if [ -n "$__sudo_cmd" ]; then
    "$__sudo_cmd" "$@"
  else
    "$@"
  fi
}

#######################################
# Fix CentOS 7 EOL yum repos (vault)
# Globals:
#   None
# Arguments:
#   1 - sudo_cmd: sudo command or empty
# Outputs:
#   None
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__fw_requirements_fix_yum_repo_for_centos7() {
  __sudo_cmd=${1:-}
  __os_release=""
  if [ -f /etc/centos-release ]; then
    __os_release=$(cat /etc/centos-release 2>/dev/null)
  elif [ -f /etc/redhat-release ]; then
    __os_release=$(cat /etc/redhat-release 2>/dev/null)
  fi
  case "$__os_release" in
  *"CentOS Linux release 7"*) ;;
  *) return 0 ;;
  esac

  set -- /etc/yum.repos.d/CentOS-*.repo
  if [ ! -e "$1" ]; then
    return 0
  fi

  echo "Preflight: fixing CentOS 7 yum repos (vault)..."
  if [ -n "$__sudo_cmd" ]; then
    __fw_requirements_run_with_sudo "$__sudo_cmd" sed -i -r \
      -e 's|^mirrorlist=|#mirrorlist=|g' \
      -e 's|^#?baseurl=http://mirror.centos.org/centos|baseurl=https://vault.centos.org/centos|g' \
      -e 's|^#?baseurl=http://mirror.centos.org/altarch|baseurl=https://vault.centos.org/altarch|g' \
      -e 's|^#?baseurl=http://download.fedoraproject.org|baseurl=http://download.fedoraproject.org|g' \
      /etc/yum.repos.d/CentOS-*.repo >/dev/null 2>&1 || return 1
  else
    sed -i -r \
      -e 's|^mirrorlist=|#mirrorlist=|g' \
      -e 's|^#?baseurl=http://mirror.centos.org/centos|baseurl=https://vault.centos.org/centos|g' \
      -e 's|^#?baseurl=http://mirror.centos.org/altarch|baseurl=https://vault.centos.org/altarch|g' \
      -e 's|^#?baseurl=http://download.fedoraproject.org|baseurl=http://download.fedoraproject.org|g' \
      /etc/yum.repos.d/CentOS-*.repo >/dev/null 2>&1 || return 1
  fi
  return 0
}

#######################################
# Install packages via apt/dnf/yum
# Globals:
#   None
# Arguments:
#   1 - sudo_cmd: sudo command or empty
#   2 - apt_pkgs: apt package list
#   3 - dnf_pkgs: dnf package list
#   4 - yum_pkgs: yum package list
#   5 - label: log label
# Outputs:
#   None
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__fw_requirements_install_packages() {
  __sudo_cmd=${1:-}
  __apt_pkgs=${2:-}
  __dnf_pkgs=${3:-}
  __yum_pkgs=${4:-}
  __label=${5:-dependencies}

  if command -v apt-get >/dev/null 2>&1; then
    echo "Preflight: installing $__label (apt)..."
    __fw_requirements_run_with_sudo "$__sudo_cmd" apt-get update >/dev/null 2>&1 || return 1
    set -- $__apt_pkgs
    DEBIAN_FRONTEND=noninteractive __fw_requirements_run_with_sudo "$__sudo_cmd" apt-get install -y \
      "$@" >/dev/null 2>&1 || return 1
    return 0
  fi
  if command -v dnf >/dev/null 2>&1; then
    echo "Preflight: installing $__label (dnf)..."
    set -- $__dnf_pkgs
    __fw_requirements_run_with_sudo "$__sudo_cmd" dnf install -y \
      "$@" >/dev/null 2>&1 || return 1
    return 0
  fi
  if command -v yum >/dev/null 2>&1; then
    echo "Preflight: installing $__label (yum)..."
    __fw_requirements_fix_yum_repo_for_centos7 "$__sudo_cmd" || return 1
    set -- $__yum_pkgs
    __fw_requirements_run_with_sudo "$__sudo_cmd" yum install -y \
      "$@" >/dev/null 2>&1 || return 1
    return 0
  fi
  echo "Error: Unsupported OS. Please install $__label manually." >&2
  return 1
}

#######################################
# Download file via curl or wget
# Globals:
#   None
# Arguments:
#   1 - url: download url
#   2 - out: output file path
#   3 - mode: progress or quiet
# Outputs:
#   None
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__fw_requirements_download_file() {
  __url=${1:-}
  __out=${2:-}
  __mode=${3:-quiet}
  if [ "$__mode" = "progress" ]; then
    if command -v curl >/dev/null 2>&1; then
      curl -fL --progress-bar "$__url" -o "$__out"
      return $?
    fi
    if command -v wget >/dev/null 2>&1; then
      wget --progress=dot:mega -O "$__out" "$__url"
      return $?
    fi
    return 1
  fi
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$__url" -o "$__out"
    return $?
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -q -O "$__out" "$__url"
    return $?
  fi
  return 1
}

#######################################
# Create temp directory
# Globals:
#   None
# Arguments:
#   1 - prefix: mktemp prefix
# Outputs:
#   temp dir path
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__fw_requirements_mktemp_dir() {
  __prefix=${1:-radp_tmp}
  __tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t "$__prefix")
  if [ -z "$__tmpdir" ] || [ ! -d "$__tmpdir" ]; then
    return 1
  fi
  echo "$__tmpdir"
  return 0
}

#######################################
# Cleanup temp directory
# Globals:
#   None
# Arguments:
#   1 - tmpdir: temp directory
# Outputs:
#   None
# Returns:
#   None
#######################################
__fw_requirements_cleanup_tmpdir() {
  __tmpdir=${1:-}
  if [ -n "$__tmpdir" ] && [ -d "$__tmpdir" ]; then
    rm -rf "$__tmpdir"
  fi
}
