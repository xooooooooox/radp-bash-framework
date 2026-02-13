#!/usr/bin/env bash
# toolkit module: cli/09_upgrade.sh
# CLI 项目升级：升级基于 radp-bash-framework 创建的 CLI 项目

# 可升级的组件列表
declare -ga __radp_upgrade_components=(entry ide gitignore version workflows packaging globals upgrade_cmd completion_cmd config)

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

  # 查找入口脚本（兼容 macOS BSD，不依赖 GNU find -executable）
  local entry_script=""
  local file
  for file in "$target_dir/bin"/*; do
    if [[ -f "$file" && -x "$file" ]]; then
      entry_script="$file"
      break
    fi
  done
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
  local entry_script=""
  local file
  for file in "$target_dir/bin"/*; do
    if [[ -f "$file" && -x "$file" ]]; then
      entry_script="$file"
      break
    fi
  done
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
  version)
    __radp_upgrade_version "$target_dir" "$project_name" "$dry_run" "$force" "$show_diff"
    ;;
  workflows)
    __radp_upgrade_workflows "$target_dir" "$project_name" "$dry_run" "$force" "$show_diff"
    ;;
  packaging)
    __radp_upgrade_packaging "$target_dir" "$project_name" "$dry_run" "$force" "$show_diff"
    ;;
  globals)
    __radp_upgrade_globals "$target_dir" "$dry_run" "$force" "$show_diff"
    ;;
  upgrade_cmd)
    __radp_upgrade_upgrade_cmd "$target_dir" "$project_name" "$dry_run" "$force" "$show_diff"
    ;;
  completion_cmd)
    __radp_upgrade_completion_cmd "$target_dir" "$project_name" "$dry_run" "$force" "$show_diff"
    ;;
  config)
    __radp_upgrade_config "$target_dir" "$project_name" "$dry_run" "$force" "$show_diff"
    ;;
  *)
    return 1
    ;;
  esac
}

#######################################
# 升级 upgrade 命令（如果不存在则创建）
#######################################
__radp_upgrade_upgrade_cmd() {
  local target_dir="$1"
  local project_name="$2"
  local dry_run="$3"
  local force="$4"
  local show_diff="$5"

  local upgrade_file="$target_dir/src/main/shell/commands/upgrade.sh"

  local new_content
  new_content=$(radp_cli_upgrade_cmd_content "$project_name")

  if [[ ! -f "$upgrade_file" ]]; then
    if [[ "$dry_run" == "true" ]]; then
      echo "  [CREATE] src/main/shell/commands/upgrade.sh"
    else
      mkdir -p "$(dirname "$upgrade_file")"
      echo "$new_content" >"$upgrade_file"
      echo "  [CREATE] src/main/shell/commands/upgrade.sh"
    fi
    return 0
  fi

  local current_content
  current_content=$(cat "$upgrade_file")

  if [[ "$current_content" == "$new_content" ]]; then
    echo "  [OK]   src/main/shell/commands/upgrade.sh (up to date)"
    return 1
  fi

  if [[ "$dry_run" == "true" ]]; then
    echo "  [UPDATE] src/main/shell/commands/upgrade.sh"
    if [[ "$show_diff" == "true" ]]; then
      diff -u <(echo "$current_content") <(echo "$new_content") | sed 's/^/    /' || true
    fi
  else
    echo "$new_content" >"$upgrade_file"
    echo "  [UPDATE] src/main/shell/commands/upgrade.sh"
  fi

  return 0
}

#######################################
# 升级 completion 命令（如果不存在则创建）
#######################################
__radp_upgrade_completion_cmd() {
  local target_dir="$1"
  local project_name="$2"
  local dry_run="$3"
  local force="$4"
  local show_diff="$5"

  local completion_file="$target_dir/src/main/shell/commands/completion.sh"

  local new_content
  new_content=$(radp_cli_completion_cmd_content "$project_name")

  if [[ ! -f "$completion_file" ]]; then
    if [[ "$dry_run" == "true" ]]; then
      echo "  [CREATE] src/main/shell/commands/completion.sh"
    else
      mkdir -p "$(dirname "$completion_file")"
      echo "$new_content" >"$completion_file"
      echo "  [CREATE] src/main/shell/commands/completion.sh"
    fi
    return 0
  fi

  local current_content
  current_content=$(cat "$completion_file")

  if [[ "$current_content" == "$new_content" ]]; then
    echo "  [OK]   src/main/shell/commands/completion.sh (up to date)"
    return 1
  fi

  if [[ "$dry_run" == "true" ]]; then
    echo "  [UPDATE] src/main/shell/commands/completion.sh"
    if [[ "$show_diff" == "true" ]]; then
      diff -u <(echo "$current_content") <(echo "$new_content") | sed 's/^/    /' || true
    fi
  else
    echo "$new_content" >"$completion_file"
    echo "  [UPDATE] src/main/shell/commands/completion.sh"
  fi

  return 0
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

  # 生成新的入口脚本内容（复用 scaffold 中的模板）
  local new_content
  new_content=$(radp_cli_entry_content "$project_name")

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
# 升级 _globals.sh（应用级全局选项）
# 如果文件不存在则创建示例文件
#######################################
__radp_upgrade_globals() {
  local target_dir="$1"
  local dry_run="$2"
  local force="$3"
  local show_diff="$4"

  local globals_file="$target_dir/src/main/shell/commands/_globals.sh"

  # 如果文件已存在，不覆盖（保留用户自定义内容）
  if [[ -f "$globals_file" ]]; then
    echo "  [OK]   commands/_globals.sh (already exists)"
    return 1
  fi

  # 生成示例文件
  local new_content
  new_content=$(cat <<'GLOBALS_CMD'
#!/usr/bin/env bash
# Application-level global options
# These options are available to all commands
#
# Usage: Define @global annotations here, similar to @option in command files
# Variables will be available as gopt_<name> (e.g., gopt_verbose)
#
# Syntax examples:
#   @global -v, --verbose Enable verbose output
#   @global -c, --config <dir> Configuration directory
#   @global -e, --env <name> Environment name [default: local]
#
# Note: These options can be placed before or after the command:
#   mycli -c /path list
#   mycli list -c /path
GLOBALS_CMD
)

  if [[ "$dry_run" == "true" ]]; then
    echo "  [CREATE] commands/_globals.sh"
  else
    mkdir -p "$(dirname "$globals_file")"
    echo "$new_content" >"$globals_file"
    echo "  [CREATE] commands/_globals.sh"
  fi

  return 0
}

#######################################
# 升级 config 文件（仅在文件不存在时创建）
# 不修改已有配置文件（用户拥有的内容）
#######################################
__radp_upgrade_config() {
  local target_dir="$1"
  local project_name="$2"
  local dry_run="$3"
  local force="$4"
  local show_diff="$5"

  local config_dir="$target_dir/src/main/shell/config"
  local project_var="${project_name//-/_}"
  local has_changes=false

  # config.yaml
  local config_file="$config_dir/config.yaml"
  if [[ -f "$config_file" ]]; then
    echo "  [OK]   config/config.yaml (already exists)"
  else
    if [[ "$dry_run" == "true" ]]; then
      echo "  [CREATE] config/config.yaml"
    else
      mkdir -p "$config_dir"
      radp_cli_config_yaml_content "$project_name" "$project_var" >"$config_file"
      echo "  [CREATE] config/config.yaml"
    fi
    has_changes=true
  fi

  # config-dev.yaml
  local config_dev_file="$config_dir/config-dev.yaml"
  if [[ -f "$config_dev_file" ]]; then
    echo "  [OK]   config/config-dev.yaml (already exists)"
  else
    if [[ "$dry_run" == "true" ]]; then
      echo "  [CREATE] config/config-dev.yaml"
    else
      mkdir -p "$config_dir"
      radp_cli_config_dev_yaml_content "$project_name" "$project_var" >"$config_dev_file"
      echo "  [CREATE] config/config-dev.yaml"
    fi
    has_changes=true
  fi

  if [[ "$has_changes" == "true" ]]; then
    return 0
  else
    return 1
  fi
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

#######################################
# 升级 version.sh（迁移 + 模板刷新）
# 支持两种格式：
#   - 旧格式：gr_radp_extend_<project_var>_version（从 config.yaml 迁移）
#   - 新格式：gr_app_version（模板刷新）
#######################################
__radp_upgrade_version() {
  local target_dir="$1"
  local project_name="$2"
  local dry_run="$3"
  local force="$4"
  local show_diff="$5"

  local version_file="$target_dir/src/main/shell/commands/version.sh"
  local config_file="$target_dir/src/main/shell/config/config.yaml"
  local project_var="${project_name//-/_}"

  if [[ ! -f "$version_file" ]]; then
    echo "  [SKIP] commands/version.sh (not found)"
    return 1
  fi

  local current_content
  current_content=$(cat "$version_file")

  # 提取用户当前版本号（支持新旧两种格式）
  local current_version="v0.0.1"
  local version_extracted

  # 新格式：declare -gr gr_app_version="v1.2.3"
  version_extracted=$(sed -n 's/^declare -gr gr_app_version="\([^"]*\)"/\1/p' "$version_file" 2>/dev/null || true)
  if [[ -n "$version_extracted" ]]; then
    current_version="$version_extracted"
  else
    # 旧格式：从 config.yaml 读取版本
    if [[ -f "$config_file" ]] && command -v yq &>/dev/null; then
      local yaml_version
      yaml_version=$(yq ".radp.extend.${project_var}.version // \"\"" "$config_file" 2>/dev/null || true)
      if [[ -n "$yaml_version" && "$yaml_version" != "null" ]]; then
        current_version="$yaml_version"
      fi
    fi
  fi

  # 生成期望的模板内容（保留用户的版本号）
  local new_content
  new_content=$(radp_cli_version_cmd_content "$project_name" "$current_version")

  if [[ "$current_content" == "$new_content" ]]; then
    echo "  [OK]   commands/version.sh (up to date)"
    return 1
  fi

  if [[ "$dry_run" == "true" ]]; then
    echo "  [UPDATE] commands/version.sh"
    echo "           Version: ${current_version}"
    if [[ "$show_diff" == "true" ]]; then
      diff -u <(echo "$current_content") <(echo "$new_content") | sed 's/^/    /' || true
    fi
  else
    echo "$new_content" >"$version_file"
    echo "  [UPDATE] commands/version.sh"
    echo "           Version: ${current_version}"
  fi

  return 0
}

#######################################
# 升级 GitHub Workflows
#######################################
__radp_upgrade_workflows() {
  local target_dir="$1"
  local project_name="$2"
  local dry_run="$3"
  local force="$4"
  local show_diff="$5"

  local workflows_dir="$target_dir/.github/workflows"
  local project_var="${project_name//-/_}"
  local has_changes=false

  # 如果目录不存在，创建它
  if [[ ! -d "$workflows_dir" ]]; then
    if [[ "$dry_run" == "true" ]]; then
      echo "  [CREATE] .github/workflows/"
    else
      mkdir -p "$workflows_dir"
      echo "  [CREATE] .github/workflows/"
    fi
    has_changes=true
  fi

  # 定义工作流列表
  local -a workflow_files=(
    "release-prep.yml"
    "create-version-tag.yml"
    "update-spec-version.yml"
    "build-copr-package.yml"
    "build-obs-package.yml"
    "update-homebrew-tap.yml"
    "attach-release-packages.yml"
    "cleanup-branches.yml"
  )

  local workflow
  for workflow in "${workflow_files[@]}"; do
    if __radp_upgrade_single_workflow "$target_dir" "$project_name" "$project_var" "$workflow" "$dry_run" "$force" "$show_diff"; then
      has_changes=true
    fi
  done

  if [[ "$has_changes" == "true" ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# 升级单个工作流文件
#######################################
__radp_upgrade_single_workflow() {
  local target_dir="$1"
  local project_name="$2"
  local project_var="$3"
  local workflow_file="$4"
  local dry_run="$5"
  local force="$6"
  local show_diff="$7"

  local workflows_dir="$target_dir/.github/workflows"
  local file_path="$workflows_dir/$workflow_file"
  local checksum_dir="$target_dir/.radp-cli/checksums/workflows"
  local checksum_file="$checksum_dir/${workflow_file%.yml}"

  # 生成工作流内容
  local new_content
  new_content=$(__radp_workflow_generate_content "$project_name" "$project_var" "$workflow_file")

  if [[ -z "$new_content" ]]; then
    echo "  [SKIP] .github/workflows/$workflow_file (no template)"
    return 1
  fi

  # 文件不存在，创建
  if [[ ! -f "$file_path" ]]; then
    if [[ "$dry_run" == "true" ]]; then
      echo "  [CREATE] .github/workflows/$workflow_file"
    else
      mkdir -p "$workflows_dir"
      echo "$new_content" >"$file_path"
      # 保存 checksum
      mkdir -p "$checksum_dir"
      echo -n "$new_content" | shasum -a 256 | cut -d' ' -f1 >"$checksum_file"
      echo "  [CREATE] .github/workflows/$workflow_file"
    fi
    return 0
  fi

  local current_content
  current_content=$(cat "$file_path")

  # 检查是否需要更新
  if [[ "$current_content" == "$new_content" ]]; then
    echo "  [OK]   .github/workflows/$workflow_file (up to date)"
    return 1
  fi

  # 检查是否被用户修改
  local is_modified=false
  if [[ -f "$checksum_file" ]]; then
    local original_checksum
    original_checksum=$(cat "$checksum_file")
    local current_checksum
    current_checksum=$(echo -n "$current_content" | shasum -a 256 | cut -d' ' -f1)
    if [[ "$original_checksum" != "$current_checksum" ]]; then
      is_modified=true
    fi
  else
    # 没有 checksum 记录，假设已被修改
    is_modified=true
  fi

  if [[ "$is_modified" == "true" && "$force" != "true" ]]; then
    echo "  [SKIP] .github/workflows/$workflow_file (user modified, use --force to overwrite)"
    if [[ "$show_diff" == "true" ]]; then
      echo "    Diff:"
      diff -u <(echo "$current_content") <(echo "$new_content") | sed 's/^/    /' || true
    fi
    return 1
  fi

  if [[ "$dry_run" == "true" ]]; then
    echo "  [UPDATE] .github/workflows/$workflow_file"
    if [[ "$show_diff" == "true" ]]; then
      diff -u <(echo "$current_content") <(echo "$new_content") | sed 's/^/    /' || true
    fi
  else
    echo "$new_content" >"$file_path"
    # 更新 checksum
    mkdir -p "$checksum_dir"
    echo -n "$new_content" | shasum -a 256 | cut -d' ' -f1 >"$checksum_file"
    echo "  [UPDATE] .github/workflows/$workflow_file"
  fi

  return 0
}

#######################################
# 生成工作流内容
# 复用 08_scaffold.sh 中的 radp_workflow_content_* 函数
#######################################
__radp_workflow_generate_content() {
  local project_name="$1"
  local project_var="$2"
  local workflow_file="$3"

  case "$workflow_file" in
  release-prep.yml)
    radp_workflow_content_release_prep "$project_name" "$project_var"
    ;;
  create-version-tag.yml)
    radp_workflow_content_create_tag "$project_name" "$project_var"
    ;;
  update-spec-version.yml)
    radp_workflow_content_update_spec "$project_name" "$project_var"
    ;;
  build-copr-package.yml)
    radp_workflow_content_build_copr "$project_name" "$project_var"
    ;;
  build-obs-package.yml)
    radp_workflow_content_build_obs "$project_name" "$project_var"
    ;;
  update-homebrew-tap.yml)
    radp_workflow_content_homebrew "$project_name" "$project_var"
    ;;
  attach-release-packages.yml)
    radp_workflow_content_attach_packages "$project_name" "$project_var"
    ;;
  cleanup-branches.yml)
    radp_workflow_content_cleanup_branches "$project_name" "$project_var"
    ;;
  *)
    return 1
    ;;
  esac
}

#######################################
# 升级 packaging 文件
# 使用与 scaffold 相同的内容生成器函数
#######################################
__radp_upgrade_packaging() {
  local target_dir="$1"
  local project_name="$2"
  local dry_run="$3"
  local force="$4"
  local show_diff="$5"

  local packaging_dir="$target_dir/packaging"
  local checksum_dir="$target_dir/.radp-cli/checksums/packaging"
  local has_changes=false

  # 如果 packaging 目录不存在
  if [[ ! -d "$packaging_dir" ]]; then
    if [[ "$force" == "true" ]]; then
      # --force: 创建 packaging 目录
      if [[ "$dry_run" == "true" ]]; then
        echo "  [CREATE] packaging/ (will be created with --force)"
      else
        mkdir -p "$packaging_dir"
        echo "  [CREATE] packaging/"
      fi
      has_changes=true
    else
      echo "  [SKIP] packaging/ (directory not found, use --force to create)"
      return 1
    fi
  fi

  # 定义打包文件列表
  local -a packaging_files=(
    "copr/${project_name}.spec"
    "obs/${project_name}.spec"
    "homebrew/${project_name}.rb"
    "obs/debian/control"
    "obs/debian/rules"
    "obs/debian/${project_name}.install"
    "obs/debian/${project_name}.links"
    "obs/debian/changelog"
    "obs/debian/copyright"
    "obs/debian/source/format"
  )

  local pkg_file
  for pkg_file in "${packaging_files[@]}"; do
    if __radp_upgrade_single_packaging "$target_dir" "$project_name" "$pkg_file" "$dry_run" "$force" "$show_diff"; then
      has_changes=true
    fi
  done

  # 升级 install.sh (单独处理因为不在 packaging 目录下)
  if __radp_upgrade_install_sh "$target_dir" "$project_name" "$dry_run" "$force" "$show_diff"; then
    has_changes=true
  fi

  if [[ "$has_changes" == "true" ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# 升级单个打包文件
#######################################
__radp_upgrade_single_packaging() {
  local target_dir="$1"
  local project_name="$2"
  local pkg_file="$3"
  local dry_run="$4"
  local force="$5"
  local show_diff="$6"

  local file_path="$target_dir/packaging/$pkg_file"
  local relative_path="packaging/$pkg_file"
  local checksum_dir="$target_dir/.radp-cli/checksums/packaging"
  local checksum_file="$checksum_dir/${pkg_file//\//_}"

  # 生成新内容
  local new_content
  new_content=$(__radp_packaging_generate_content "$project_name" "$pkg_file")

  if [[ -z "$new_content" ]]; then
    return 1
  fi

  # 文件不存在，创建
  if [[ ! -f "$file_path" ]]; then
    if [[ "$dry_run" == "true" ]]; then
      echo "  [CREATE] $relative_path"
    else
      mkdir -p "$(dirname "$file_path")"
      echo "$new_content" >"$file_path"
      # 保存 checksum
      mkdir -p "$checksum_dir"
      echo -n "$new_content" | shasum -a 256 | cut -d' ' -f1 >"$checksum_file"
      echo "  [CREATE] $relative_path"
    fi
    return 0
  fi

  # 对于 spec 文件，需要保留 Version 和 %changelog
  if [[ "$pkg_file" == *".spec" ]]; then
    new_content=$(__radp_packaging_merge_spec "$file_path" "$new_content")
  fi

  local current_content
  current_content=$(cat "$file_path")

  # 检查是否需要更新
  if [[ "$current_content" == "$new_content" ]]; then
    echo "  [OK]   $relative_path (up to date)"
    return 1
  fi

  # 检查用户是否修改过文件
  local should_update=false
  if [[ "$force" == "true" ]]; then
    should_update=true
  elif [[ -f "$checksum_file" ]]; then
    local saved_checksum current_checksum
    saved_checksum=$(cat "$checksum_file")
    current_checksum=$(echo -n "$current_content" | shasum -a 256 | cut -d' ' -f1)
    if [[ "$saved_checksum" == "$current_checksum" ]]; then
      should_update=true
    else
      echo "  [SKIP] $relative_path (user modified, use --force to override)"
      return 1
    fi
  else
    # 没有 checksum 文件
    # 对于 spec 文件：只更新 %install 段，其他内容保持不变，可以安全更新
    if [[ "$pkg_file" == *".spec" ]]; then
      should_update=true
    else
      # 其他文件（homebrew, debian等）：可能有用户自定义，跳过
      echo "  [SKIP] $relative_path (no checksum, use --force to override)"
      return 1
    fi
  fi

  if [[ "$should_update" == "true" ]]; then
    if [[ "$dry_run" == "true" ]]; then
      echo "  [UPDATE] $relative_path"
      if [[ "$show_diff" == "true" ]]; then
        diff -u <(echo "$current_content") <(echo "$new_content") | sed 's/^/    /' || true
      fi
    else
      echo "$new_content" >"$file_path"
      # 更新 checksum
      mkdir -p "$checksum_dir"
      echo -n "$new_content" | shasum -a 256 | cut -d' ' -f1 >"$checksum_file"
      echo "  [UPDATE] $relative_path"
    fi
    return 0
  fi

  return 1
}

#######################################
# 生成打包文件内容
#######################################
__radp_packaging_generate_content() {
  local project_name="$1"
  local pkg_file="$2"
  local today
  today="$(date '+%a %b %d %Y')"

  case "$pkg_file" in
  *".spec")
    radp_packaging_content_spec "$project_name" "$today"
    ;;
  *".rb")
    radp_packaging_content_homebrew "$project_name"
    ;;
  */debian/control)
    radp_packaging_content_debian_control "$project_name"
    ;;
  */debian/rules)
    radp_packaging_content_debian_rules "$project_name"
    ;;
  *".install")
    radp_packaging_content_debian_install "$project_name"
    ;;
  *".links")
    radp_packaging_content_debian_links "$project_name"
    ;;
  */debian/changelog)
    radp_packaging_content_debian_changelog "$project_name"
    ;;
  */debian/copyright)
    radp_packaging_content_debian_copyright "$project_name"
    ;;
  */debian/source/format)
    echo "3.0 (quilt)"
    ;;
  *)
    echo ""
    return 1
    ;;
  esac
}

