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
  mkdir -p "$target_dir"/packaging/{copr,homebrew,obs/debian/source}
  mkdir -p "$target_dir"/.github/workflows

  # 生成入口脚本
  __radp_cli_scaffold_bin "$project_name" "$target_dir"

  # 生成示例命令
  __radp_cli_scaffold_commands "$project_name" "$target_dir"

  # 生成配置文件（包含版本配置）
  __radp_cli_scaffold_config "$project_name" "$target_dir"

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

  # 初始化项目元数据（用于 upgrade 命令）
  radp_cli_init_metadata "$target_dir" "$project_name" "$(radp_get_fw_install_version)"

  radp_log_info "Project created successfully: $target_dir"
  radp_log_info ""
  radp_log_info "Next steps:"
  radp_log_info "  cd $target_dir"
  radp_log_info "  ./bin/$project_name --help"
  radp_log_info ""
  radp_log_info "Add new commands by creating files in src/main/shell/commands/"
}

#######################################
# 生成入口脚本内容
# Arguments:
#   1 - project_name: 项目名称
# Outputs:
#   入口脚本内容（写入 stdout）
#######################################
radp_cli_entry_content() {
  local project_name="$1"
  cat <<ENTRY_SCRIPT
#!/usr/bin/env bash
set -euo pipefail

# 检查框架是否已安装
if ! command -v radp-bf &>/dev/null; then
  echo "Error: radp-bash-framework not found. Please install it first." >&2
  echo "  See: https://github.com/xooooooooox/radp-bash-framework" >&2
  exit 1
fi

# 设置应用名称和根目录
export RADP_APP_NAME="$project_name"
export RADP_APP_ROOT="\$(radp-bf resolve-root "\${BASH_SOURCE[0]}")"
# shellcheck source=/dev/null
source "\$(radp-bf path launcher)" "\$@"
ENTRY_SCRIPT
}

#######################################
# 生成入口脚本（thin entry script）
# 所有 boilerplate 逻辑由 framework/launcher.sh 处理
#######################################
__radp_cli_scaffold_bin() {
  local project_name="$1"
  local target_dir="$2"

  radp_cli_entry_content "$project_name" >"$target_dir/bin/$project_name"
  chmod +x "$target_dir/bin/$project_name"
}

#######################################
# 生成示例命令
#######################################
__radp_cli_scaffold_commands() {
  local project_name="$1"
  local target_dir="$2"

  # version 命令
  cat >"$target_dir/src/main/shell/commands/version.sh" <<'VERSION_CMD'
#!/usr/bin/env bash
# @cmd
# @desc Show version information

# Application version
# Update this value when releasing a new version
declare -gr gr_app_version="v0.0.1"

cmd_version() {
    echo "__PROJECT_NAME__ $(radp_get_install_version "${gr_app_version}")"
}
VERSION_CMD
  sed -i.bak "s/__PROJECT_NAME__/$project_name/g" "$target_dir/src/main/shell/commands/version.sh"
  rm -f "$target_dir/src/main/shell/commands/version.sh.bak"

  # completion 命令
  cat >"$target_dir/src/main/shell/commands/completion.sh" <<'COMPLETION_CMD'
#!/usr/bin/env bash
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
  cat >"$target_dir/src/main/shell/commands/hello.sh" <<'HELLO_CMD'
#!/usr/bin/env bash
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
  cat >"$target_dir/src/main/shell/config/config.yaml" <<YAML_CONFIG
# $project_name configuration
# This file follows radp-bash-framework's configuration structure
# Priority: Environment variables (GX_*) > YAML values > defaults

radp:
  env: default

  # Framework settings override (optional)
  fw:
    banner-mode: off
    log:
      debug: false
      level: info
      console:
        enabled: false
      file:
        enabled: false

  # Application-specific extensions
  # Variables defined here will be available as gr_radp_extend_* in shell
  extend:
    ${project_var}:
      # Add your application-specific configuration here
      # Example: api_url: https://api.example.com
YAML_CONFIG

  # 生成环境特定配置示例
  cat >"$target_dir/src/main/shell/config/config-dev.yaml" <<YAML_DEV
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

  # 生成 IDE code completion 支持文件
  cat >"$target_dir/src/main/shell/config/_ide.sh" <<'IDE_HINTS'
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
}

