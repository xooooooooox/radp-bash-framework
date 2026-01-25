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
    mkdir -p "$target_dir"/{bin,src/main/shell/{commands,config,libs,vars}}
    mkdir -p "$target_dir"/packaging/{copr,homebrew,obs/debian/source}
    mkdir -p "$target_dir"/.github/workflows

    # 生成入口脚本
    __radp_cli_scaffold_bin "$project_name" "$target_dir"

    # 生成示例命令
    __radp_cli_scaffold_commands "$project_name" "$target_dir"

    # 生成配置文件
    __radp_cli_scaffold_config "$project_name" "$target_dir"

    # 生成版本常量
    __radp_cli_scaffold_constants "$project_name" "$target_dir"

    # 生成 README
    __radp_cli_scaffold_readme "$project_name" "$target_dir"

    # 生成 .gitignore
    __radp_cli_scaffold_gitignore "$target_dir"

    # 生成 CHANGELOG
    __radp_cli_scaffold_changelog "$project_name" "$target_dir"

    # 生成安装脚本
    __radp_cli_scaffold_install "$project_name" "$target_dir"

    # 生成打包文件
    __radp_cli_scaffold_packaging "$project_name" "$target_dir"

    # 生成 GitHub workflows
    __radp_cli_scaffold_workflows "$project_name" "$target_dir"

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

    # 生成补全脚本时禁用 banner 和控制台日志，避免污染输出
    if [[ "${1:-}" == "completion" ]]; then
        export GX_RADP_FW_BANNER_MODE=off
        export GX_RADP_FW_LOG_CONSOLE_ENABLED=false
    fi

    # 设置用户配置路径（在加载 framework 之前）
    # 这样 framework 会自动加载 config/config.yaml 和 config/config-{env}.yaml
    export GX_RADP_FW_USER_CONFIG_PATH="$project_root/src/main/shell/config"

    # shellcheck source=/dev/null
    source "$(radp-bf --print-run)"

    # 设置应用信息
    radp_cli_set_app_name "__APPNAME__"
    radp_cli_set_commands_dir "$project_root/src/main/shell/commands"

    # 加载版本常量
    # shellcheck source=/dev/null
    source "$project_root/src/main/shell/vars/constants.sh"

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
    local project_var="${project_name//-/_}"
    cat > "$target_dir/src/main/shell/commands/version.sh" << VERSION_CMD
# @cmd
# @desc Show version information

cmd_version() {
    # Version is loaded from src/main/shell/vars/constants.sh
    echo "${project_name} \${gr_${project_var}_version:-v0.1.0}"
}
VERSION_CMD

    # completion 命令
    cat > "$target_dir/src/main/shell/commands/completion.sh" << 'COMPLETION_CMD'
