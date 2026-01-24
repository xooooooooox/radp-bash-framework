#!/usr/bin/env bash
# toolkit module: cli/08_scaffold.sh
# 项目脚手架：生成基于 radp-bash-framework 的 CLI 项目

#######################################
# 创建新的 CLI 项目
# Arguments:
#   1 - project_name: 项目名称
#   2 - target_dir: 目标目录（可选，默认为当前目录下的项目名）
# Returns:
#   0 - 成功
#   1 - 失败
#######################################
radp_cli_scaffold_new() {
    local project_name="$1"
    local target_dir="${2:-$project_name}"

    # 验证项目名称
    if [[ ! "$project_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        radp_log_error "Invalid project name: $project_name"
        radp_log_error "Project name must start with a letter and contain only letters, numbers, underscores, and hyphens."
        return 1
    fi

    # 检查目标目录
    if [[ -d "$target_dir" ]]; then
        if [[ -n "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
            radp_log_error "Directory already exists and is not empty: $target_dir"
            return 1
        fi
    fi

    radp_log_info "Creating new CLI project: $project_name"

    # 创建目录结构
    mkdir -p "$target_dir"/{bin,src/main/shell/{commands,config,libs}}

    # 生成入口脚本
    __radp_cli_scaffold_bin "$project_name" "$target_dir"

    # 生成示例命令
    __radp_cli_scaffold_commands "$project_name" "$target_dir"

    # 生成配置文件
    __radp_cli_scaffold_config "$project_name" "$target_dir"

    # 生成 README
    __radp_cli_scaffold_readme "$project_name" "$target_dir"

    # 生成 .gitignore
    __radp_cli_scaffold_gitignore "$target_dir"

    radp_log_info "Project created successfully: $target_dir"
    radp_log_info ""
    radp_log_info "Next steps:"
    radp_log_info "  cd $target_dir"
    radp_log_info "  ./bin/$project_name --help"
    radp_log_info ""
    radp_log_info "Add new commands by creating files in src/main/shell/commands/"
}

#######################################
# 生成入口脚本
#######################################
__radp_cli_scaffold_bin() {
    local project_name="$1"
    local target_dir="$2"

    cat > "$target_dir/bin/$project_name" << 'ENTRY_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# 解析脚本真实路径
__APPNAME___resolve_script_dir() {
    local src="${BASH_SOURCE[0]}"
    while [[ -L "$src" ]]; do
        local dir
        dir="$(cd -P "$(dirname "$src")" && pwd)"
        src="$(readlink "$src")"
        [[ "$src" != /* ]] && src="$dir/$src"
    done
    cd -P "$(dirname "$src")" && pwd
}

# 获取项目根目录
__APPNAME___get_project_root() {
    local bin_dir
    bin_dir=$(__APPNAME___resolve_script_dir)
    dirname "$bin_dir"
}

# 主函数
__APPNAME___main() {
    local project_root
    project_root=$(__APPNAME___get_project_root)

    # 加载 radp-bash-framework
    if ! command -v radp-bf &>/dev/null; then
        echo "Error: radp-bash-framework not found. Please install it first." >&2
        echo "  See: https://github.com/xooooooooox/radp-bash-framework" >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source "$(radp-bf --print-run)"

    # 配置应用
    # shellcheck source=/dev/null
    [[ -f "$project_root/src/main/shell/config/app.sh" ]] && \
        source "$project_root/src/main/shell/config/app.sh"

    # 设置应用信息
    radp_cli_set_app_name "__APPNAME__"
    radp_cli_set_commands_dir "$project_root/src/main/shell/commands"

    # 加载项目私有库（如果存在）
    if [[ -d "$project_root/src/main/shell/libs" ]]; then
        local lib_file
        while IFS= read -r -d '' lib_file; do
            # shellcheck source=/dev/null
            source "$lib_file"
        done < <(find "$project_root/src/main/shell/libs" -type f -name "*.sh" -print0 | sort -z)
    fi

    # 运行
    radp_app_run "$@"
}

__APPNAME___main "$@"
ENTRY_SCRIPT

    # 替换占位符
    sed -i.bak "s/__APPNAME__/${project_name//-/_}/g" "$target_dir/bin/$project_name"
    rm -f "$target_dir/bin/$project_name.bak"

    # 设置执行权限
    chmod +x "$target_dir/bin/$project_name"
}

#######################################
# 生成示例命令
#######################################
__radp_cli_scaffold_commands() {
    local project_name="$1"
    local target_dir="$2"

    # version 命令
    cat > "$target_dir/src/main/shell/commands/version.sh" << 'VERSION_CMD'
# @cmd
# @desc Show version information

cmd_version() {
    echo "__APP_NAME__ v0.1.0"
}
VERSION_CMD
    sed -i.bak "s/__APP_NAME__/$project_name/g" "$target_dir/src/main/shell/commands/version.sh"
    rm -f "$target_dir/src/main/shell/commands/version.sh.bak"

    # completion 命令
    cat > "$target_dir/src/main/shell/commands/completion.sh" << 'COMPLETION_CMD'
# @cmd
# @desc Generate shell completion script
# @arg shell! Shell type (bash or zsh)
# @example completion bash > ~/.bash_completion.d/__APP_NAME__
# @example completion zsh > ~/.zfunc/___APP_NAME__

cmd_completion() {
    local shell="${1:-}"

    if [[ -z "$shell" ]]; then
        radp_log_error "Shell type required (bash or zsh)"
        return 1
    fi

    radp_cli_completion_generate "$shell"
}
COMPLETION_CMD
    sed -i.bak "s/__APP_NAME__/$project_name/g" "$target_dir/src/main/shell/commands/completion.sh"
    rm -f "$target_dir/src/main/shell/commands/completion.sh.bak"

    # hello 示例命令
    cat > "$target_dir/src/main/shell/commands/hello.sh" << 'HELLO_CMD'
# @cmd
# @desc Say hello (example command)
# @arg name Name to greet
# @option -u, --uppercase Convert to uppercase
# @example hello
# @example hello World
# @example hello --uppercase World

cmd_hello() {
    local name="${1:-World}"
    local message="Hello, $name!"

    if [[ "${opt_uppercase:-}" == "true" ]]; then
        message="${message^^}"
    fi

    echo "$message"
}
HELLO_CMD
}

#######################################
# 生成配置文件
#######################################
__radp_cli_scaffold_config() {
    local project_name="$1"
    local target_dir="$2"

    cat > "$target_dir/src/main/shell/config/app.sh" << APP_CONFIG
#!/usr/bin/env bash
# Application configuration for $project_name

# Application version
declare -gr ${project_name//-/_}_version="v0.1.0"
APP_CONFIG
}

#######################################
# 生成 README
#######################################
__radp_cli_scaffold_readme() {
    local project_name="$1"
    local target_dir="$2"

    cat > "$target_dir/README.md" << README
# $project_name

A CLI tool built with [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework).

## Installation

\`\`\`bash
# Clone the repository
git clone <repository-url>
cd $project_name

# Make sure radp-bash-framework is installed
brew install xooooooooox/radp/radp-bash-framework
# or see: https://github.com/xooooooooox/radp-bash-framework#installation

# Run
./bin/$project_name --help
\`\`\`

## Usage

\`\`\`bash
# Show help
$project_name --help

# Show version
$project_name version

# Example command
$project_name hello World

# Generate shell completion
$project_name completion bash > ~/.bash_completion.d/$project_name
\`\`\`

## Adding Commands

Create new command files in \`src/main/shell/commands/\`:

\`\`\`bash
# src/main/shell/commands/mycommand.sh

# @cmd
# @desc My command description
# @arg name! Required argument
# @option -v, --verbose Enable verbose output
# @example mycommand foo
# @example mycommand --verbose bar

cmd_mycommand() {
    local name="\$1"

    if [[ "\${opt_verbose:-}" == "true" ]]; then
        echo "Running in verbose mode"
    fi

    echo "Hello, \$name!"
}
\`\`\`

### Subcommands

Create a directory for subcommand groups:

\`\`\`
src/main/shell/commands/
├── mygroup/
│   ├── create.sh    # $project_name mygroup create
│   └── delete.sh    # $project_name mygroup delete
└── hello.sh         # $project_name hello
\`\`\`

## License

MIT
README
}

#######################################
# 生成 .gitignore
#######################################
__radp_cli_scaffold_gitignore() {
    local target_dir="$1"

    cat > "$target_dir/.gitignore" << 'GITIGNORE'
# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Temporary files
tmp/
temp/
*.tmp
*.bak
GITIGNORE
}