#######################################
# 生成 README
#######################################
__radp_cli_scaffold_readme() {
  local project_name="$1"
  local target_dir="$2"

  cat >"$target_dir/README.md" <<README
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
$project_name completion bash > ~/.local/share/bash-completion/completions/$project_name
$project_name completion zsh > ~/.zfunc/_$project_name

# Verbose mode (show banner and info logs)
$project_name -v hello World
$project_name --verbose version

# Debug mode (show banner and debug logs)
$project_name --debug hello World
\`\`\`

## Global Options

| Option | Description |
|--------|-------------|
| \`-v\`, \`--verbose\` | Enable verbose output (banner + info logs) |
| \`--debug\` | Enable debug output (banner + debug logs) |
| \`-h\`, \`--help\` | Show help |
| \`--version\` | Show version |

By default, the CLI runs in quiet mode (no banner, only error logs).

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
      # Your custom config here
      # api_url: https://api.example.com
\`\`\`

### Version Management

The application version is defined in \`src/main/shell/commands/version.sh\`:

\`\`\`bash
declare -gr gr_app_version="v0.0.1"
\`\`\`

This is the single source of truth for version management. The CI workflows automatically update this value during releases.

### Accessing Config in Code

Variables from \`radp.extend.*\` are available as \`gr_radp_extend_*\`:

\`\`\`bash
# radp.extend.${project_name//-/_}.api_url -> gr_radp_extend_${project_name//-/_}_api_url
echo "\$gr_radp_extend_${project_name//-/_}_api_url"
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
# @option -u, --uppercase Convert output to uppercase
# @example mycommand foo
# @example mycommand --uppercase bar

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

  cat >"$target_dir/.gitignore" <<'GITIGNORE'
# Auto-generated files
src/main/shell/config/config.sh
src/main/shell/config/_idecomp.sh
.radp-cli/checksums/

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
# 生成 CHANGELOG
#######################################
__radp_cli_scaffold_changelog() {
  local project_name="$1"
  local target_dir="$2"

  cat >"$target_dir/CHANGELOG.md" <<'CHANGELOG'
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

  cat >"$target_dir/install.sh" <<'INSTALL_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="xooooooooox"
REPO_NAME="__PROJECT_NAME__"
tmp_dir=""

# Installation mode: auto, manual, <pkm>
# auto: detect and use package manager if available, fallback to manual
# manual: always use manual installation (download from GitHub)
# homebrew/dnf/yum/apt/zypper: force specific package manager
__PROJECT_UPPER___INSTALL_MODE="${__PROJECT_UPPER___INSTALL_MODE:-auto}"

log() { printf "%s\n" "$*"; }
err() { printf "__PROJECT_NAME__ install: %s\n" "$*" >&2; }
die() { err "$@"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# ============================================================================
# Package Manager Detection and Installation
# ============================================================================

detect_os() {
  local os=""
  if [[ "${OSTYPE:-}" == darwin* ]]; then
    os="macos"
  elif [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    case "${ID:-}" in
      fedora|centos|rhel|rocky|almalinux|ol) os="rhel" ;;
      debian|ubuntu|linuxmint|pop) os="debian" ;;
      opensuse*|sles) os="suse" ;;
      *) os="linux" ;;
    esac
  else
    os="unknown"
  fi
  echo "${os}"
}

detect_package_manager() {
  local os; os="$(detect_os)"
  if have brew; then echo "homebrew"; return 0; fi
  case "${os}" in
    rhel)
      if have dnf; then echo "dnf"; return 0
      elif have yum; then echo "yum"; return 0; fi ;;
    debian)
      if have apt-get; then echo "apt"; return 0; fi ;;
    suse)
      if have zypper; then echo "zypper"; return 0; fi ;;
  esac
  echo ""
}

check_repo_configured() {
  local pkm="$1"
  case "${pkm}" in
    homebrew) brew tap 2>/dev/null | grep -q "xooooooooox/radp" ;;
    dnf|yum)
      [[ -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:xooooooooox:radp.repo ]] || \
      [[ -f /etc/yum.repos.d/radp.repo ]] ;;
    apt) [[ -f /etc/apt/sources.list.d/home:xooooooooox:radp.list ]] ;;
    zypper) zypper repos 2>/dev/null | grep -q "xooooooooox" ;;
    *) return 1 ;;
  esac
}

setup_repo() {
  local pkm="$1"
  log "Setting up repository for ${pkm}..."
  case "${pkm}" in
    homebrew)
      log "Adding Homebrew tap..."
      brew tap xooooooooox/radp ;;
    dnf)
      log "Enabling COPR repository..."
      sudo dnf install -y dnf-plugins-core >/dev/null 2>&1 || true
      sudo dnf copr enable -y xooooooooox/radp ;;
    yum)
      log "Enabling COPR repository..."
      sudo yum install -y yum-plugin-copr >/dev/null 2>&1 || true
      sudo yum copr enable -y xooooooooox/radp ;;
    apt)
      log "Adding OBS repository..."
      local distro=""
      if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        case "${ID:-}" in
          ubuntu) distro="xUbuntu_${VERSION_ID}" ;;
          debian) distro="Debian_${VERSION_ID}" ;;
          *) err "Unsupported distribution for apt: ${ID:-unknown}"; return 1 ;;
        esac
      fi
      [[ -z "${distro}" ]] && { err "Cannot detect distribution for OBS repository"; return 1; }
      echo "deb http://download.opensuse.org/repositories/home:/xooooooooox:/radp/${distro}/ /" | \
        sudo tee /etc/apt/sources.list.d/home:xooooooooox:radp.list >/dev/null
      curl -fsSL "https://download.opensuse.org/repositories/home:xooooooooox:radp/${distro}/Release.key" | \
        gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_xooooooooox_radp.gpg >/dev/null
      sudo apt-get update >/dev/null ;;
    zypper)
      log "Adding OBS repository..."
      local distro=""
      if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        case "${ID:-}" in
          opensuse-tumbleweed) distro="openSUSE_Tumbleweed" ;;
          opensuse-leap) distro="openSUSE_Leap_${VERSION_ID}" ;;
          sles) distro="SLE_${VERSION_ID}" ;;
          *) err "Unsupported distribution for zypper: ${ID:-unknown}"; return 1 ;;
        esac
      fi
      [[ -z "${distro}" ]] && { err "Cannot detect distribution for OBS repository"; return 1; }
      sudo zypper addrepo -f "https://download.opensuse.org/repositories/home:/xooooooooox:/radp/${distro}/home:xooooooooox:radp.repo" ;;
    *) err "Unknown package manager: ${pkm}"; return 1 ;;
  esac
}

refresh_cache() {
  local pkm="$1"
  log "Refreshing package cache..."
  case "${pkm}" in
    homebrew) brew update >/dev/null 2>&1 || true ;;
    dnf) sudo dnf clean all >/dev/null 2>&1 || true; sudo dnf makecache >/dev/null 2>&1 || true ;;
    yum) sudo yum clean all >/dev/null 2>&1 || true; sudo yum makecache >/dev/null 2>&1 || true ;;
    apt) sudo apt-get update >/dev/null 2>&1 || true ;;
    zypper) sudo zypper refresh >/dev/null 2>&1 || true ;;
  esac
}

install_via_pkm() {
  local pkm="$1"
  refresh_cache "${pkm}"
  log "Installing ${REPO_NAME} via ${pkm}..."
  case "${pkm}" in
    homebrew) brew install __PROJECT_NAME__ ;;
    dnf) sudo dnf install -y __PROJECT_NAME__ ;;
    yum) sudo yum install -y __PROJECT_NAME__ ;;
    apt) sudo apt-get install -y __PROJECT_NAME__ ;;
    zypper) sudo zypper install -y __PROJECT_NAME__ ;;
    *) err "Unknown package manager: ${pkm}"; return 1 ;;
  esac
}

# ============================================================================
# Manual Installation
# ============================================================================

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

install_manual() {
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

  # Remove IDE support files (development only, not needed at runtime)
  find "${install_dir}/src" -name "_ide*.sh" -delete 2>/dev/null || true

  chmod 0755 "${install_dir}/bin/__PROJECT_NAME__"
  find "${install_dir}/src" -type f -name "*.sh" -exec chmod 0755 {} \;

  # Write install method marker for uninstall
  echo "manual" >"${install_dir}/.install-method"
  echo "${ref}" >"${install_dir}/.install-ref"

  # Write actual installed version for banner display
  local installed_version
  if [[ "${ref}" =~ ^v[0-9]+\.[0-9]+ ]]; then
    # ref is a version tag, use it directly
    installed_version="${ref}"
  else
    # ref is branch/SHA, append to base version from source
    local base_version
    base_version=$(sed -n 's/^declare -gr gr_app_version="\([^"]*\)".*/\1/p' \
      "${install_dir}/src/main/shell/commands/version.sh" 2>/dev/null)
    base_version="${base_version:-v0.0.0}"
    installed_version="${base_version}+${ref}"
  fi
  echo "${installed_version}" >"${install_dir}/.install-version"

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

# ============================================================================
# Main
# ============================================================================

main() {
  local mode="${__PROJECT_UPPER___INSTALL_MODE}"
  local pkm=""

  case "${mode}" in
    manual)
      log "Using manual installation (__PROJECT_UPPER___INSTALL_MODE=manual)"
      install_manual
      return 0 ;;
    homebrew|dnf|yum|apt|zypper)
      pkm="${mode}"
      if ! have "${pkm}" && [[ "${pkm}" != "homebrew" ]]; then
        die "Package manager '${pkm}' not found"
      fi
      if [[ "${pkm}" == "homebrew" ]] && ! have brew; then
        die "Homebrew not found"
      fi ;;
    auto|"")
      pkm="$(detect_package_manager)"
      if [[ -z "${pkm}" ]]; then
        log "No supported package manager detected, using manual installation"
        install_manual
        return 0
      fi
      log "Detected package manager: ${pkm}" ;;
    *)
      die "Unknown install mode: ${mode}. Use: auto, manual, homebrew, dnf, yum, apt, zypper" ;;
  esac

  if ! check_repo_configured "${pkm}"; then
    log "Repository not configured for ${pkm}"
    setup_repo "${pkm}" || {
      err "Failed to setup repository, falling back to manual installation"
      install_manual
      return 0
    }
  fi

  install_via_pkm "${pkm}" || {
    err "Package manager installation failed, falling back to manual installation"
    install_manual
    return 0
  }

  log "Successfully installed ${REPO_NAME} via ${pkm}"
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
  sed -i.bak "s/__PROJECT_VAR__/${project_var}/g" "$target_dir/install.sh"
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
  cat >"$target_dir/packaging/copr/${project_name}.spec" <<SPEC
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
# Remove development mode marker (only used in source tree)
rm -f %{buildroot}%{_libdir}/${project_name}/src/main/shell/config/_ide.sh
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
  cat >"$target_dir/packaging/obs/debian/control" <<CONTROL
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
  cat >"$target_dir/packaging/obs/debian/rules" <<'RULES'
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
	# Remove development mode marker (only used in source tree)
	rm -f debian/__PROJECT_NAME__/usr/lib/__PROJECT_NAME__/src/main/shell/config/_ide.sh
	chmod 0755 debian/__PROJECT_NAME__/usr/lib/__PROJECT_NAME__/bin/__PROJECT_NAME__
	find debian/__PROJECT_NAME__/usr/lib/__PROJECT_NAME__/src -type f -name '*.sh' -exec chmod 0755 {} \;
RULES
  sed -i.bak "s/__PROJECT_NAME__/${project_name}/g" "$target_dir/packaging/obs/debian/rules"
  rm -f "$target_dir/packaging/obs/debian/rules.bak"

  # Debian install
  cat >"$target_dir/packaging/obs/debian/${project_name}.install" <<INSTALL
bin usr/lib/${project_name}
src usr/lib/${project_name}
INSTALL

  # Debian links
  cat >"$target_dir/packaging/obs/debian/${project_name}.links" <<LINKS
usr/lib/${project_name}/bin/${project_name} usr/bin/${project_name}
LINKS

  # Debian changelog
  cat >"$target_dir/packaging/obs/debian/changelog" <<CHANGELOG
${project_name} (0.0.0-1) unstable; urgency=medium

  * Placeholder entry. The CI workflow rewrites this changelog.

 -- xooooooooox <xozoz.sos@gmail.com>  Thu, 01 Jan 1970 00:00:00 +0000
CHANGELOG

  # Debian copyright
  cat >"$target_dir/packaging/obs/debian/copyright" <<COPYRIGHT
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
  echo "3.0 (quilt)" >"$target_dir/packaging/obs/debian/source/format"

  # Homebrew formula template
  # Convert project name to Ruby class name (capitalize first letter, remove hyphens and capitalize following letters)
  local class_name
  class_name="$(echo "${project_name}" | sed -r 's/(^|-)([a-z])/\U\2/g')"

  cat >"$target_dir/packaging/homebrew/${project_name}.rb" <<FORMULA
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

    # Remove IDE support files (development only, not needed at runtime)
    Dir.glob(libexec/"src/**/_ide*.sh").each { |f| rm f }

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

  mkdir -p "$target_dir/.github/workflows"

  radp_workflow_content_release_prep "$project_name" "$project_var" >"$target_dir/.github/workflows/release-prep.yml"
  radp_workflow_content_create_tag "$project_name" "$project_var" >"$target_dir/.github/workflows/create-version-tag.yml"
  radp_workflow_content_update_spec "$project_name" "$project_var" >"$target_dir/.github/workflows/update-spec-version.yml"
  radp_workflow_content_build_copr "$project_name" "$project_var" >"$target_dir/.github/workflows/build-copr-package.yml"
  radp_workflow_content_build_obs "$project_name" "$project_var" >"$target_dir/.github/workflows/build-obs-package.yml"
  radp_workflow_content_homebrew "$project_name" "$project_var" >"$target_dir/.github/workflows/update-homebrew-tap.yml"
  radp_workflow_content_attach_packages "$project_name" "$project_var" >"$target_dir/.github/workflows/attach-release-packages.yml"
  radp_workflow_content_cleanup_branches "$project_name" "$project_var" >"$target_dir/.github/workflows/cleanup-branches.yml"
}

#######################################
# Workflow content generators (reusable by scaffold and upgrade)
# 这些函数输出 workflow 内容到 stdout，可被 scaffold 和 upgrade 复用
#######################################

radp_workflow_content_release_prep() {
  local project_name="$1"
  local project_var="$2"

  cat <<'WORKFLOW'
name: Release prep

on:
  workflow_dispatch:
    inputs:
      bump_type:
        description: "Release version bump type"
        type: choice
        options:
          - patch
          - minor
          - major
          - manual
        default: patch
        required: true
      version:
        description: "Manual release version tag (vX.Y.Z) when bump_type=manual"
        required: false

permissions:
  contents: write
  pull-requests: write

jobs:
  release-prep:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    defaults:
      run:
        shell: bash
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Fetch tags
        run: git fetch --tags --force

      - name: Resolve version
        id: version
        run: |
          set -euo pipefail
          bump_type="${{ inputs.bump_type }}"
          manual_version="${{ inputs.version }}"
          latest_tag="$(git tag --list 'v*' --sort=-v:refname | head -n 1)"

          # Handle initial release (no existing tags)
          if [[ -z "${latest_tag}" ]]; then
            echo "No tags found; using v0.0.0 as base for initial release."
            latest_tag="v0.0.0"
          fi

          if [[ ! "${latest_tag}" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
            echo "Latest tag '${latest_tag}' does not match vX.Y.Z" >&2
            exit 1
          fi
          major="${BASH_REMATCH[1]}"
          minor="${BASH_REMATCH[2]}"
          patch="${BASH_REMATCH[3]}"

          case "${bump_type}" in
            patch)
              version="v${major}.${minor}.$((patch + 1))"
              ;;
            minor)
              version="v${major}.$((minor + 1)).0"
              ;;
            major)
              version="v$((major + 1)).0.0"
              ;;
            manual)
              if [[ -z "${manual_version}" ]]; then
                echo "Manual bump_type requires inputs.version." >&2
                exit 1
              fi
              version="${manual_version}"
              ;;
            *)
              echo "Unsupported bump_type: ${bump_type}" >&2
              exit 1
              ;;
          esac

          if [[ ! "${version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Version '${version}' does not match vX.Y.Z" >&2
            exit 1
          fi

          echo "version=${version}" >> "$GITHUB_OUTPUT"
          echo "latest=${latest_tag}" >> "$GITHUB_OUTPUT"

      - name: Create release branch
        id: branch
        run: |
          set -euo pipefail
          version="${{ steps.version.outputs.version }}"
          if git rev-parse "${version}" >/dev/null 2>&1; then
            echo "Tag ${version} already exists. Aborting release prep." >&2
            exit 1
          fi
          branch="workflow/${version}"
          reused=false
          if git ls-remote --exit-code --heads origin "${branch}" >/dev/null 2>&1; then
            git checkout -b "${branch}" "origin/${branch}"
            echo "Reusing existing branch ${branch}"
            reused=true
          else
            git checkout -b "${branch}"
          fi
          echo "branch=${branch}" >> "$GITHUB_OUTPUT"
          echo "reused=${reused}" >> "$GITHUB_OUTPUT"

      - name: Update versions and changelog
        env:
          VERSION: ${{ steps.version.outputs.version }}
WORKFLOW

  # 这部分需要插入 project_name
  cat <<WORKFLOW
        run: |
          set -euo pipefail
          version="\${VERSION}"
          version_no_prefix="\${version#v}"

          # Update version.sh
          sed -i "s/^declare -gr gr_app_version=.*/declare -gr gr_app_version=\"\${version}\"/" src/main/shell/commands/version.sh

          # Update spec files
          sed -i "s/^Version:.*/Version:        \${version_no_prefix}/" packaging/copr/${project_name}.spec
          sed -i "s/^Version:.*/Version:        \${version_no_prefix}/" packaging/obs/${project_name}.spec

          # Update CHANGELOG.md
          python3 - <<'PY'
          import os
          import re
          import subprocess
          from pathlib import Path

          version = os.environ["VERSION"].strip()
          if not re.match(r"^v[0-9]+\.[0-9]+\.[0-9]+\$", version):
            raise SystemExit(f"Invalid version: {version}")
          version_no_prefix = version[1:]

          def git(*args: str) -> str:
            return subprocess.check_output(["git", *args], text=True, errors="replace").strip()

          def try_git(*args: str) -> str:
            try:
              return git(*args)
            except subprocess.CalledProcessError:
              return ""

          changelog_path = Path("CHANGELOG.md")
          if not changelog_path.exists():
            raise SystemExit("CHANGELOG.md not found.")
          changelog_text = changelog_path.read_text()
          header_pattern = re.compile(rf"^##\\s+v?{re.escape(version_no_prefix)}(\\s|\$)")

          last_tag = try_git("describe", "--tags", "--abbrev=0", "--match", "v*")
          log_range = f"{last_tag}..HEAD" if last_tag else "HEAD"
          log_output = try_git("log", "--no-merges", "--pretty=%h %s", log_range)
          base_types = ["feat", "fix", "chore"]
          standard_types = base_types + ["docs", "refactor", "perf", "test", "build", "ci"]
          other_key = "other"
          entries_by_type = {t: [] for t in standard_types}
          entries_by_type[other_key] = []
          type_pattern = re.compile(r"^(?P<type>[A-Za-z][A-Za-z0-9_-]*)(\\([^\\)]*\\))?:\\s+(?P<desc>.+)\$")

          for line in log_output.splitlines():
            line = line.strip()
            if not line:
              continue
            parts = line.split(" ", 1)
            sha = parts[0]
            subject = parts[1] if len(parts) > 1 else ""
            subject_ascii = subject.encode("ascii", "ignore").decode("ascii").strip()
            if not subject_ascii:
              subject_ascii = "<non-ascii subject>"
            match = type_pattern.match(subject_ascii)
            if match:
              commit_type = match.group("type").lower()
              desc = match.group("desc").strip() or subject_ascii
            else:
              commit_type = other_key
              desc = subject_ascii
            if commit_type not in entries_by_type:
              commit_type = other_key
            entries_by_type[commit_type].append(desc)

          default_header = f"## {version}"
          include_types = [t for t in standard_types if entries_by_type[t]]
          if entries_by_type[other_key]:
            include_types.append(other_key)

          def build_section_lines(header_line: str, leading_blank: bool) -> list[str]:
            section = []
            if leading_blank:
              section.append("")
            section.append(header_line)
            section.append("")
            if not include_types:
              section.append("- TODO: no commits found; add summary manually.")
              return section
            for commit_type in include_types:
              section.append(f"### {commit_type}")
              section.append("")
              for entry in entries_by_type.get(commit_type, []):
                section.append(f"- {entry}")
              section.append("")
            while section and section[-1] == "":
              section.pop()
            return section

          lines = changelog_text.splitlines()
          start = None
          for idx, line in enumerate(lines):
            if header_pattern.match(line):
              start = idx
              break
          if start is not None:
            end = len(lines)
            for idx in range(start + 1, len(lines)):
              if lines[idx].startswith("## "):
                end = idx
                break
            existing_section = "\\n".join(lines[start:end])
            todo_markers = (
              "TODO: curate and rewrite this list before release.",
              "TODO: no commits found; add summary manually.",
            )
            if any(marker in existing_section for marker in todo_markers):
              header_line = lines[start]
              new_lines = build_section_lines(header_line, leading_blank=False)
              lines = lines[:start] + new_lines + lines[end:]
            else:
              print("CHANGELOG entry exists and appears edited; leaving it unchanged.")
          else:
            insert_at = 1 if lines and lines[0].strip() == "# CHANGELOG" else 0
            new_lines = build_section_lines(default_header, leading_blank=True)
            lines = lines[:insert_at] + new_lines + lines[insert_at:]

          changelog_path.write_text("\\n".join(lines).rstrip() + "\\n")

          print(f"Updated version to {version} (last tag: {last_tag or 'none'})")
          PY
WORKFLOW

  cat <<WORKFLOW

      - name: Install radp-bash-framework
        run: |
          set -euo pipefail
          curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | \\
            RADP_BF_INSTALL_MODE=manual bash
          echo "\$HOME/.local/bin" >> "\$GITHUB_PATH"

      - name: Regenerate completion scripts
        run: |
          set -euo pipefail
          export PATH="\$HOME/.local/bin:\$PATH"
          ./bin/${project_name} completion bash > completions/${project_name}.bash
          ./bin/${project_name} completion zsh > completions/${project_name}.zsh
          echo "Completion scripts regenerated"

      - name: Commit changes
        id: commit
        run: |
          set -euo pipefail
          if git diff --quiet; then
            if [[ "\${{ steps.branch.outputs.reused }}" == "true" ]]; then
              echo "No changes to commit; branch already exists."
              exit 0
            fi
            echo "No changes to commit; aborting release prep." >&2
            exit 1
          fi
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add \\
            src/main/shell/commands/version.sh \\
            packaging/copr/${project_name}.spec \\
            packaging/obs/${project_name}.spec \\
            completions/${project_name}.bash \\
            completions/${project_name}.zsh \\
            CHANGELOG.md
          git commit -m "Release prep \${{ steps.version.outputs.version }}"

      - name: Push branch
        run: |
          set -euo pipefail
          git push --set-upstream origin "\${{ steps.branch.outputs.branch }}"

      - name: Create pull request
        env:
          GH_TOKEN: \${{ secrets.RELEASE_PREP_TOKEN || github.token }}
          HAS_RELEASE_PREP_TOKEN: \${{ secrets.RELEASE_PREP_TOKEN != '' }}
        run: |
          set -euo pipefail
          version="\${{ steps.version.outputs.version }}"
          branch="\${{ steps.branch.outputs.branch }}"
          title="Release \${version}"
          body_file="\$(mktemp)"
          cat > "\${body_file}" <<EOF
          Release prep for \${version}.

          - Update gr_app_version in version.sh
          - Sync spec versions
          - Add changelog entry (please review and edit)

          When this PR is merged, create-version-tag will run automatically to validate and tag the release.
          EOF
          if gh pr create --base main --head "\${branch}" --title "\${title}" --body-file "\${body_file}"; then
            exit 0
          fi
          if gh pr view --head "\${branch}" >/dev/null 2>&1; then
            echo "PR already exists for \${branch}."
            exit 0
          fi
          if [[ "\${HAS_RELEASE_PREP_TOKEN}" == "true" ]]; then
            echo "PR creation failed even with RELEASE_PREP_TOKEN; check token scopes and repo settings." >&2
            exit 1
          fi
          echo "PR creation not permitted for GitHub Actions token." >&2
          echo "Enable 'Allow GitHub Actions to create and approve pull requests' or create the PR manually:" >&2
          echo "  gh pr create --base main --head \"\${branch}\" --title \"\${title}\" --body-file \"\${body_file}\"" >&2
WORKFLOW
}

radp_workflow_content_create_tag() {
  local project_name="$1"
  local project_var="$2"

  cat <<'WORKFLOW'
name: Create version tag

on:
  workflow_dispatch:
  pull_request:
    types:
      - closed
    branches:
      - main

permissions:
  contents: write

jobs:
  create-version-tag:
    if: >-
      ${{
        (github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main') ||
        (github.event_name == 'pull_request' &&
          github.event.pull_request.merged == true &&
          startsWith(github.event.pull_request.head.ref, 'workflow/v'))
      }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout (manual)
        if: github.event_name == 'workflow_dispatch'
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          ref: main

      - name: Checkout (auto)
        if: github.event_name == 'pull_request'
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          ref: ${{ github.event.pull_request.merge_commit_sha }}

      - name: Fetch tags
        run: git fetch --tags --force

      - name: Resolve context
        id: ctx
        run: |
          set -euo pipefail
          if [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then
            head_ref="${{ github.event.pull_request.head.ref }}"
            expected_version="${head_ref#workflow/}"
            echo "expected_version=${expected_version}" >> "$GITHUB_OUTPUT"
            echo "tag_target=${{ github.event.pull_request.merge_commit_sha }}" >> "$GITHUB_OUTPUT"
          else
            echo "expected_version=" >> "$GITHUB_OUTPUT"
            echo "tag_target=HEAD" >> "$GITHUB_OUTPUT"
          fi

      - name: Read version
        id: version
        run: |
          set -euo pipefail
          version_file="src/main/shell/commands/version.sh"
          version=$(grep -oP 'declare -gr gr_app_version="\K[^"]+' "$version_file")
          if [[ -z "$version" ]]; then
            echo "Failed to read gr_app_version from $version_file" >&2
            exit 1
          fi
          if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Version '$version' does not match vx.y.z" >&2
            exit 1
          fi
          expected_version="${{ steps.ctx.outputs.expected_version }}"
          if [[ -n "$expected_version" && "$version" != "$expected_version" ]]; then
            echo "Version mismatch: expected ${expected_version}, got ${version}" >&2
            exit 1
          fi
          echo "version=$version" >> "$GITHUB_OUTPUT"

      - name: Validate changelog
        run: |
          set -euo pipefail
          version="${{ steps.version.outputs.version }}"
          version_no_prefix="${version#v}"
          changelog_file="CHANGELOG.md"
          if [[ ! -f "$changelog_file" ]]; then
            echo "CHANGELOG.md not found; update changelog before tagging." >&2
            exit 1
          fi
          if ! grep -Eq "^##[[:space:]]+v?${version_no_prefix}([[:space:]]|$)" "$changelog_file"; then
            echo "CHANGELOG.md missing entry for ${version}; update changelog before tagging." >&2
            exit 1
          fi
WORKFLOW

  cat <<WORKFLOW

      - name: Validate spec versions
        run: |
          set -euo pipefail
          version="\${{ steps.version.outputs.version }}"
          version_no_prefix="\${version#v}"
          copr_spec_file="packaging/copr/${project_name}.spec"
          obs_spec_file="packaging/obs/${project_name}.spec"
          for spec_file in "\$copr_spec_file" "\$obs_spec_file"; do
            if [[ ! -f "\$spec_file" ]]; then
              echo "Spec file not found: \$spec_file" >&2
              exit 1
            fi
            spec_version="\$(awk -F'[: ]+' '/^Version:/{print \$2; exit}' "\$spec_file")"
            if [[ -z "\$spec_version" ]]; then
              echo "Failed to read Version from \$spec_file" >&2
              exit 1
            fi
            if [[ "\$spec_version" != "\$version_no_prefix" ]]; then
              echo "Spec version mismatch in \$spec_file: expected \$version_no_prefix, got \$spec_version" >&2
              echo "Run release-prep to sync spec versions before tagging." >&2
              exit 1
            fi
          done
WORKFLOW

  cat <<'WORKFLOW'

      - name: Create and push tag
        run: |
          set -euo pipefail
          version="${{ steps.version.outputs.version }}"
          tag_target="${{ steps.ctx.outputs.tag_target }}"
          if [[ -z "$tag_target" ]]; then
            tag_target="HEAD"
          fi
          if ! git cat-file -e "${tag_target}^{commit}" 2>/dev/null; then
            echo "Tag target not found: ${tag_target}" >&2
            exit 1
          fi
          if git rev-parse "$version" >/dev/null 2>&1; then
            echo "Tag $version already exists."
            exit 0
          fi
          git tag "$version" "$tag_target"
          git push origin "$version"
WORKFLOW
}

radp_workflow_content_update_spec() {
  local project_name="$1"
  local project_var="$2"

  cat <<'WORKFLOW'
name: Update spec version

on:
  workflow_run:
    workflows:
      - Create version tag
    types:
      - completed
  workflow_dispatch:

permissions:
  contents: write

jobs:
  update-spec-version:
    if: >-
      ${{
        github.event_name != 'workflow_run' ||
        (github.event.workflow_run.conclusion == 'success' &&
        (github.event.workflow_run.head_branch == 'main' ||
         startsWith(github.event.workflow_run.head_branch, 'workflow/')))
      }}
    runs-on: ubuntu-latest
    defaults:
      run:
        shell: bash
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          ref: main

      - name: Fetch tags
        run: git fetch --tags --force

      - name: Read and validate version
        id: version
        run: |
          set -euo pipefail
          version_file="src/main/shell/commands/version.sh"
          version=$(grep -oP 'declare -gr gr_app_version="\K[^"]+' "$version_file")
          if [[ -z "$version" ]]; then
            echo "Failed to read gr_app_version from $version_file" >&2
            exit 1
          fi
          if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Version '$version' does not match vx.y.z" >&2
            exit 1
          fi
          echo "version=$version" >> "$GITHUB_OUTPUT"
WORKFLOW

  cat <<WORKFLOW

      - name: Update spec version
        run: |
          set -euo pipefail
          version="\${{ steps.version.outputs.version }}"
          version_no_prefix="\${version#v}"
          copr_spec_file="packaging/copr/${project_name}.spec"
          if [[ -f "\$copr_spec_file" ]]; then
            sed -i "s/^Version:.*/Version:        \${version_no_prefix}/" "\$copr_spec_file"
          else
            echo "COPR spec file not found: \$copr_spec_file" >&2
            exit 1
          fi
          obs_spec_file="packaging/obs/${project_name}.spec"
          if [[ -f "\$obs_spec_file" ]]; then
            sed -i "s/^Version:.*/Version:        \${version_no_prefix}/" "\$obs_spec_file"
          else
            echo "OBS spec file not found: \$obs_spec_file" >&2
            exit 1
          fi
WORKFLOW

  cat <<WORKFLOW

      - name: Commit and push
        run: |
          set -euo pipefail
          if git diff --quiet; then
            echo "No changes to commit."
            exit 0
          fi
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add packaging/copr/${project_name}.spec
          if [[ -f "packaging/obs/${project_name}.spec" ]]; then
            git add packaging/obs/${project_name}.spec
          fi
          git commit -m "Update spec version to \${{ steps.version.outputs.version }}"
          git push
WORKFLOW
}

radp_workflow_content_build_copr() {
  local project_name="$1"
  local project_var="$2"

  cat <<'WORKFLOW'
name: Build COPR package

on:
  workflow_run:
    workflows:
      - Update spec version
    types:
      - completed

permissions:
  contents: read

jobs:
  build-copr-package:
    if: >-
      ${{
        github.event.workflow_run.conclusion == 'success' &&
        (github.event.workflow_run.head_branch == 'main' ||
         startsWith(github.event.workflow_run.head_branch, 'workflow/'))
      }}
    runs-on: ubuntu-latest
    env:
      COPR_LOGIN: ${{ secrets.COPR_LOGIN }}
      COPR_TOKEN: ${{ secrets.COPR_TOKEN }}
      COPR_USERNAME: ${{ secrets.COPR_USERNAME }}
      COPR_PROJECT: ${{ secrets.COPR_PROJECT }}
    steps:
      - name: Validate COPR secrets
        run: |
          set -euo pipefail
          for value in COPR_LOGIN COPR_TOKEN COPR_USERNAME COPR_PROJECT; do
            if [[ -z "${!value:-}" ]]; then
              echo "Missing required secret: ${value}" >&2
              exit 1
            fi
          done

      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Read version
        id: version
        run: |
          set -euo pipefail
          version_file="src/main/shell/commands/version.sh"
          version=$(grep -oP 'declare -gr gr_app_version="\K[^"]+' "$version_file")
          if [[ -z "$version" ]]; then
            echo "Failed to read gr_app_version from $version_file" >&2
            exit 1
          fi
          echo "version=${version}" >> "$GITHUB_OUTPUT"

      - name: Check tag exists
        id: tag
        run: |
          set -euo pipefail
          version="${{ steps.version.outputs.version }}"
          git fetch --tags --force
          if ! git rev-parse "$version" >/dev/null 2>&1; then
            echo "Tag $version does not exist. Skipping COPR build."
            echo "should_build=false" >> "$GITHUB_OUTPUT"
            exit 0
          fi
          tag_sha="$(git rev-parse "$version^{commit}")"
          run_sha="${{ github.event.workflow_run.head_sha }}"
          if [[ -n "${run_sha}" && "${tag_sha}" != "${run_sha}" ]]; then
            echo "Tag ${version} points to ${tag_sha}, workflow head is ${run_sha}; skipping COPR build."
            echo "should_build=false" >> "$GITHUB_OUTPUT"
            exit 0
          fi
          echo "should_build=true" >> "$GITHUB_OUTPUT"
          echo "tag_sha=${tag_sha}" >> "$GITHUB_OUTPUT"

      - name: Install copr-cli
        run: |
          set -euo pipefail
          python -m pip install --upgrade pip
          python -m pip install copr-cli

      - name: Configure copr-cli
        run: |
          set -euo pipefail
          mkdir -p ~/.config
          cat <<CONFIG > ~/.config/copr
          [copr-cli]
          login = ${COPR_LOGIN}
          token = ${COPR_TOKEN}
          username = ${COPR_USERNAME}
          copr_url = https://copr.fedorainfracloud.org
          encrypted = false

          [main]
          login = ${COPR_LOGIN}
          token = ${COPR_TOKEN}
          username = ${COPR_USERNAME}
          copr_url = https://copr.fedorainfracloud.org
          encrypted = false
          CONFIG
WORKFLOW

  cat <<WORKFLOW

      - name: Trigger COPR build
        if: steps.tag.outputs.should_build == 'true'
        run: |
          set -euo pipefail
          copr-cli buildscm "\${COPR_PROJECT}" \\
            --clone-url "\${GITHUB_SERVER_URL}/\${GITHUB_REPOSITORY}.git" \\
            --commit "\${{ steps.tag.outputs.tag_sha }}" \\
            --subdir "packaging/copr" \\
            --spec "${project_name}.spec"
WORKFLOW
}

radp_workflow_content_build_obs() {
  local project_name="$1"
  local project_var="$2"

  cat <<'WORKFLOW'
name: Build OBS package

on:
  workflow_run:
    workflows:
      - Update spec version
    types:
      - completed
  workflow_dispatch:

permissions:
  contents: read

jobs:
  build-obs-package:
    if: >-
      ${{
        github.event_name != 'workflow_run' ||
        (github.event.workflow_run.conclusion == 'success' &&
        (github.event.workflow_run.head_branch == 'main' ||
         startsWith(github.event.workflow_run.head_branch, 'workflow/')))
      }}
    runs-on: ubuntu-latest
    env:
      OBS_USERNAME: ${{ secrets.OBS_USERNAME }}
      OBS_PASSWORD: ${{ secrets.OBS_PASSWORD }}
      OBS_PROJECT: ${{ secrets.OBS_PROJECT }}
      OBS_PACKAGE: ${{ secrets.OBS_PACKAGE }}
      OBS_API_URL: ${{ secrets.OBS_API_URL }}
    steps:
      - name: Validate OBS secrets
        run: |
          set -euo pipefail
          for value in OBS_USERNAME OBS_PASSWORD OBS_PROJECT OBS_PACKAGE; do
            if [[ -z "${!value:-}" ]]; then
              echo "Missing required secret: ${value}" >&2
              exit 1
            fi
          done

          default_api_url="https://api.opensuse.org"
          if [[ -z "${OBS_API_URL:-}" ]]; then
            echo "OBS_API_URL not set; using default ${default_api_url}"
            echo "OBS_API_URL=${default_api_url}" >> "$GITHUB_ENV"
          else
            echo "OBS_API_URL=${OBS_API_URL}" >> "$GITHUB_ENV"
          fi

      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Fetch tags
        run: git fetch --tags --force

      - name: Read version
        id: version
        run: |
          set -euo pipefail
          version_file="src/main/shell/commands/version.sh"
          version=$(grep -oP 'declare -gr gr_app_version="\K[^"]+' "$version_file")
          if [[ -z "$version" ]]; then
            echo "Failed to read gr_app_version from $version_file" >&2
            exit 1
          fi
          if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Version '$version' does not match vx.y.z" >&2
            exit 1
          fi
          version_no_prefix="${version#v}"
          echo "version=${version}" >> "$GITHUB_OUTPUT"
          echo "version_no_prefix=${version_no_prefix}" >> "$GITHUB_OUTPUT"

      - name: Check tag exists
        id: tag
        run: |
          set -euo pipefail
          version="${{ steps.version.outputs.version }}"
          if ! git rev-parse "$version" >/dev/null 2>&1; then
            echo "Tag $version does not exist. Skipping OBS build."
            echo "should_build=false" >> "$GITHUB_OUTPUT"
            exit 0
          fi
          tag_sha="$(git rev-parse "$version^{commit}")"
          if [[ "${GITHUB_EVENT_NAME}" == "workflow_run" ]]; then
            run_sha="${{ github.event.workflow_run.head_sha }}"
            if [[ -n "${run_sha}" && "${tag_sha}" != "${run_sha}" ]]; then
              echo "Tag ${version} points to ${tag_sha}, workflow head is ${run_sha}; skipping OBS build."
              echo "should_build=false" >> "$GITHUB_OUTPUT"
              exit 0
            fi
          fi
          echo "should_build=true" >> "$GITHUB_OUTPUT"
          echo "tag_sha=${tag_sha}" >> "$GITHUB_OUTPUT"

      - name: Install osc
        if: steps.tag.outputs.should_build == 'true'
        run: |
          set -euo pipefail
          sudo apt-get update
          sudo apt-get install -y osc dpkg-dev debhelper

      - name: Configure osc
        if: steps.tag.outputs.should_build == 'true'
        run: |
          set -euo pipefail
          cat > ~/.oscrc <<EOF
          [general]
          apiurl = ${OBS_API_URL}

          [${OBS_API_URL}]
          user = ${OBS_USERNAME}
          pass = ${OBS_PASSWORD}
          EOF
          chmod 600 ~/.oscrc

      - name: Verify OBS authentication
        if: steps.tag.outputs.should_build == 'true'
        run: |
          set -euo pipefail
          osc -A "${OBS_API_URL}" ls "${OBS_PROJECT}" >/dev/null
          osc -A "${OBS_API_URL}" ls "${OBS_PROJECT}" "${OBS_PACKAGE}" >/dev/null
WORKFLOW

  cat <<WORKFLOW

      - name: Sync sources to OBS
        if: steps.tag.outputs.should_build == 'true'
        run: |
          set -euo pipefail
          version="\${{ steps.version.outputs.version }}"
          version_no_prefix="\${{ steps.version.outputs.version_no_prefix }}"
          checkout_root="\${{ runner.temp }}/obs"
          mkdir -p "\$checkout_root"
          pushd "\$checkout_root" >/dev/null

          osc -A "\${OBS_API_URL}" checkout "\${OBS_PROJECT}" "\${OBS_PACKAGE}"
          pkg_dir="\${OBS_PROJECT}/\${OBS_PACKAGE}"

          if [[ ! -d "\$pkg_dir/.osc" ]]; then
            echo "OBS checkout missing .osc directory at \$pkg_dir" >&2
            exit 1
          fi

          shopt -s dotglob
          for entry in "\$pkg_dir"/*; do
            [[ "\$(basename "\$entry")" == ".osc" ]] && continue
            rm -rf "\$entry"
          done
          shopt -u dotglob

          spec_source="\${GITHUB_WORKSPACE}/packaging/obs/${project_name}.spec"
          if [[ ! -f "\$spec_source" ]]; then
            echo "Spec file not found at \$spec_source" >&2
            exit 1
          fi
          cp "\$spec_source" "\$pkg_dir/"

          tarball_url="\${GITHUB_SERVER_URL}/\${GITHUB_REPOSITORY}/archive/refs/tags/\${version}.tar.gz"
          tarball_name="v\${version_no_prefix}.tar.gz"
          tarball_path="\$pkg_dir/\${tarball_name}"
          curl -L --fail --show-error -o "\$tarball_path" "\$tarball_url"
          if [[ ! -s "\$tarball_path" ]]; then
            echo "Failed to download tarball from \$tarball_url" >&2
            exit 1
          fi

          if [[ -d "\${GITHUB_WORKSPACE}/packaging/obs/debian" ]]; then
            cp -a "\${GITHUB_WORKSPACE}/packaging/obs/debian" "\$pkg_dir/debian"
          elif [[ -d "\${GITHUB_WORKSPACE}/packaging/deb/debian" ]]; then
            cp -a "\${GITHUB_WORKSPACE}/packaging/deb/debian" "\$pkg_dir/debian"
          else
            echo "No debian/ metadata found; skipping debian sync."
          fi

          if [[ -d "\$pkg_dir/debian" ]]; then
            deb_version="\${version_no_prefix}-1"
            changelog_path="\$pkg_dir/debian/changelog"
            {
              printf '${project_name} (%s) unstable; urgency=medium\\n\\n' "\$deb_version"
              printf '  * Automated OBS build for version %s\\n\\n' "\$deb_version"
              printf ' -- xooooooooox <xozoz.sos@gmail.com>  %s\\n' "\$(date -R)"
            } > "\$changelog_path"
            tmp_build="\$(mktemp -d)"
            orig_tarball="\$tmp_build/${project_name}_\${version_no_prefix}.orig.tar.gz"
            cp "\$tarball_path" "\$orig_tarball"
            tar --force-local -xzf "\$orig_tarball" -C "\$tmp_build"
            src_dir="\$tmp_build/${project_name}-\${version_no_prefix}"
            if [[ ! -d "\$src_dir" ]]; then
              echo "Expected source dir not found: \$src_dir" >&2
              exit 1
            fi
            cp -a "\$pkg_dir/debian" "\$src_dir/debian"
            (cd "\$src_dir" && dpkg-source -b .)
            find "\$tmp_build" -maxdepth 1 -type f -name '${project_name}_*.dsc' -print0 | xargs -0 -I {} mv {} "\$pkg_dir/"
            find "\$tmp_build" -maxdepth 1 -type f -name '${project_name}_*.debian.tar.*' -print0 | xargs -0 -I {} mv {} "\$pkg_dir/"
            cp "\$orig_tarball" "\$pkg_dir/"
            rm -rf "\$tmp_build"
          fi

          pushd "\$pkg_dir" >/dev/null
          osc addremove
          popd >/dev/null
          popd >/dev/null

      - name: Commit and trigger OBS build
        if: steps.tag.outputs.should_build == 'true'
        run: |
          set -euo pipefail
          pkg_dir="\${{ runner.temp }}/obs/\${OBS_PROJECT}/\${OBS_PACKAGE}"
          if [[ ! -d "\$pkg_dir/.osc" ]]; then
            echo "OBS package directory missing at \$pkg_dir" >&2
            exit 1
          fi

          pushd "\$pkg_dir" >/dev/null
          status_output="\$(osc status)"
          if [[ -z "\$status_output" ]]; then
            echo "No OBS changes to commit."
            exit 0
          fi

          osc commit -m "Update ${project_name} to \${{ steps.version.outputs.version }}"
          popd >/dev/null
WORKFLOW
}

radp_workflow_content_homebrew() {
  local project_name="$1"
  local project_var="$2"

  cat <<WORKFLOW
name: Update Homebrew Tap

on:
  push:
    tags:
      - "v*"
  workflow_run:
    workflows:
      - Create version tag
    types:
      - completed
  workflow_dispatch:

jobs:
  update-tap:
    if: >-
      \${{
        github.event_name != 'workflow_run' ||
        (github.event.workflow_run.conclusion == 'success' &&
        (github.event.workflow_run.head_branch == 'main' ||
         startsWith(github.event.workflow_run.head_branch, 'workflow/')))
      }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    env:
      TAP_REPO: xooooooooox/homebrew-radp
      TAP_FORMULA_PATH: Formula/${project_name}.rb
    steps:
      - name: Checkout source
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Fetch tags
        run: git fetch --tags --force

      - name: Checkout tap repository
        uses: actions/checkout@v4
        with:
          repository: \${{ env.TAP_REPO }}
          path: homebrew-radp
          token: \${{ secrets.HOMEBREW_TAP_TOKEN }}

      - name: Prepare release metadata
        id: release
        run: |
          set -euo pipefail
          if [[ "\${GITHUB_EVENT_NAME}" == "workflow_run" ]]; then
            head_sha="\${{ github.event.workflow_run.head_sha }}"
            head_branch="\${{ github.event.workflow_run.head_branch }}"
            if [[ "\${head_branch}" == workflow/v* ]]; then
              tag_name="\${head_branch#workflow/}"
            else
              tag_name="\$(git tag --points-at "\${head_sha}" --list 'v*' | sort -V | tail -n 1)"
            fi
          else
            tag_name="\${GITHUB_REF_NAME}"
          fi
          if [[ -z "\${tag_name}" ]]; then
            echo "Failed to resolve version tag for event \${GITHUB_EVENT_NAME}" >&2
            exit 1
          fi
          if ! git rev-parse "\${tag_name}" >/dev/null 2>&1; then
            echo "Resolved tag \${tag_name} does not exist in repository." >&2
            exit 1
          fi
          version_file="src/main/shell/commands/version.sh"
          version_from_tag="\$(git show "\${tag_name}:\${version_file}" | grep -oP 'declare -gr gr_app_version="\\K[^"]+')"
          if [[ -z "\${version_from_tag}" ]]; then
            echo "Failed to read gr_app_version from \${version_file} at \${tag_name}" >&2
            exit 1
          fi
          if [[ "\${version_from_tag}" != "\${tag_name}" ]]; then
            echo "Tag \${tag_name} does not match gr_app_version (\${version_from_tag})" >&2
            exit 1
          fi
          version="\${tag_name#v}"
          tarball_url="https://github.com/\${GITHUB_REPOSITORY}/archive/refs/tags/\${tag_name}.tar.gz"
          sha256="\$(curl -L "\${tarball_url}" | sha256sum | awk '{print \$1}')"
          echo "tag_name=\${tag_name}" >> "\$GITHUB_OUTPUT"
          echo "version=\${version}" >> "\$GITHUB_OUTPUT"
          echo "tarball_url=\${tarball_url}" >> "\$GITHUB_OUTPUT"
          echo "sha256=\${sha256}" >> "\$GITHUB_OUTPUT"

      - name: Create or update formula
        env:
          VERSION: \${{ steps.release.outputs.version }}
          TARBALL_URL: \${{ steps.release.outputs.tarball_url }}
          SHA256: \${{ steps.release.outputs.sha256 }}
        run: |
          set -euo pipefail
          template="packaging/homebrew/${project_name}.rb"
          formula="homebrew-radp/\${TAP_FORMULA_PATH}"
          mkdir -p "\$(dirname "\${formula}")"

          # Copy template and replace placeholders
          cp "\${template}" "\${formula}"
          sed -i "s|%%TARBALL_URL%%|\${TARBALL_URL}|g" "\${formula}"
          sed -i "s|%%SHA256%%|\${SHA256}|g" "\${formula}"
          sed -i "s|%%VERSION%%|\${VERSION}|g" "\${formula}"

      - name: Commit and push tap
        run: |
          set -euo pipefail
          cd homebrew-radp
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add "\${TAP_FORMULA_PATH}" || true
          if git diff --cached --quiet; then
            echo "No changes to commit."
            exit 0
          fi
          git commit -m "Update ${project_name} to \${{ steps.release.outputs.tag_name }}"
          git push
WORKFLOW
}

radp_workflow_content_attach_packages() {
  local project_name="$1"
  local project_var="$2"

  cat <<WORKFLOW
name: Attach release packages

on:
  workflow_run:
    workflows:
      - Build COPR package
      - Build OBS package
      - Update Homebrew Tap
    types:
      - completed
  workflow_dispatch:

permissions:
  contents: write

jobs:
  attach-release-packages:
    if: >-
      \${{
        github.event_name != 'workflow_run' ||
        (github.event.workflow_run.conclusion == 'success' &&
        (github.event.workflow_run.head_branch == 'main' ||
         startsWith(github.event.workflow_run.head_branch, 'workflow/')))
      }}
    runs-on: ubuntu-latest
    env:
      COPR_PROJECT: \${{ secrets.COPR_PROJECT }}
      OBS_PROJECT: \${{ secrets.OBS_PROJECT }}
      OBS_PACKAGE: \${{ secrets.OBS_PACKAGE }}
      OBS_API_URL: \${{ secrets.OBS_API_URL }}
      OBS_USERNAME: \${{ secrets.OBS_USERNAME }}
      OBS_PASSWORD: \${{ secrets.OBS_PASSWORD }}
      TAP_FORMULA_URL: https://raw.githubusercontent.com/xooooooooox/homebrew-radp/HEAD/Formula/${project_name}.rb
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Fetch tags
        run: git fetch --tags --force

      - name: Resolve tag and package
        id: release
        shell: bash
        run: |
          set -euo pipefail
          if [[ "\${GITHUB_EVENT_NAME}" == "workflow_run" ]]; then
            head_sha="\${{ github.event.workflow_run.head_sha }}"
            tag_name="\$(git tag --points-at "\${head_sha}" --list 'v*' | sort -V | tail -n 1)"
          else
            tag_name="\${GITHUB_REF_NAME}"
          fi

          version_file="src/main/shell/commands/version.sh"
          if [[ -z "\${tag_name}" && "\${GITHUB_EVENT_NAME}" == "workflow_run" ]]; then
            version_from_commit="\$(git show "\${head_sha}:\${version_file}" | grep -oP 'declare -gr gr_app_version="\\K[^"]+')"
            if [[ -z "\${version_from_commit}" ]]; then
              echo "Failed to read gr_app_version from \${version_file} at \${head_sha}" >&2
              exit 1
            fi
            tag_name="\${version_from_commit}"
          fi

          if [[ -z "\${tag_name}" ]]; then
            echo "Failed to resolve version tag for event \${GITHUB_EVENT_NAME}" >&2
            exit 1
          fi

          if [[ ! "\${tag_name}" =~ ^v[0-9]+\\.[0-9]+\\.[0-9]+\$ ]]; then
            echo "Resolved tag '\${tag_name}' does not match vx.y.z" >&2
            exit 1
          fi

          should_upload=true
          if ! git rev-parse "\${tag_name}" >/dev/null 2>&1; then
            echo "Tag \${tag_name} does not exist yet; skipping release attachment."
            should_upload=false
          elif [[ "\${GITHUB_EVENT_NAME}" == "workflow_run" ]]; then
            tag_sha="\$(git rev-parse "\${tag_name}^{commit}")"
            if [[ -n "\${head_sha}" && "\${tag_sha}" != "\${head_sha}" ]]; then
              echo "Tag \${tag_name} points to \${tag_sha}, workflow head is \${head_sha}; skipping release attachment."
              should_upload=false
            fi
          fi

          version="\${tag_name#v}"
          package_name="\$(awk -F': *' '/^Name:/{print \$2; exit}' packaging/copr/${project_name}.spec)"
          if [[ -z "\${package_name}" ]]; then
            echo "Failed to read package name from packaging/copr/${project_name}.spec" >&2
            exit 1
          fi

          echo "tag_name=\${tag_name}" >> "\$GITHUB_OUTPUT"
          echo "version=\${version}" >> "\$GITHUB_OUTPUT"
          echo "package_name=\${package_name}" >> "\$GITHUB_OUTPUT"
          echo "should_upload=\${should_upload}" >> "\$GITHUB_OUTPUT"

      - name: Download COPR packages
        if: >-
          \${{
            steps.release.outputs.should_upload == 'true' &&
            (github.event_name != 'workflow_run' ||
            github.event.workflow_run.name == 'Build COPR package')
          }}
        env:
          VERSION: \${{ steps.release.outputs.version }}
          PACKAGE_NAME: \${{ steps.release.outputs.package_name }}
        shell: bash
        run: |
          set -euo pipefail
          if [[ -z "\${COPR_PROJECT:-}" ]]; then
            echo "COPR_PROJECT not set; skipping COPR download."
            exit 0
          fi
          python - <<'PY'
          import json
          import os
          import re
          import sys
          import urllib.parse
          import urllib.request
          from pathlib import Path

          copr_project = os.environ["COPR_PROJECT"].strip()
          version = os.environ["VERSION"].strip()
          package_name = os.environ["PACKAGE_NAME"].strip()

          if "/" not in copr_project:
            print(f"Invalid COPR_PROJECT: {copr_project}", file=sys.stderr)
            sys.exit(0)

          owner, project = copr_project.split("/", 1)

          def request(url: str) -> urllib.request.Request:
            return urllib.request.Request(
              url,
              headers={
                "User-Agent": "${project_name}-release-bot/1.0",
                "Accept": "application/json,text/html;q=0.9,*/*;q=0.8",
              },
            )

          def fetch(url: str) -> tuple[bytes, int, str]:
            req = request(url)
            with urllib.request.urlopen(req) as resp:
              data = resp.read()
              status = getattr(resp, "status", None) or resp.getcode()
              content_type = resp.headers.get("Content-Type", "")
              return data, int(status), content_type

          def api_json(url: str) -> dict:
            data, status, content_type = fetch(url)
            if not data:
              raise ValueError(f"Empty response from {url}")
            try:
              return json.loads(data.decode("utf-8"))
            except json.JSONDecodeError as exc:
              snippet = data[:200].decode("utf-8", "ignore")
              raise ValueError(f"Invalid JSON from {url}: {snippet}") from exc

          def download(url: str, dest: Path) -> None:
            dest.parent.mkdir(parents=True, exist_ok=True)
            data, status, content_type = fetch(url)
            if status >= 400:
              raise ValueError(f"Download failed: {url} status={status}")
            with open(dest, "wb") as fh:
              fh.write(data)

          params = {
            "ownername": owner,
            "projectname": project,
            "limit": "50",
          }
          builds_url = "https://copr.fedorainfracloud.org/api_3/build/list?" + urllib.parse.urlencode(params)
          try:
            build_data = api_json(builds_url)
            builds = build_data.get("builds") or build_data.get("items") or []
          except Exception as exc:
            print(f"Failed to read COPR build list: {exc}", file=sys.stderr)
            builds = []

          candidates = []
          for build in builds:
            if build.get("state") != "succeeded":
              continue
            source_pkg = build.get("source_package") or {}
            source_name = source_pkg.get("name") or build.get("package_name")
            if source_name and source_name != package_name:
              continue
            src_version = source_pkg.get("version")
            if src_version and not (src_version == version or src_version.startswith(version + "-")):
              continue
            candidates.append(build)

          if not candidates:
            print(f"No COPR builds found for {package_name} {version}", file=sys.stderr)
            sys.exit(0)

          selected = max(candidates, key=lambda b: b.get("id", 0))
          build_id = selected.get("id")
          repo_url = (selected.get("repo_url") or "").rstrip("/")
          chroots = selected.get("chroots") or []

          dest_dir = Path("release-assets/copr")
          downloaded = set()

          def fetch_listing(url: str) -> str:
            data, status, content_type = fetch(url)
            return data.decode("utf-8", "ignore")

          def download_rpms_from_listing(base_url: str) -> int:
            try:
              listing = fetch_listing(base_url)
            except Exception:
              return 0
            hrefs = re.findall(r'href=["\']([^"\']+)["\']', listing)
            count = 0
            for href in hrefs:
              if href in ("../", "./"):
                continue
              href_clean = href.split("?", 1)[0].split("#", 1)[0]
              if not href_clean.endswith(".rpm"):
                continue
              filename = href_clean.split("/")[-1]
              if filename.endswith(".src.rpm"):
                continue
              if package_name not in filename or version not in filename:
                continue
              if filename in downloaded:
                continue
              full_url = urllib.parse.urljoin(base_url, href_clean)
              try:
                download(full_url, dest_dir / f"copr-{filename}")
              except Exception:
                continue
              downloaded.add(filename)
              count += 1
            return count

          if build_id and package_name and chroots:
            build_dir_candidates = [f"{int(build_id):08d}-{package_name}", f"{build_id}-{package_name}"]
            for chroot in chroots:
              chroot_url = f"{repo_url}/{chroot}/"
              for build_dir in build_dir_candidates:
                direct_url = f"{chroot_url}{build_dir}/"
                download_rpms_from_listing(direct_url)

          if downloaded:
            print(f"Downloaded {len(downloaded)} COPR RPMs", file=sys.stderr)
          else:
            print(f"No COPR RPMs downloaded for {package_name} {version}", file=sys.stderr)
          PY

      - name: Download OBS packages
        if: >-
          \${{
            steps.release.outputs.should_upload == 'true' &&
            (github.event_name != 'workflow_run' ||
            github.event.workflow_run.name == 'Build OBS package')
          }}
        env:
          VERSION: \${{ steps.release.outputs.version }}
          PACKAGE_NAME: \${{ steps.release.outputs.package_name }}
        shell: bash
        run: |
          set -euo pipefail
          if [[ -z "\${OBS_PROJECT:-}" ]]; then
            echo "OBS_PROJECT not set; skipping OBS download."
            exit 0
          fi
          python - <<'PY'
          import os
          import sys
          import base64
          import urllib.error
          import urllib.parse
          import urllib.request
          import xml.etree.ElementTree as ET
          from pathlib import Path
          import time

          project = os.environ["OBS_PROJECT"].strip()
          package = (os.environ.get("OBS_PACKAGE") or os.environ.get("PACKAGE_NAME") or "").strip()
          version = os.environ["VERSION"].strip()
          api_url = (os.environ.get("OBS_API_URL") or "https://api.opensuse.org").rstrip("/")
          username = (os.environ.get("OBS_USERNAME") or "").strip()
          password = (os.environ.get("OBS_PASSWORD") or "").strip()
          max_wait_seconds = int(os.environ.get("OBS_WAIT_SECONDS", "1200"))
          poll_interval = int(os.environ.get("OBS_POLL_INTERVAL", "30"))

          if not package:
            print("OBS package name is missing", file=sys.stderr)
            sys.exit(0)

          def quote(segment: str) -> str:
            return urllib.parse.quote(segment, safe="")

          def request(url: str) -> urllib.request.Request:
            req = urllib.request.Request(
              url,
              headers={
                "User-Agent": "${project_name}-release-bot/1.0",
                "Accept": "application/xml,text/xml;q=0.9,*/*;q=0.8",
              },
            )
            if username and password:
              token = base64.b64encode(f"{username}:{password}".encode("utf-8")).decode("ascii")
              req.add_header("Authorization", f"Basic {token}")
            return req

          def fetch(url: str) -> tuple[bytes, int, str]:
            req = request(url)
            try:
              with urllib.request.urlopen(req) as resp:
                data = resp.read()
                status = getattr(resp, "status", None) or resp.getcode()
                content_type = resp.headers.get("Content-Type", "")
                return data, int(status), content_type
            except urllib.error.HTTPError as exc:
              raise ValueError(f"HTTP {exc.code} for {url}") from exc

          def fetch_xml(url: str) -> ET.Element:
            data, status, content_type = fetch(url)
            if not data:
              raise ValueError(f"Empty response from {url}")
            return ET.fromstring(data)

          def download(url: str, dest: Path) -> None:
            dest.parent.mkdir(parents=True, exist_ok=True)
            with urllib.request.urlopen(request(url)) as resp, open(dest, "wb") as fh:
              fh.write(resp.read())

          project_q = quote(project)
          package_q = quote(package)
          result_url = f"{api_url}/build/{project_q}/_result?package={package_q}"

          dest_dir = Path("release-assets/obs")
          downloaded: set[str] = set()
          deadline = time.time() + max_wait_seconds

          while True:
            try:
              root = fetch_xml(result_url)
            except Exception as exc:
              print(f"Failed to query OBS results: {exc}", file=sys.stderr)
              break

            candidates = []
            for result in root.findall(".//result"):
              repo = result.get("repository")
              arch = result.get("arch")
              if not repo or not arch:
                continue
              status_nodes = result.findall(f"./status[@package='{package}']")
              if not status_nodes:
                continue
              code = (status_nodes[0].get("code") or "").lower()
              if code in {"succeeded", "published", "finished", "unchanged"}:
                candidates.append((repo, arch))

            for repo, arch in candidates:
              repo_q = quote(repo)
              arch_q = quote(arch)
              base_url = f"{api_url}/build/{project_q}/{repo_q}/{arch_q}/{package_q}"
              try:
                binaries_root = fetch_xml(base_url)
              except Exception:
                continue
              for binary in binaries_root.findall(".//binary"):
                filename = binary.get("filename")
                if not filename:
                  continue
                lower = filename.lower()
                if lower.endswith((".src.rpm", ".nosrc.rpm", ".ddeb")):
                  continue
                if not (lower.endswith(".rpm") or lower.endswith(".deb")):
                  continue
                if version not in filename:
                  continue
                if filename in downloaded:
                  continue
                file_url = f"{base_url}/{urllib.parse.quote(filename, safe='')}"
                try:
                  download(file_url, dest_dir / f"obs-{filename}")
                except Exception:
                  continue
                downloaded.add(filename)

            if downloaded:
              break

            if time.time() + poll_interval > deadline:
              break

            print(f"OBS binaries not ready; retrying in {poll_interval}s", file=sys.stderr)
            time.sleep(poll_interval)

          if downloaded:
            print(f"Downloaded {len(downloaded)} OBS binaries")
          else:
            print(f"No OBS binaries downloaded for {package} {version}", file=sys.stderr)
          PY

      - name: Download Homebrew formula
        if: >-
          \${{
            steps.release.outputs.should_upload == 'true' &&
            (github.event_name != 'workflow_run' ||
            github.event.workflow_run.name == 'Update Homebrew Tap')
          }}
        shell: bash
        run: |
          set -euo pipefail
          if [[ -z "\${TAP_FORMULA_URL:-}" ]]; then
            echo "TAP_FORMULA_URL not set; skipping formula download."
            exit 0
          fi
          mkdir -p release-assets/homebrew
          curl -L --fail --show-error -o release-assets/homebrew/homebrew-${project_name}.rb "\${TAP_FORMULA_URL}"

      - name: Upload assets to release
        if: steps.release.outputs.should_upload == 'true'
        env:
          GH_TOKEN: \${{ github.token }}
        shell: bash
        run: |
          set -euo pipefail
          tag="\${{ steps.release.outputs.tag_name }}"
          if ! gh release view "\$tag" >/dev/null 2>&1; then
            gh release create "\$tag" --title "\$tag" --generate-notes
          fi
          if [[ ! -d release-assets ]]; then
            echo "No assets directory to upload."
            exit 0
          fi
          mapfile -t assets < <(find release-assets -maxdepth 3 -type f | sort)
          if [[ \${#assets[@]} -eq 0 ]]; then
            echo "No assets to upload."
            exit 0
          fi
          gh release upload "\$tag" "\${assets[@]}" --clobber
WORKFLOW
}

radp_workflow_content_cleanup_branches() {
  local project_name="$1"
  local project_var="$2"

  cat <<'WORKFLOW'
name: Cleanup stale workflow branches

on:
  schedule:
    # Run every Sunday at 00:00 UTC
    - cron: "0 0 * * 0"
  workflow_dispatch:
    inputs:
      days_old:
        description: "Delete branches older than this many days"
        type: number
        default: 14
        required: false
      dry_run:
        description: "Dry run (list branches without deleting)"
        type: boolean
        default: false
        required: false

permissions:
  contents: write

jobs:
  cleanup-branches:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Delete stale workflow branches
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          set -euo pipefail

          # Configuration
          days_old="${{ inputs.days_old || 14 }}"
          dry_run="${{ inputs.dry_run || false }}"
          branch_pattern="workflow/v"

          echo "Configuration:"
          echo "  Days old threshold: ${days_old}"
          echo "  Dry run: ${dry_run}"
          echo "  Branch pattern: ${branch_pattern}*"
          echo ""

          # Calculate cutoff date
          cutoff_date=$(date -d "${days_old} days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
                        date -v-${days_old}d +%Y-%m-%dT%H:%M:%SZ)
          cutoff_epoch=$(date -d "${cutoff_date}" +%s 2>/dev/null || \
                         date -j -f "%Y-%m-%dT%H:%M:%SZ" "${cutoff_date}" +%s)

          echo "Cutoff date: ${cutoff_date}"
          echo ""

          # Get remote branches matching pattern
          git fetch --prune origin

          deleted_count=0
          skipped_count=0

          while IFS= read -r ref; do
            [[ -z "$ref" ]] && continue

            branch="${ref#refs/remotes/origin/}"
            [[ "$branch" != ${branch_pattern}* ]] && continue

            # Get last commit date for this branch
            last_commit_date=$(git log -1 --format=%cI "origin/${branch}" 2>/dev/null || echo "")
            if [[ -z "$last_commit_date" ]]; then
              echo "[SKIP] ${branch} (no commit date)"
              skipped_count=$((skipped_count + 1))
              continue
            fi

            # Convert to epoch for comparison
            commit_epoch=$(date -d "${last_commit_date}" +%s 2>/dev/null || \
                           date -j -f "%Y-%m-%dT%H:%M:%S%z" "${last_commit_date}" +%s 2>/dev/null || \
                           echo "0")

            if [[ "$commit_epoch" -lt "$cutoff_epoch" ]]; then
              if [[ "$dry_run" == "true" ]]; then
                echo "[DRY-RUN] Would delete: ${branch} (last commit: ${last_commit_date})"
              else
                echo "[DELETE] ${branch} (last commit: ${last_commit_date})"
                git push origin --delete "${branch}" || {
                  echo "  Failed to delete ${branch}"
                  skipped_count=$((skipped_count + 1))
                  continue
                }
              fi
              deleted_count=$((deleted_count + 1))
            else
              echo "[KEEP] ${branch} (last commit: ${last_commit_date})"
              skipped_count=$((skipped_count + 1))
            fi
          done < <(git for-each-ref --format='%(refname)' refs/remotes/origin/)

          echo ""
          echo "Summary:"
          if [[ "$dry_run" == "true" ]]; then
            echo "  Would delete: ${deleted_count} branches"
          else
            echo "  Deleted: ${deleted_count} branches"
          fi
          echo "  Kept/Skipped: ${skipped_count} branches"
WORKFLOW
}
