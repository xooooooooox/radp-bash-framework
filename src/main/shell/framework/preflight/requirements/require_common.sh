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
#   1 - run_cmd: optional command/function to run sed as root/sudo
# Outputs:
#   None
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__fw_requirements_fix_yum_repo_for_centos7() {
  __run_cmd=${1:-}
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
  if [ -n "$__run_cmd" ]; then
    "$__run_cmd" sed -i -r \
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
