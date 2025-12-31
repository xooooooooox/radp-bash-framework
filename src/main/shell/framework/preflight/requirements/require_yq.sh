#!/bin/sh

__fw_requirements_check_yq() {
  command -v yq >/dev/null 2>&1
}

__fw_requirements_prepare_yq() {
  __install_ver=${1:?}
  # TODO v1.0-2025/12/31: 待实现
}
