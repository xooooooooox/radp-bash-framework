#!/usr/bin/env bash

#######################################
# 检测当前操作系统发行版，并尝试识别使用的包管理工具。
# 此函数主要读取 /etc/os-release 文件来获取发行版的名称和版本，
# 然后基于发行版名称推断包管理工具。
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   输出格式为 "distro_arch:distro_os:distro_id:distro_name:distro_version:distro_pm"
# Examples:
#   1) 获取完整信息
#      distro_info=$(__fw_os_get_distro_info)
#      IFS=':' read -r distro_arch distro_os distro_id distro_name distro_version distro_pm <<< "$distro_info"
#   2) 如果仅关注 distro_pm
#      IFS=':' read -r _ _ _ _ _ distro_pm < <(__fw_os_get_distro_info)
#######################################
__fw_os_get_distro_info() {
  local distro_arch="unknown"
  local distro_os="unknown"
  local distro_id="unknown"
  local distro_name="unknown"
  local distro_version="unknown"
  local distro_pm="unknown"

  distro_arch=$(uname -m)
  distro_os=$(uname -s)

  if [[ "$OSTYPE" =~ ^darwin ]]; then
    # macOS 系统
    distro_id="osx"
    distro_name="osx"
    distro_version=$(sw_vers -productVersion)
    distro_pm="brew" # macOS 常用 Homebrew 作为包管理器
  elif [[ -f /etc/os-release ]]; then
    # 读取 /etc/os-release 文件获取发行版信息
    . /etc/os-release
    distro_id="${ID:-unkownn}"
    distro_name="${NAME:-unknown}"
    distro_version="${VERSION_ID:-unknown}"

    # 基于发行版名称推断包管理工具
    case $distro_id in
    ubuntu | debian | linuxmint)
      distro_pm="apt-get"
      ;;
    fedora)
      if [[ "$VERSION_ID" -ge 22 ]]; then
        distro_pm="dnf"
      else
        distro_pm="yum"
      fi
      ;;
    centos | rhel)
      if [[ "$VERSION_ID" -ge 9 ]]; then
        distro_pm="dnf"
      else
        distro_pm="yum"
      fi
      ;;
    arch | manjaro)
      distro_pm="pacman"
      ;;
    opensuse* | sles)
      distro_pm="zypper"
      ;;
    alpine)
      distro_pm="apk"
      ;;
    *)
      distro_pm="unknown"
      ;;
    esac
  fi

  # 使用 ':' 作为分隔符输出结果
  echo "${distro_arch}:${distro_os}:${distro_id}:${distro_name}:${distro_version}:${distro_pm}"
}

__main() {
  # sudo
  gr_sudo=$([ "${EUID:-$(id -u)}" -ne 0 ] && printf 'sudo' || printf '')
  readonly gr_sudo

  # distro
  IFS=':' read -r gr_distro_arch gr_distro_os gr_distro_id gr_distro_name gr_distro_version gr_distro_pm < <(__fw_os_get_distro_info)
  readonly gr_distro_arch gr_distro_os gr_distro_id gr_distro_name gr_distro_version gr_distro_pm
}

#----------------------------------------------------------------------------------------------------------------------#
declare -g gr_sudo
declare -g gr_distro_arch
declare -g gr_distro_os
declare -g gr_distro_id
declare -g gr_distro_name
declare -g gr_distro_version
declare -g gr_distro_pm

__main "$@"