#######################################
# 合并 spec 文件
# 只更新 %install 段，保留其他用户自定义内容
#######################################
__radp_packaging_merge_spec() {
  local current_file="$1"
  local new_content="$2"

  # 从新内容中提取 %install 段（到 %files 之前）
  local new_install_file
  new_install_file=$(mktemp)
  echo "$new_content" | awk '/%install/,/%files/ { if (!/^%files/) print }' >"$new_install_file"

  # 在当前文件中替换 %install 段
  awk -v install_file="$new_install_file" '
    BEGIN { in_install = 0 }
    /^%install/ {
      in_install = 1
      while ((getline line < install_file) > 0) print line
      close(install_file)
      next
    }
    /^%files/ {
      in_install = 0
    }
    !in_install { print }
  ' "$current_file"

  rm -f "$new_install_file"
}

#######################################
# 升级 install.sh
#######################################
__radp_upgrade_install_sh() {
  local target_dir="$1"
  local project_name="$2"
  local dry_run="$3"
  local force="$4"
  local show_diff="$5"

  local file_path="$target_dir/install.sh"
  local relative_path="install.sh"
  local checksum_dir="$target_dir/.radp-cli/checksums"
  local checksum_file="$checksum_dir/install_sh"

  local project_var="${project_name//-/_}"
  local project_upper="${project_var^^}"

  # 生成新内容
  local new_content
  new_content=$(radp_packaging_content_install_sh "$project_name")

  # 替换占位符
  new_content=$(echo "$new_content" | sed "s/__PROJECT_NAME__/${project_name}/g")
  new_content=$(echo "$new_content" | sed "s/__PROJECT_UPPER__/${project_upper}/g")
  new_content=$(echo "$new_content" | sed "s/__PROJECT_VAR__/${project_var}/g")

  # 文件不存在，创建
  if [[ ! -f "$file_path" ]]; then
    if [[ "$dry_run" == "true" ]]; then
      echo "  [CREATE] $relative_path"
    else
      echo "$new_content" >"$file_path"
      chmod +x "$file_path"
      # 保存 checksum
      mkdir -p "$checksum_dir"
      echo -n "$new_content" | shasum -a 256 | cut -d' ' -f1 >"$checksum_file"
      echo "  [CREATE] $relative_path"
    fi
    return 0
  fi

  local current_content
  current_content=$(cat "$file_path")

  # 检查是否需要更新
  if [[ "$current_content" == "$new_content" ]]; then
    echo "  [OK]   $relative_path (up to date)"
    return 1
  fi

  # 检查用户是否修改过文件
  local should_update=false
  if [[ "$force" == "true" ]]; then
    should_update=true
  elif [[ -f "$checksum_file" ]]; then
    local saved_checksum current_checksum
    saved_checksum=$(cat "$checksum_file")
    current_checksum=$(echo -n "$current_content" | shasum -a 256 | cut -d' ' -f1)
    if [[ "$saved_checksum" == "$current_checksum" ]]; then
      should_update=true
    else
      echo "  [SKIP] $relative_path (user modified, use --force to override)"
      return 1
    fi
  else
    # 没有 checksum 文件，跳过（可能是用户自定义）
    echo "  [SKIP] $relative_path (no checksum, use --force to override)"
    return 1
  fi

  if [[ "$should_update" == "true" ]]; then
    if [[ "$dry_run" == "true" ]]; then
      echo "  [UPDATE] $relative_path"
      if [[ "$show_diff" == "true" ]]; then
        diff -u <(echo "$current_content") <(echo "$new_content") | sed 's/^/    /' || true
      fi
    else
      echo "$new_content" >"$file_path"
      chmod +x "$file_path"
      # 更新 checksum
      mkdir -p "$checksum_dir"
      echo -n "$new_content" | shasum -a 256 | cut -d' ' -f1 >"$checksum_file"
      echo "  [UPDATE] $relative_path"
    fi
    return 0
  fi

  return 1
}
