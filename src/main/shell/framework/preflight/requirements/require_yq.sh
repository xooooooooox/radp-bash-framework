#!/bin/sh

__fw_requirements_check_yq() {
  __req_ver=${1:-}
  command -v yq >/dev/null 2>&1
}

__fw_requirements_prepare_yq() {
  __req_ver=${1:-}
  __install_ver=${2:-}
  # TODO v1.0-2025/12/31: 待实现
}
