#!/usr/bin/env bash
set -e

__main() {
  # 加载日志组件
  # shellcheck source=./logger/logger.sh
  __framework_source_scripts "$gr_framework_context_libs_path"/logger/logger.sh
  # 如果日志组件成功加载, 后续便可以使用 radp_log_xx 进行日志打印了

  # TODO v1.0-2025/12/29: 接下来加载工具库
}

__main