# @cmd
# @desc Generate shell completion script
# @arg shell! Shell type (bash or zsh)
# @example completion bash > ~/.local/share/bash-completion/completions/__APP_NAME__
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
# 遵循 radp-bash-framework 的 YAML 配置机制
#######################################
__radp_cli_scaffold_config() {
    local project_name="$1"
    local target_dir="$2"
    local project_var="${project_name//-/_}"

    # 生成 config.yaml（遵循 radp-bash-framework 的配置结构）
    cat > "$target_dir/src/main/shell/config/config.yaml" << YAML_CONFIG
# $project_name configuration
# This file follows radp-bash-framework's configuration structure
# Priority: Environment variables (GX_*) > YAML values > defaults

radp:
  env: default

  # Framework settings override (optional)
  fw:
    banner-mode: on
    log:
      debug: false
      level: info
      console:
        enabled: true
      file:
        enabled: false
    user:
      config:
        automap: true  # Auto-generate config.sh from radp.extend.*

  # Application-specific extensions
  # Variables defined here will be available as gr_radp_extend_* in shell
  extend:
    ${project_var}:
      # Add your application config here
      # example:
      #   some_setting: value
YAML_CONFIG

    # 生成环境特定配置示例
    cat > "$target_dir/src/main/shell/config/config-dev.yaml" << YAML_DEV
# Development environment overrides for $project_name

radp:
  fw:
    log:
      debug: true
      level: debug

  extend:
    ${project_var}:
      # Development-specific overrides
YAML_DEV
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

## Prerequisites

radp-bash-framework must be installed:

\`\`\`bash
brew tap xooooooooox/radp
brew install radp-bash-framework
\`\`\`

Or see: https://github.com/xooooooooox/radp-bash-framework#installation

## Installation

### Script (curl / wget)

\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/xooooooooox/$project_name/main/install.sh | bash
\`\`\`

### Homebrew

\`\`\`bash
brew tap xooooooooox/radp
brew install $project_name
\`\`\`

### RPM (COPR)

\`\`\`bash
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y $project_name
\`\`\`

### From source

\`\`\`bash
git clone https://github.com/xooooooooox/$project_name
cd $project_name
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

## Configuration

This project uses radp-bash-framework's YAML configuration system.

### Configuration Files

\`\`\`
src/main/shell/config/
├── config.yaml          # Base configuration
└── config-dev.yaml      # Development environment overrides
\`\`\`

### Configuration Structure

\`\`\`yaml
radp:
  env: default           # Environment name (loads config-{env}.yaml)

  fw:                    # Framework settings
    banner-mode: on
    log:
      debug: false
      level: info

  extend:                # Application-specific settings
    ${project_name//-/_}:
      version: v0.1.0
      # Your custom config here
\`\`\`

### Accessing Config in Code

Variables from \`radp.extend.*\` are available as \`gr_radp_extend_*\`:

\`\`\`bash
# radp.extend.${project_name//-/_}.version -> gr_radp_extend_${project_name//-/_}_version
echo "\$gr_radp_extend_${project_name//-/_}_version"
\`\`\`

### Environment Variables

Override any config with \`GX_*\` prefix:

\`\`\`bash
GX_RADP_FW_LOG_DEBUG=true $project_name hello
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

## CI/CD

This project includes GitHub Actions workflows for automated releases.

### Workflow Chain

\`\`\`
release-prep (manual trigger)
       │
       ▼
   PR merged
       │
       ▼
create-version-tag
       │
       ├──────────────────────┬──────────────────────┐
       ▼                      ▼                      ▼
update-spec-version    update-homebrew-tap    (GitHub Release)
       │
       ├──────────────┐
       ▼              ▼
build-copr-package  build-obs-package
\`\`\`

### Release Process

1. Trigger \`release-prep\` workflow with bump_type (patch/minor/major/manual)
2. Review and merge the generated PR
3. Subsequent workflows run automatically

### Required Secrets

Configure these secrets in your GitHub repository settings (\`Settings > Secrets and variables > Actions\`):

#### Homebrew Tap (required for \`update-homebrew-tap\`)

| Secret | Description |
|--------|-------------|
| \`HOMEBREW_TAP_TOKEN\` | GitHub Personal Access Token with \`repo\` scope for homebrew-radp repository |

#### COPR (required for \`build-copr-package\`)

| Secret | Description |
|--------|-------------|
| \`COPR_LOGIN\` | COPR API login (from <https://copr.fedorainfracloud.org/api/>) |
| \`COPR_TOKEN\` | COPR API token |
| \`COPR_USERNAME\` | COPR username |
| \`COPR_PROJECT\` | COPR project name (e.g., \`radp\`) |

#### OBS (required for \`build-obs-package\`)

| Secret | Description |
|--------|-------------|
| \`OBS_USERNAME\` | OBS username |
| \`OBS_PASSWORD\` | OBS password or API token |
| \`OBS_PROJECT\` | OBS project name |
| \`OBS_PACKAGE\` | OBS package name |
| \`OBS_API_URL\` | (Optional) OBS API URL, defaults to \`https://api.opensuse.org\` |

### Skipping Workflows

If you don't need certain distribution channels:
- Delete the corresponding workflow file from \`.github/workflows/\`
- Or leave secrets unconfigured (workflow will skip with missing secrets)

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

#######################################
# 生成版本常量文件
#######################################
__radp_cli_scaffold_constants() {
    local project_name="$1"
    local target_dir="$2"
    local project_var="${project_name//-/_}"

    cat > "$target_dir/src/main/shell/vars/constants.sh" << CONSTANTS
#!/usr/bin/env bash

# ${project_name} version - single source of truth for release management
declare -gr gr_${project_var}_version=v0.1.0
CONSTANTS
}

#######################################
# 生成 CHANGELOG
#######################################
__radp_cli_scaffold_changelog() {
    local project_name="$1"
    local target_dir="$2"

    cat > "$target_dir/CHANGELOG.md" << 'CHANGELOG'
# CHANGELOG

## v0.1.0 - Initial Release

- Initial release
CHANGELOG
}

#######################################
# 生成安装脚本
#######################################
__radp_cli_scaffold_install() {
    local project_name="$1"
    local target_dir="$2"
    local project_var="${project_name//-/_}"
    local project_upper="${project_var^^}"

    cat > "$target_dir/install.sh" << 'INSTALL_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="xooooooooox"
REPO_NAME="__PROJECT_NAME__"
tmp_dir=""

log() { printf "%s\n" "$*"; }
err() { printf "__PROJECT_NAME__ install: %s\n" "$*" >&2; }
die() { err "$@"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

detect_fetcher() {
  if have curl; then echo "curl"; return 0; fi
  if have wget; then echo "wget"; return 0; fi
  if have fetch; then echo "fetch"; return 0; fi
  return 1
}

fetch_url() {
  local tool="$1" url="$2" out="$3"
  case "${tool}" in
    curl) curl -fsSL "${url}" -o "${out}" ;;
    wget) wget -qO "${out}" "${url}" ;;
    fetch) fetch -qo "${out}" "${url}" ;;
    *) return 1 ;;
  esac
}

fetch_text() {
  local tool="$1" url="$2"
  case "${tool}" in
    curl) curl -fsSL "${url}" ;;
    wget) wget -qO- "${url}" ;;
    fetch) fetch -qo- "${url}" ;;
    *) return 1 ;;
  esac
}

resolve_ref() {
  local manual_ref="${__PROJECT_UPPER___REF:-}"
  local manual_version="${__PROJECT_UPPER___VERSION:-}"
  if [[ -n "${manual_ref}" ]]; then echo "${manual_ref}"; return 0; fi
  if [[ -n "${manual_version}" ]]; then echo "${manual_version}"; return 0; fi
  local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
  local json
  json="$(fetch_text "${FETCH_TOOL}" "${api_url}" || true)"
  if [[ -z "${json}" ]]; then
    die "Failed to fetch latest release; set __PROJECT_UPPER___VERSION or __PROJECT_UPPER___REF."
  fi
  local tag
  tag="$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"${json}")"
  tag="${tag%%$'\n'*}"
  if [[ -z "${tag}" ]]; then
    die "Failed to parse latest tag; set __PROJECT_UPPER___VERSION or __PROJECT_UPPER___REF."
  fi
  echo "${tag}"
}

cleanup() { [[ -n "${tmp_dir:-}" ]] && rm -rf "${tmp_dir}"; }

main() {
  FETCH_TOOL="$(detect_fetcher)" || die "Requires curl, wget, or fetch."
  local install_dir="${__PROJECT_UPPER___INSTALL_DIR:-$HOME/.local/lib/${REPO_NAME}}"
  local bin_dir="${__PROJECT_UPPER___BIN_DIR:-$HOME/.local/bin}"
  local ref; ref="$(resolve_ref)"

  if [[ -z "${install_dir}" || "${install_dir}" == "/" ]]; then
    die "Unsafe install dir: ${install_dir}"
  fi
  if [[ "${__PROJECT_UPPER___ALLOW_ANY_DIR:-0}" != "1" ]]; then
    if [[ "$(basename "${install_dir}")" != "${REPO_NAME}" ]]; then
      die "Install dir must end with ${REPO_NAME} (set __PROJECT_UPPER___ALLOW_ANY_DIR=1 to override)."
    fi
  fi

  local tar_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/${ref}.tar.gz"
  tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t "${REPO_NAME}")"
  local tarball="${tmp_dir}/${REPO_NAME}.tar.gz"
  trap cleanup EXIT

  log "Downloading ${tar_url}"
  fetch_url "${FETCH_TOOL}" "${tar_url}" "${tarball}" || die "Failed to download ${tar_url}"

  local tar_listing root_dir
  tar_listing="$(tar -tzf "${tarball}")"
  root_dir="${tar_listing%%/*}"
  [[ -z "${root_dir}" ]] && die "Unable to read archive structure."

  tar -xzf "${tarball}" -C "${tmp_dir}"
  local src_root="${tmp_dir}/${root_dir}"
  [[ ! -d "${src_root}/bin" || ! -d "${src_root}/src" ]] && die "Archive layout unexpected."

  rm -rf "${install_dir}"
  mkdir -p "${install_dir}"
  cp -R "${src_root}/bin" "${install_dir}/"
  cp -R "${src_root}/src" "${install_dir}/"

  chmod 0755 "${install_dir}/bin/__PROJECT_NAME__"
  find "${install_dir}/src" -type f -name "*.sh" -exec chmod 0755 {} \;

  mkdir -p "${bin_dir}"
  local target="${install_dir}/bin/__PROJECT_NAME__"
  local link_path="${bin_dir}/__PROJECT_NAME__"
  [[ -e "${link_path}" && ! -L "${link_path}" ]] && die "Refusing to overwrite existing file: ${link_path}"
  ln -sf "${target}" "${link_path}"

  log "Installed to ${install_dir}"
  log "Ensure ${bin_dir} is in your PATH."
  log ""
  log "Prerequisites:"
  log "  - radp-bash-framework must be installed and in PATH"
  log "  See: https://github.com/xooooooooox/radp-bash-framework"
  log ""
  log "Run: __PROJECT_NAME__ --help"
}

main "$@"
INSTALL_SCRIPT

    # 替换占位符
    sed -i.bak "s/__PROJECT_NAME__/${project_name}/g" "$target_dir/install.sh"
    sed -i.bak "s/__PROJECT_UPPER__/${project_upper}/g" "$target_dir/install.sh"
    rm -f "$target_dir/install.sh.bak"
    chmod +x "$target_dir/install.sh"
}

#######################################
# 生成打包文件
#######################################
__radp_cli_scaffold_packaging() {
    local project_name="$1"
    local target_dir="$2"
    local today
    today="$(date '+%a %b %d %Y')"

    # COPR spec
    cat > "$target_dir/packaging/copr/${project_name}.spec" << SPEC
Name:           ${project_name}
Version:        0.1.0
Release:        1%{?dist}
Summary:        CLI tool built with radp-bash-framework

License:        MIT
URL:            https://github.com/xooooooooox/${project_name}
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

BuildArch:      noarch
Requires:       bash
Requires:       coreutils
Requires:       radp-bash-framework

%description
${project_name} is a CLI tool built with radp-bash-framework.

%prep
%setup -q -n ${project_name}-%{version}

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_libdir}/${project_name}
cp -a bin %{buildroot}%{_libdir}/${project_name}/
cp -a src %{buildroot}%{_libdir}/${project_name}/
chmod 0755 %{buildroot}%{_libdir}/${project_name}/bin/${project_name}
find %{buildroot}%{_libdir}/${project_name}/src -type f -name "*.sh" -exec chmod 0755 {} \;
mkdir -p %{buildroot}%{_bindir}
ln -s %{_libdir}/${project_name}/bin/${project_name} %{buildroot}%{_bindir}/${project_name}

%files
%license LICENSE
%doc README.md
%{_bindir}/${project_name}
%{_libdir}/${project_name}/

%changelog
* ${today} xooooooooox <xozoz.sos@gmail.com> - 0.1.0-1
- Initial RPM package
SPEC

    # OBS spec (same as COPR)
    cp "$target_dir/packaging/copr/${project_name}.spec" "$target_dir/packaging/obs/${project_name}.spec"

    # Debian control
    cat > "$target_dir/packaging/obs/debian/control" << CONTROL
Source: ${project_name}
Section: utils
Priority: optional
Maintainer: xooooooooox <xozoz.sos@gmail.com>
Build-Depends: debhelper-compat (= 13)
Standards-Version: 4.6.2
Homepage: https://github.com/xooooooooox/${project_name}
Rules-Requires-Root: no

Package: ${project_name}
Architecture: all
Depends: \${misc:Depends}, bash, coreutils, radp-bash-framework
Description: CLI tool built with radp-bash-framework.
 ${project_name} is a CLI tool built with radp-bash-framework.
CONTROL

    # Debian rules
    cat > "$target_dir/packaging/obs/debian/rules" << 'RULES'
#!/usr/bin/make -f

%:
	dh $@

override_dh_auto_configure:
	:

override_dh_auto_build:
	:

override_dh_auto_install:
	:

override_dh_fixperms:
	dh_fixperms
	chmod 0755 debian/__PROJECT_NAME__/usr/lib/__PROJECT_NAME__/bin/__PROJECT_NAME__
	find debian/__PROJECT_NAME__/usr/lib/__PROJECT_NAME__/src -type f -name '*.sh' -exec chmod 0755 {} \;
RULES
    sed -i.bak "s/__PROJECT_NAME__/${project_name}/g" "$target_dir/packaging/obs/debian/rules"
    rm -f "$target_dir/packaging/obs/debian/rules.bak"

    # Debian install
    cat > "$target_dir/packaging/obs/debian/${project_name}.install" << INSTALL
bin usr/lib/${project_name}
src usr/lib/${project_name}
INSTALL

    # Debian links
    cat > "$target_dir/packaging/obs/debian/${project_name}.links" << LINKS
usr/lib/${project_name}/bin/${project_name} usr/bin/${project_name}
LINKS

    # Debian changelog
    cat > "$target_dir/packaging/obs/debian/changelog" << CHANGELOG
${project_name} (0.0.0-1) unstable; urgency=medium

  * Placeholder entry. The CI workflow rewrites this changelog.

 -- xooooooooox <xozoz.sos@gmail.com>  Thu, 01 Jan 1970 00:00:00 +0000
CHANGELOG

    # Debian copyright
    cat > "$target_dir/packaging/obs/debian/copyright" << COPYRIGHT
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${project_name}
Source: https://github.com/xooooooooox/${project_name}

Files: *
Copyright: 2024-present xooooooooox
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
COPYRIGHT

    # Debian source format
    echo "3.0 (quilt)" > "$target_dir/packaging/obs/debian/source/format"

    # Homebrew formula template
    # Convert project name to Ruby class name (capitalize first letter, remove hyphens and capitalize following letters)
    local class_name
    class_name="$(echo "${project_name}" | sed -r 's/(^|-)([a-z])/\U\2/g')"

    cat > "$target_dir/packaging/homebrew/${project_name}.rb" << FORMULA
# Homebrew formula template for ${project_name}
# The CI workflow uses this template and replaces placeholders with actual values.
#
# Placeholders:
#   %%TARBALL_URL%% - GitHub archive URL for the release tag
#   %%SHA256%%      - SHA256 checksum of the tarball
#   %%VERSION%%     - Version number (without 'v' prefix)
#
# Installation:
#   brew tap xooooooooox/radp
#   brew install ${project_name}

class ${class_name} < Formula
  desc "CLI tool built with radp-bash-framework"
  homepage "https://github.com/xooooooooox/${project_name}"
  url "%%TARBALL_URL%%"
  sha256 "%%SHA256%%"
  version "%%VERSION%%"
  license "MIT"

  depends_on "xooooooooox/radp/radp-bash-framework"

  def install
    # Install to libexec
    libexec.install "bin", "src"

    # Create wrapper script that sets up paths
    (bin/"${project_name}").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/bin/${project_name}" "\\\$@"
    EOS
  end

  def caveats
    <<~EOS
      ${project_name} requires radp-bash-framework (installed as dependency).

      Quick start:
        ${project_name} --help
    EOS
  end

  test do
    system "#{bin}/${project_name}", "--help"
  end
end
FORMULA
}

#######################################
# 生成 GitHub workflows
#######################################
__radp_cli_scaffold_workflows() {
    local project_name="$1"
    local target_dir="$2"
    local project_var="${project_name//-/_}"

    __radp_cli_scaffold_workflow_release_prep "$project_name" "$target_dir" "$project_var"
    __radp_cli_scaffold_workflow_create_tag "$project_name" "$target_dir" "$project_var"
    __radp_cli_scaffold_workflow_update_spec "$project_name" "$target_dir" "$project_var"
    __radp_cli_scaffold_workflow_build_copr "$project_name" "$target_dir" "$project_var"
    __radp_cli_scaffold_workflow_build_obs "$project_name" "$target_dir" "$project_var"
    __radp_cli_scaffold_workflow_homebrew "$project_name" "$target_dir" "$project_var"
}

__radp_cli_scaffold_workflow_release_prep() {
    local project_name="$1"
    local target_dir="$2"
    local project_var="$3"

    cat > "$target_dir/.github/workflows/release-prep.yml" << WORKFLOW
name: Release prep

on:
  workflow_dispatch:
    inputs:
      bump_type:
        description: "Release version bump type"
        type: choice
        options: [patch, minor, major, manual]
        default: patch
        required: true
      version:
        description: "Manual version (vX.Y.Z) when bump_type=manual"
        required: false

permissions:
  contents: write
  pull-requests: write

jobs:
  release-prep:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - run: git fetch --tags --force
      - name: Resolve version
        id: version
        run: |
          set -euo pipefail
          bump_type="\${{ inputs.bump_type }}"
          manual_version="\${{ inputs.version }}"
          latest_tag="\$(git tag --list 'v*' --sort=-v:refname | head -n 1)"
          [[ -z "\${latest_tag}" ]] && { echo "No tags found" >&2; exit 1; }
          [[ ! "\${latest_tag}" =~ ^v([0-9]+)\\.([0-9]+)\\.([0-9]+)\$ ]] && exit 1
          major="\${BASH_REMATCH[1]}" minor="\${BASH_REMATCH[2]}" patch="\${BASH_REMATCH[3]}"
          case "\${bump_type}" in
            patch) version="v\${major}.\${minor}.\$((patch + 1))" ;;
            minor) version="v\${major}.\$((minor + 1)).0" ;;
            major) version="v\$((major + 1)).0.0" ;;
            manual) version="\${manual_version}" ;;
          esac
          echo "version=\${version}" >> "\$GITHUB_OUTPUT"
      - name: Create branch and update files
        run: |
          set -euo pipefail
          version="\${{ steps.version.outputs.version }}"
          version_no_prefix="\${version#v}"
          git checkout -b "workflow/\${version}"
          sed -i "s/^declare -gr gr_${project_var}_version=.*/declare -gr gr_${project_var}_version=\${version}/" src/main/shell/vars/constants.sh
          sed -i "s/^Version:.*/Version:        \${version_no_prefix}/" packaging/copr/${project_name}.spec
          sed -i "s/^Version:.*/Version:        \${version_no_prefix}/" packaging/obs/${project_name}.spec
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add -A
          git commit -m "Release prep \${version}"
          git push --set-upstream origin "workflow/\${version}"
      - name: Create PR
        env:
          GH_TOKEN: \${{ github.token }}
        run: |
          version="\${{ steps.version.outputs.version }}"
          gh pr create --base main --head "workflow/\${version}" --title "Release \${version}" --body "Release prep for \${version}"
WORKFLOW
}

__radp_cli_scaffold_workflow_create_tag() {
    local project_name="$1"
    local target_dir="$2"
    local project_var="$3"

    cat > "$target_dir/.github/workflows/create-version-tag.yml" << WORKFLOW
name: Create version tag

on:
  workflow_dispatch:
  pull_request:
    types: [closed]
    branches: [main]

permissions:
  contents: write

jobs:
  create-version-tag:
    if: |
      (github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main') ||
      (github.event_name == 'pull_request' && github.event.pull_request.merged == true && startsWith(github.event.pull_request.head.ref, 'workflow/v'))
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          ref: main
      - run: git fetch --tags --force
      - name: Read and tag
        run: |
          set -euo pipefail
          version=\$(sed -n 's/^declare -gr gr_${project_var}_version=//p' src/main/shell/vars/constants.sh | head -n 1)
          [[ -z "\$version" ]] && exit 1
          git rev-parse "\$version" >/dev/null 2>&1 && { echo "Tag exists"; exit 0; }
          git tag "\$version"
          git push origin "\$version"
WORKFLOW
}

__radp_cli_scaffold_workflow_update_spec() {
    local project_name="$1"
    local target_dir="$2"
    local project_var="$3"

    cat > "$target_dir/.github/workflows/update-spec-version.yml" << WORKFLOW
name: Update spec version

on:
  workflow_run:
    workflows: [Create version tag]
    types: [completed]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  update-spec-version:
    if: github.event_name != 'workflow_run' || github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          ref: main
      - run: git fetch --tags --force
      - name: Update specs
        run: |
          set -euo pipefail
          version=\$(sed -n 's/^declare -gr gr_${project_var}_version=//p' src/main/shell/vars/constants.sh | head -n 1)
          version_no_prefix="\${version#v}"
          sed -i "s/^Version:.*/Version:        \${version_no_prefix}/" packaging/copr/${project_name}.spec
          sed -i "s/^Version:.*/Version:        \${version_no_prefix}/" packaging/obs/${project_name}.spec
          git diff --quiet && exit 0
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add packaging/
          git commit -m "Update spec version to \${version}"
          git push
WORKFLOW
}

__radp_cli_scaffold_workflow_build_copr() {
    local project_name="$1"
    local target_dir="$2"
    local project_var="$3"

    cat > "$target_dir/.github/workflows/build-copr-package.yml" << WORKFLOW
name: Build COPR package

on:
  workflow_run:
    workflows: [Update spec version]
    types: [completed]

permissions:
  contents: read

jobs:
  build-copr-package:
    if: github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    env:
      COPR_LOGIN: \${{ secrets.COPR_LOGIN }}
      COPR_TOKEN: \${{ secrets.COPR_TOKEN }}
      COPR_USERNAME: \${{ secrets.COPR_USERNAME }}
      COPR_PROJECT: \${{ secrets.COPR_PROJECT }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Build
        run: |
          set -euo pipefail
          for v in COPR_LOGIN COPR_TOKEN COPR_USERNAME COPR_PROJECT; do
            [[ -z "\${!v:-}" ]] && { echo "Missing \$v" >&2; exit 1; }
          done
          version=\$(sed -n 's/^declare -gr gr_${project_var}_version=//p' src/main/shell/vars/constants.sh | head -n 1)
          git fetch --tags --force
          git rev-parse "\$version" >/dev/null 2>&1 || { echo "Tag not found"; exit 0; }
          tag_sha=\$(git rev-parse "\$version^{commit}")
          pip install copr-cli
          mkdir -p ~/.config
          cat > ~/.config/copr << EOF
          [copr-cli]
          login = \${COPR_LOGIN}
          token = \${COPR_TOKEN}
          username = \${COPR_USERNAME}
          copr_url = https://copr.fedorainfracloud.org
          EOF
          copr-cli buildscm "\${COPR_PROJECT}" --clone-url "\${GITHUB_SERVER_URL}/\${GITHUB_REPOSITORY}.git" --commit "\${tag_sha}" --subdir "packaging/copr" --spec "${project_name}.spec"
WORKFLOW
}

__radp_cli_scaffold_workflow_build_obs() {
    local project_name="$1"
    local target_dir="$2"
    local project_var="$3"

    cat > "$target_dir/.github/workflows/build-obs-package.yml" << WORKFLOW
name: Build OBS package

on:
  workflow_run:
    workflows: [Update spec version]
    types: [completed]
  workflow_dispatch:

permissions:
  contents: read

jobs:
  build-obs-package:
    if: github.event_name != 'workflow_run' || github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    env:
      OBS_USERNAME: \${{ secrets.OBS_USERNAME }}
      OBS_PASSWORD: \${{ secrets.OBS_PASSWORD }}
      OBS_PROJECT: \${{ secrets.OBS_PROJECT }}
      OBS_PACKAGE: \${{ secrets.OBS_PACKAGE }}
      OBS_API_URL: \${{ secrets.OBS_API_URL }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - run: git fetch --tags --force
      - name: Build
        run: |
          set -euo pipefail
          for v in OBS_USERNAME OBS_PASSWORD OBS_PROJECT OBS_PACKAGE; do
            [[ -z "\${!v:-}" ]] && { echo "Missing \$v" >&2; exit 1; }
          done
          : "\${OBS_API_URL:=https://api.opensuse.org}"
          version=\$(sed -n 's/^declare -gr gr_${project_var}_version=//p' src/main/shell/vars/constants.sh | head -n 1)
          version_no_prefix="\${version#v}"
          git rev-parse "\$version" >/dev/null 2>&1 || { echo "Tag not found"; exit 0; }
          sudo apt-get update && sudo apt-get install -y osc dpkg-dev debhelper
          cat > ~/.oscrc << EOF
          [general]
          apiurl = \${OBS_API_URL}
          [\${OBS_API_URL}]
          user = \${OBS_USERNAME}
          pass = \${OBS_PASSWORD}
          EOF
          chmod 600 ~/.oscrc
          osc -A "\${OBS_API_URL}" checkout "\${OBS_PROJECT}" "\${OBS_PACKAGE}"
          pkg_dir="\${OBS_PROJECT}/\${OBS_PACKAGE}"
          find "\$pkg_dir" -mindepth 1 -not -path "\$pkg_dir/.osc*" -delete
          cp packaging/obs/${project_name}.spec "\$pkg_dir/"
          curl -L -o "\$pkg_dir/v\${version_no_prefix}.tar.gz" "\${GITHUB_SERVER_URL}/\${GITHUB_REPOSITORY}/archive/refs/tags/\${version}.tar.gz"
          cp -a packaging/obs/debian "\$pkg_dir/"
          cd "\$pkg_dir" && osc addremove && osc commit -m "Update to \${version}"
WORKFLOW
}

__radp_cli_scaffold_workflow_homebrew() {
    local project_name="$1"
    local target_dir="$2"
    local project_var="$3"

    cat > "$target_dir/.github/workflows/update-homebrew-tap.yml" << WORKFLOW
name: Update Homebrew Tap

on:
  push:
    tags: ["v*"]
  workflow_run:
    workflows: [Create version tag]
    types: [completed]
  workflow_dispatch:

jobs:
  update-tap:
    if: github.event_name != 'workflow_run' || github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    permissions:
      contents: read
    env:
      TAP_REPO: xooooooooox/homebrew-radp
      TAP_FORMULA_PATH: Formula/${project_name}.rb
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - run: git fetch --tags --force
      - uses: actions/checkout@v4
        with:
          repository: \${{ env.TAP_REPO }}
          path: homebrew-radp
          token: \${{ secrets.HOMEBREW_TAP_TOKEN }}
      - name: Update formula
        run: |
          set -euo pipefail
          version=\$(sed -n 's/^declare -gr gr_${project_var}_version=//p' src/main/shell/vars/constants.sh | head -n 1)
          version_no_prefix="\${version#v}"
          tarball_url="https://github.com/\${GITHUB_REPOSITORY}/archive/refs/tags/\${version}.tar.gz"
          sha256=\$(curl -sL "\$tarball_url" | sha256sum | awk '{print \$1}')
          formula="homebrew-radp/\${TAP_FORMULA_PATH}"
          [[ ! -f "\$formula" ]] && { echo "Formula not found"; exit 0; }
          sed -i "s|url \"[^\"]*\"|url \"\$tarball_url\"|" "\$formula"
          sed -i "s|sha256 \"[^\"]*\"|sha256 \"\$sha256\"|" "\$formula"
          sed -i "s|version \"[^\"]*\"|version \"\$version_no_prefix\"|" "\$formula"
          cd homebrew-radp
          git diff --quiet && exit 0
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add "\${TAP_FORMULA_PATH}"
          git commit -m "Update ${project_name} to \${version}"
          git push
WORKFLOW
}
