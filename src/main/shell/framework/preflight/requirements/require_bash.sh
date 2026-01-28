#!/bin/sh

# shellcheck source=./preflight_helper.sh
. "$gr_fw_requirements_path"/preflight_helper.sh

#######################################
# 检查 bash 是否满足最低版本要求
# Globals:
#   BASH_VERSION
# Arguments:
#   1 - req_ver: 最低版本
#   2 - bash_bin: 可选，指定 bash 可执行文件路径
# Outputs:
#   None
# Returns:
#   0 - 满足
#   1 - 不满足
#######################################
__fw_requirements_check_bash() {
  __req_ver=${1:-}
  __bash_bin_arg=${2:-}
  __ok=0
  __ver=${__ver:-}
  if [ -n "$__bash_bin_arg" ]; then
    __ver=$("$__bash_bin_arg" --version 2>/dev/null | sed -n '1s/.*version[[:space:]]*//p')
    __ver=${__ver%% *}
    __ver=${__ver%%(*}
  elif [ -n "$BASH_VERSION" ]; then
    __ver=${BASH_VERSION%%(*}
  fi

  if [ -n "$__ver" ]; then
    if [ -z "$__req_ver" ]; then
      __ok=1
    else
      if __fw_requirements_bash_version_ge "$__ver" "$__req_ver"; then
        __ok=1
      fi
    fi
  fi
  unset __ver __req_ver __bash_bin_arg
  if [ "$__ok" -eq 1 ]; then
    unset __ok
    return 0
  else
    unset __ok
    return 1
  fi
}

#######################################
# 比较 bash 版本是否满足最低版本要求
# Globals:
#   None
# Arguments:
#   1 - curr_ver: 当前版本
#   2 - req_ver: 最低版本
# Outputs:
#   None
# Returns:
#   0 - 满足
#   1 - 不满足
#######################################
__fw_requirements_bash_version_ge() {
  __curr_ver=${1:-}
  __req_ver=${2:-}
  if [ -z "$__req_ver" ]; then
    return 0
  fi
  if [ -z "$__curr_ver" ]; then
    return 1
  fi

  __curr_major=$(echo "$__curr_ver" | cut -d. -f1)
  __curr_minor=$(echo "$__curr_ver." | cut -d. -f2)
  [ -z "$__curr_minor" ] && __curr_minor=0
  __req_major=$(echo "$__req_ver" | cut -d. -f1)
  __req_minor=$(echo "$__req_ver." | cut -d. -f2)
  [ -z "$__req_minor" ] && __req_minor=0

  if [ "$__curr_major" -gt "$__req_major" ] || { [ "$__curr_major" -eq "$__req_major" ] && [ "$__curr_minor" -ge "$__req_minor" ]; }; then
    return 0
  fi
  return 1
}

#######################################
# 安装 bash(源码编译)
# Globals:
#   gw_fw_requirements_bash_required_ver
#   gw_fw_requirements_bash_reexec
# Arguments:
#   1 - req_ver: 最低版本
#   2 - install_ver: 指定安装版本
# Outputs:
#   None
# Returns:
#   0 - Success
#   1 - Failed
#######################################
__fw_requirements_prepare_bash() {
  __req_ver=${1:-}
  __install_ver=${2:-}
  gw_fw_requirements_bash_required_ver=$__req_ver

  # 解析安装目标版本：优先 install 版本，其次 req 版本
  __target_ver=${__install_ver:-${__req_ver:-5.2}}
  echo "Preflight: installing bash $__target_ver from source..." >&2
  __major=$(printf '%s' "$__target_ver" | cut -d. -f1)
  __minor=$(printf '%s' "$__target_ver" | cut -d. -f2)
  __patch=$(printf '%s' "$__target_ver" | cut -d. -f3)
  [ -z "$__minor" ] && __minor=0
  [ -z "$__patch" ] && __patch=0
  case "$__major" in
  ''|*[!0-9]*) __major=5 ;;
  esac
  case "$__minor" in
  ''|*[!0-9]*) __minor=0 ;;
  esac
  case "$__patch" in
  ''|*[!0-9]*) __patch=0 ;;
  esac
  __base_ver="${__major}.${__minor}"

  __sudo=$(__fw_requirements_resolve_sudo "Error: Installing bash requires root or sudo.") || return 1

  #######################################
  # 安装构建 bash 所需依赖(支持 apt/dnf/yum)
  # Globals:
  #   None
  # Arguments:
  #   None
  # Outputs:
  #   None
  # Returns:
  #   0 - Success
  #   1 - Failed
  #######################################
  __fw_requirements_prepare_bash_install_deps() {
    __fw_requirements_install_packages "$__sudo" \
      "build-essential bison libreadline-dev libncurses-dev ca-certificates curl wget tar gzip patch" \
      "gcc make bison readline-devel ncurses-devel ca-certificates curl wget tar gzip patch" \
      "gcc make bison readline-devel ncurses-devel ca-certificates curl wget tar gzip patch" \
      "build dependencies"
  }

  __fw_requirements_prepare_bash_install_deps || {
    echo "Error: Failed to install build dependencies." >&2
    return 1
  }

  __tmpdir=$(__fw_requirements_mktemp_dir "radp_bash_build")
  if [ -z "$__tmpdir" ] || [ ! -d "$__tmpdir" ]; then
    echo "Error: Failed to create temp directory." >&2
    return 1
  fi

  #######################################
  # 清理临时目录
  # Globals:
  #   __tmpdir
  # Arguments:
  #   None
  # Outputs:
  #   None
  # Returns:
  #   None
  #######################################
  __fw_requirements_prepare_bash_cleanup() {
    __fw_requirements_cleanup_tmpdir "$__tmpdir"
  }
  trap '__fw_requirements_prepare_bash_cleanup' 0 2 15

  __tarball="bash-${__base_ver}.tar.gz"
  __tarpath="$__tmpdir/$__tarball"
  __url_primary="https://ftp.gnu.org/gnu/bash/$__tarball"
  __url_mirror="https://mirrors.edge.kernel.org/gnu/bash/$__tarball"
  echo "Preflight: downloading $__tarball..." >&2
  if ! __fw_requirements_download_file "$__url_primary" "$__tarpath" "progress"; then
    if ! __fw_requirements_download_file "$__url_mirror" "$__tarpath" "progress"; then
      echo "Error: Failed to download $__tarball." >&2
      return 1
    fi
  fi

  tar -xzf "$__tarpath" -C "$__tmpdir" || {
    echo "Error: Failed to extract $__tarball." >&2
    return 1
  }

  __srcdir="$__tmpdir/bash-${__base_ver}"
  if [ ! -d "$__srcdir" ]; then
    echo "Error: Source directory $__srcdir not found." >&2
    return 1
  fi

  if [ "$__patch" -gt 0 ]; then
    echo "Preflight: applying bash patches (level $__patch)..." >&2
    __patch_prefix="bash${__major}${__minor}"
    __patch_dir="https://ftp.gnu.org/gnu/bash/bash-${__base_ver}-patches"
    __i=1
    while [ "$__i" -le "$__patch" ]; do
      __patch_file="${__patch_prefix}-$(printf '%03d' "$__i")"
      __patch_path="$__tmpdir/$__patch_file"
      if ! __fw_requirements_download_file "$__patch_dir/$__patch_file" "$__patch_path" "progress"; then
        echo "Error: Failed to download patch $__patch_file." >&2
        return 1
      fi
      (cd "$__srcdir" && patch -p0 < "$__patch_path") || {
        echo "Error: Failed to apply patch $__patch_file." >&2
        return 1
      }
      __i=$((__i + 1))
    done
  fi

  (cd "$__srcdir" && ./configure --prefix=/usr/local) || {
    echo "Error: Failed to configure bash source." >&2
    return 1
  }

  __jobs=1
  if command -v getconf >/dev/null 2>&1; then
    __jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null)
    [ -z "$__jobs" ] && __jobs=1
  fi

  echo "Preflight: building bash (jobs=$__jobs)..." >&2
  (cd "$__srcdir" && make -j "$__jobs") || {
    echo "Error: Failed to build bash source." >&2
    return 1
  }

  echo "Preflight: installing bash to /usr/local..." >&2
  (cd "$__srcdir" && __fw_requirements_run_with_sudo "$__sudo" make install) || {
    echo "Error: Failed to install bash." >&2
    return 1
  }
  if [ -x /usr/local/bin/bash ]; then
    gw_fw_requirements_bash_reexec=/usr/local/bin/bash
  fi

  __fw_requirements_prepare_bash_cleanup
  trap - 0 2 15
  unset __target_ver __major __minor __patch __base_ver __sudo __tmpdir __tarball __tarpath __url_primary __url_mirror
  unset __srcdir __patch_prefix __patch_dir __i __patch_file __patch_path __jobs
}
