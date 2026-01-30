#!/usr/bin/env bash
# toolkit module: cli/09_upgrade.sh
# CLI 项目升级：升级基于 radp-bash-framework 创建的 CLI 项目

# 可升级的组件列表
declare -ga __radp_upgrade_components=(entry ide gitignore)

#######################################
# 升级 CLI 项目
# Arguments:
#   1 - target_dir: 项目目录（可选，默认为当前目录）
#   @ - 组件列表或选项
# Options:
#   --dry-run   只显示变更，不实际修改
#   --force     强制覆盖，不提示确认
#   --diff      显示文件差异
# Returns:
#   0 - 成功
#   1 - 失败
#######################################
radp_cli_upgrade() {
  local target_dir="."
  local dry_run=false
  local force=false
  local show_diff=false
  local -a components=()

  # 解析参数
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --dry-run)
      dry_run=true
      shift
      ;;
    --force)
      force=true
      shift
      ;;
    --diff)
      show_diff=true
      shift
      ;;
    -*)
      radp_log_error "Unknown option: $1"
      return 1
      ;;
    *)
      # 第一个非选项参数如果是目录则作为 target_dir
      if [[ -d "$1" && ${#components[@]} -eq 0 ]]; then
        target_dir="$1"
      else
        components+=("$1")
      fi
      shift
      ;;
    esac
  done

  # 默认升级所有组件
  if [[ ${#components[@]} -eq 0 ]]; then
    components=("${__radp_upgrade_components[@]}")
  fi

  # 验证组件
  local comp
  for comp in "${components[@]}"; do
    if [[ "$comp" != "all" ]] && ! __radp_upgrade_is_valid_component "$comp"; then
      radp_log_error "Unknown component: $comp"
      radp_log_error "Available components: ${__radp_upgrade_components[*]} all"
      return 1
    fi
  done

  # 如果指定 all，替换为所有组件
  if [[ " ${components[*]} " == *" all "* ]]; then
    components=("${__radp_upgrade_components[@]}")
  fi

  # 转为绝对路径
  target_dir="$(cd "$target_dir" && pwd)"

  # 检测项目
  if ! __radp_upgrade_detect_project "$target_dir"; then
    return 1
  fi

  local project_name
  project_name="$(__radp_upgrade_get_project_name "$target_dir")"

  local current_version
  current_version="$(__radp_upgrade_get_current_version "$target_dir")"

  local target_version
  target_version="$(radp_get_fw_install_version)"

  echo "Upgrading $project_name"
  echo "  From: ${current_version:-unknown}"
  echo "  To:   $target_version"
  echo ""

  if [[ "$dry_run" == "true" ]]; then
    echo "[dry-run] Changes to be applied:"
    echo ""
  fi

  # 执行升级
  local has_changes=false
  local comp
  for comp in "${components[@]}"; do
    if __radp_upgrade_component "$target_dir" "$project_name" "$comp" "$dry_run" "$force" "$show_diff"; then
      has_changes=true
    fi
  done

  if [[ "$has_changes" == "false" ]]; then
    echo "Already up to date."
    return 0
  fi

  # 更新版本信息
  if [[ "$dry_run" == "false" ]]; then
    __radp_upgrade_update_metadata "$target_dir" "$target_version"
    echo ""
    echo "Upgrade completed."
  else
    echo ""
    echo "Run without --dry-run to apply changes."
  fi

  return 0
}

#######################################
# 检查是否为有效组件
#######################################
__radp_upgrade_is_valid_component() {
  local comp="$1"
  local valid
  for valid in "${__radp_upgrade_components[@]}"; do
    [[ "$comp" == "$valid" ]] && return 0
  done
  return 1
}

#######################################
# 检测是否为有效的 CLI 项目
#######################################
__radp_upgrade_detect_project() {
  local target_dir="$1"

  # 检查基本结构
  if [[ ! -d "$target_dir/bin" ]]; then
    radp_log_error "Not a valid CLI project: missing bin/ directory"
    return 1
  fi

  if [[ ! -d "$target_dir/src/main/shell" ]]; then
    radp_log_error "Not a valid CLI project: missing src/main/shell/ directory"
    return 1
  fi

  # 查找入口脚本
  local entry_script
  entry_script=$(find "$target_dir/bin" -maxdepth 1 -type f -executable 2>/dev/null | head -1)
  if [[ -z "$entry_script" ]]; then
    radp_log_error "Not a valid CLI project: no executable found in bin/"
    return 1
  fi

  # 检查是否使用 radp-bash-framework
  if ! grep -q "radp-bf" "$entry_script" 2>/dev/null; then
    radp_log_error "Not a radp-bash-framework project: entry script doesn't use radp-bf"
    return 1
  fi

  return 0
}

#######################################
# 获取项目名称
#######################################
__radp_upgrade_get_project_name() {
  local target_dir="$1"

  # 从 .radp-cli/name 读取
  if [[ -f "$target_dir/.radp-cli/name" ]]; then
    cat "$target_dir/.radp-cli/name"
    return 0
  fi

  # 从入口脚本名称推断
  local entry_script
  entry_script=$(find "$target_dir/bin" -maxdepth 1 -type f -executable 2>/dev/null | head -1)
  if [[ -n "$entry_script" ]]; then
    basename "$entry_script"
    return 0
  fi

  # 从目录名推断
  basename "$target_dir"
}

#######################################
# 获取当前脚手架版本
#######################################
__radp_upgrade_get_current_version() {
  local target_dir="$1"

  if [[ -f "$target_dir/.radp-cli/version" ]]; then
    cat "$target_dir/.radp-cli/version"
  else
    echo "unknown"
  fi
}

#######################################
# 升级单个组件
# Returns:
#   0 - 有变更
#   1 - 无变更
#######################################
__radp_upgrade_component() {
  local target_dir="$1"
  local project_name="$2"
  local component="$3"
  local dry_run="$4"
  local force="$5"
  local show_diff="$6"

  case "$component" in
  entry)
    __radp_upgrade_entry "$target_dir" "$project_name" "$dry_run" "$force" "$show_diff"
    ;;
  ide)
    __radp_upgrade_ide "$target_dir" "$dry_run" "$force" "$show_diff"
    ;;
  gitignore)
    __radp_upgrade_gitignore "$target_dir" "$dry_run" "$force" "$show_diff"
    ;;
  *)
    return 1
    ;;
  esac
}

#######################################
# 升级入口脚本
#######################################
__radp_upgrade_entry() {
  local target_dir="$1"
  local project_name="$2"
  local dry_run="$3"
  local force="$4"
  local show_diff="$5"

  local entry_file="$target_dir/bin/$project_name"

  if [[ ! -f "$entry_file" ]]; then
    echo "  [SKIP] bin/$project_name (not found)"
    return 1
  fi

  # 生成新的入口脚本内容
  local new_content
  new_content=$(cat <<'ENTRY_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# 检查框架是否已安装
if ! command -v radp-bf &>/dev/null; then
  echo "Error: radp-bash-framework not found. Please install it first." >&2
  echo "  See: https://github.com/xooooooooox/radp-bash-framework" >&2
  exit 1
fi

# 解析项目根目录并加载框架
export RADP_APP_ROOT="$(radp-bf resolve-root "${BASH_SOURCE[0]}")"
source "$(radp-bf path launcher)" "$@"
ENTRY_SCRIPT
)

  local current_content
  current_content=$(cat "$entry_file")

  # 检查是否需要更新
  if [[ "$current_content" == "$new_content" ]]; then
    echo "  [OK]   bin/$project_name (up to date)"
    return 1
  fi

  # 检查是否为原始内容（未被用户修改）
  local is_modified=false
  if [[ -f "$target_dir/.radp-cli/checksums/entry" ]]; then
    local original_checksum
    original_checksum=$(cat "$target_dir/.radp-cli/checksums/entry")
    local current_checksum
    current_checksum=$(echo -n "$current_content" | shasum -a 256 | cut -d' ' -f1)
    if [[ "$original_checksum" != "$current_checksum" ]]; then
      is_modified=true
    fi
  fi

  if [[ "$is_modified" == "true" && "$force" != "true" ]]; then
    echo "  [SKIP] bin/$project_name (user modified, use --force to overwrite)"
    if [[ "$show_diff" == "true" ]]; then
      echo "    Diff:"
      diff -u <(echo "$current_content") <(echo "$new_content") | sed 's/^/    /' || true
    fi
    return 1
  fi

  if [[ "$dry_run" == "true" ]]; then
    echo "  [UPDATE] bin/$project_name"
    if [[ "$show_diff" == "true" ]]; then
      diff -u <(echo "$current_content") <(echo "$new_content") | sed 's/^/    /' || true
    fi
  else
    echo "$new_content" >"$entry_file"
    chmod +x "$entry_file"
    echo "  [UPDATE] bin/$project_name"
  fi

  return 0
}

#######################################
# 升级 IDE 配置
#######################################
__radp_upgrade_ide() {
  local target_dir="$1"
  local dry_run="$2"
  local force="$3"
  local show_diff="$4"

  local ide_file="$target_dir/src/main/shell/config/_ide.sh"

  # 生成新的 _ide.sh 内容
  local new_content
  new_content=$(cat <<'IDE_HINTS'
#!/usr/bin/env bash
# IDE code completion support for BashSupport Pro
# This file is not executed at runtime, only used for IDE navigation
#
# References the auto-generated _idecomp.sh which provides navigation to:
#   - Framework library functions (radp_*)
#   - Framework global variables (gr_fw_*, gr_radp_fw_*)
#   - User global variables (gr_radp_extend_*)
#   - User library functions
# Note: _idecomp.sh is auto-generated and should be in .gitignore
# shellcheck source=./_idecomp.sh
IDE_HINTS
)

  if [[ ! -f "$ide_file" ]]; then
    if [[ "$dry_run" == "true" ]]; then
      echo "  [CREATE] src/main/shell/config/_ide.sh"
    else
      mkdir -p "$(dirname "$ide_file")"
      echo "$new_content" >"$ide_file"
      echo "  [CREATE] src/main/shell/config/_ide.sh"
    fi
    return 0
  fi

  local current_content
  current_content=$(cat "$ide_file")

  if [[ "$current_content" == "$new_content" ]]; then
    echo "  [OK]   src/main/shell/config/_ide.sh (up to date)"
    return 1
  fi

  if [[ "$dry_run" == "true" ]]; then
    echo "  [UPDATE] src/main/shell/config/_ide.sh"
    if [[ "$show_diff" == "true" ]]; then
      diff -u <(echo "$current_content") <(echo "$new_content") | sed 's/^/    /' || true
    fi
  else
    echo "$new_content" >"$ide_file"
    echo "  [UPDATE] src/main/shell/config/_ide.sh"
  fi

  return 0
}

#######################################
# 升级 .gitignore
#######################################
__radp_upgrade_gitignore() {
  local target_dir="$1"
  local dry_run="$2"
  local force="$3"
  local show_diff="$4"

  local gitignore_file="$target_dir/.gitignore"

  # 需要确保存在的条目
  local -a required_entries=(
    "src/main/shell/config/config.sh"
    "src/main/shell/config/_idecomp.sh"
    ".radp-cli/checksums/"
  )

  # 需要移除的旧条目
  local -a deprecated_entries=(
    "src/main/shell/config/completion.sh"
  )

  if [[ ! -f "$gitignore_file" ]]; then
    echo "  [SKIP] .gitignore (not found)"
    return 1
  fi

  local current_content
  current_content=$(cat "$gitignore_file")
  local new_content="$current_content"
  local has_changes=false

  # 添加缺失的条目
  local entry
  for entry in "${required_entries[@]}"; do
    if ! grep -qF "$entry" "$gitignore_file" 2>/dev/null; then
      new_content=$(echo -e "$entry\n$new_content")
      has_changes=true
    fi
  done

  # 移除废弃的条目
  for entry in "${deprecated_entries[@]}"; do
    if grep -qF "$entry" <<<"$new_content" 2>/dev/null; then
      new_content=$(grep -vF "$entry" <<<"$new_content")
      has_changes=true
    fi
  done

  if [[ "$has_changes" == "false" ]]; then
    echo "  [OK]   .gitignore (up to date)"
    return 1
  fi

  if [[ "$dry_run" == "true" ]]; then
    echo "  [UPDATE] .gitignore"
    if [[ "$show_diff" == "true" ]]; then
      diff -u <(echo "$current_content") <(echo "$new_content") | sed 's/^/    /' || true
    fi
  else
    echo "$new_content" >"$gitignore_file"
    echo "  [UPDATE] .gitignore"
  fi

  return 0
}

#######################################
# 更新元数据
#######################################
__radp_upgrade_update_metadata() {
  local target_dir="$1"
  local version="$2"

  mkdir -p "$target_dir/.radp-cli/checksums"

  # 保存版本
  echo "$version" >"$target_dir/.radp-cli/version"

  # 保存项目名称
  local project_name
  project_name=$(__radp_upgrade_get_project_name "$target_dir")
  echo "$project_name" >"$target_dir/.radp-cli/name"

  # 保存入口脚本 checksum
  local entry_file="$target_dir/bin/$project_name"
  if [[ -f "$entry_file" ]]; then
    shasum -a 256 "$entry_file" | cut -d' ' -f1 >"$target_dir/.radp-cli/checksums/entry"
  fi
}

#######################################
# 初始化项目元数据（用于 scaffold 创建时）
#######################################
radp_cli_init_metadata() {
  local target_dir="$1"
  local project_name="$2"
  local version="$3"

  mkdir -p "$target_dir/.radp-cli/checksums"

  # 保存版本
  echo "$version" >"$target_dir/.radp-cli/version"

  # 保存项目名称
  echo "$project_name" >"$target_dir/.radp-cli/name"

  # 保存入口脚本 checksum
  local entry_file="$target_dir/bin/$project_name"
  if [[ -f "$entry_file" ]]; then
    shasum -a 256 "$entry_file" | cut -d' ' -f1 >"$target_dir/.radp-cli/checksums/entry"
  fi
}
