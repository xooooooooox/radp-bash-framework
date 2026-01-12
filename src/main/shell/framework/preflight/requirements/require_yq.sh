#!/bin/sh

# shellcheck source=./require_common.sh
. "$gr_fw_requirements_path/require_common.sh"

#######################################
# 检查 yq 是否已安装
# Globals:
#   None
# Arguments:
#   1 - req_ver: 最低版本（当前实现仅判断是否存在）
# Outputs:
#   None
# Returns:
#   0 - 已安装
#   1 - 未安装
#######################################
__fw_requirements_check_yq() {
  __req_ver=${1:-}
  command -v yq >/dev/null 2>&1
}

__fw_requirements_prepare_yq() {
  __req_ver=${1:-}
  __install_ver=${2:-}

  #######################################
  # 安装 yq（二进制发布包）
  # Globals:
  #   None
  # Arguments:
  #   1 - req_ver: 最低版本
  #   2 - install_ver: 指定安装版本
  # Outputs:
  #   None
  # Returns:
  #   0 - Success
  #   1 - Failed
  #######################################

  __target_ver=${__install_ver:-${__req_ver:-4.44.1}}
  echo "Preflight: installing yq $__target_ver..."
  __os=$(uname -s 2>/dev/null | tr 'A-Z' 'a-z')
  if [ "$__os" != "linux" ]; then
    echo "Error: Unsupported OS for yq install: $__os" >&2
    return 1
  fi

  __arch=$(uname -m 2>/dev/null)
  case "$__arch" in
  x86_64 | amd64) __arch=amd64 ;;
  aarch64 | arm64) __arch=arm64 ;;
  armv7l | armv6l | arm) __arch=arm ;;
  i386 | i686) __arch=386 ;;
  *)
    echo "Error: Unsupported architecture for yq install: $__arch" >&2
    return 1
    ;;
  esac

  __sudo=$(__fw_requirements_resolve_sudo "Error: Installing yq requires root or sudo.") || return 1

  #######################################
  # 以 root 或 sudo 执行指定命令
  # Globals:
  #   __sudo
  # Arguments:
  #   @ - 命令及参数
  # Outputs:
  #   None
  # Returns:
  #   0 - Success
  #   1 - Failed
  #######################################
  __fw_requirements_prepare_yq_run() {
    __fw_requirements_run_with_sudo "$__sudo" "$@"
  }

  #######################################
  # 安装下载工具依赖（支持 apt/dnf/yum）
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
  __fw_requirements_prepare_yq_install_deps() {
    if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
      return 0
    fi
    if command -v apt-get >/dev/null 2>&1; then
      echo "Preflight: installing download tools (apt)..."
      __fw_requirements_prepare_yq_run apt-get update >/dev/null 2>&1 || return 1
      DEBIAN_FRONTEND=noninteractive __fw_requirements_prepare_yq_run apt-get install -y \
        ca-certificates curl wget >/dev/null 2>&1 || return 1
      return 0
    fi
    if command -v dnf >/dev/null 2>&1; then
      echo "Preflight: installing download tools (dnf)..."
      __fw_requirements_prepare_yq_run dnf install -y \
        ca-certificates curl wget >/dev/null 2>&1 || return 1
      return 0
    fi
    if command -v yum >/dev/null 2>&1; then
      echo "Preflight: installing download tools (yum)..."
      __fw_requirements_fix_yum_repo_for_centos7 "__fw_requirements_prepare_yq_run" || return 1
      __fw_requirements_prepare_yq_run yum install -y \
        ca-certificates curl wget >/dev/null 2>&1 || return 1
      return 0
    fi
    echo "Error: Unsupported OS. Please install curl or wget manually." >&2
    return 1
  }

  #######################################
  # 下载文件（优先 curl，其次 wget）
  # Globals:
  #   None
  # Arguments:
  #   1 - url: 下载地址
  #   2 - out: 输出文件路径
  # Outputs:
  #   None
  # Returns:
  #   0 - Success
  #   1 - Failed
  #######################################
  __fw_requirements_prepare_yq_download() {
    __url=${1:-}
    __out=${2:-}
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

  __fw_requirements_prepare_yq_install_deps || {
    echo "Error: Failed to install download tools." >&2
    return 1
  }

  __tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t radp_yq_install)
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
  __fw_requirements_prepare_yq_cleanup() {
    if [ -n "$__tmpdir" ] && [ -d "$__tmpdir" ]; then
      rm -rf "$__tmpdir"
    fi
  }
  trap '__fw_requirements_prepare_yq_cleanup' 0 2 15

  __filename="yq_${__os}_${__arch}"
  __url="https://github.com/mikefarah/yq/releases/download/v${__target_ver}/${__filename}"
  __binpath="$__tmpdir/$__filename"
  echo "Preflight: downloading yq from $__url..."

  if ! __fw_requirements_prepare_yq_download "$__url" "$__binpath"; then
    echo "Error: Failed to download yq from $__url" >&2
    return 1
  fi

  chmod +x "$__binpath" || {
    echo "Error: Failed to chmod yq binary." >&2
    return 1
  }

  __target_dir="/usr/local/bin"
  __target_bin="${__target_dir}/yq"
  if [ ! -d "$__target_dir" ]; then
    echo "Preflight: creating $__target_dir..."
    __fw_requirements_prepare_yq_run mkdir -p "$__target_dir" || {
      echo "Error: Failed to create $__target_dir." >&2
      return 1
    }
  fi

  echo "Preflight: installing yq to $__target_bin..."
  __fw_requirements_prepare_yq_run mv "$__binpath" "$__target_bin" || {
    echo "Error: Failed to install yq to $__target_bin." >&2
    return 1
  }

  __fw_requirements_prepare_yq_cleanup
  trap - 0 2 15
  unset __target_ver __os __arch __sudo __tmpdir __filename __url __binpath __target_dir __target_bin
}
