# radp-bash-framework

```
    ____  ___    ____  ____     ____  ___   _____ __  __
   / __ \/   |  / __ \/ __ \   / __ )/   | / ___// / / /
  / /_/ / /| | / / / / /_/ /  / __  / /| | \__ \/ /_/ /
 / _, _/ ___ |/ /_/ / ____/  / /_/ / ___ |___/ / __  /
/_/ |_/_/  |_/_____/_/      /_____/_/  |_/____/_/ /_/

```

[![GitHub Release](https://img.shields.io/github/v/release/xooooooooox/radp-bash-framework?label=Release)](https://github.com/xooooooooox/radp-bash-framework/releases)
[![Copr build status](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/)
[![OBS package build status](https://build.opensuse.org/projects/home:xooooooooox:radp/packages/radp-bash-framework/badge.svg)](https://build.opensuse.org/package/show/home:xooooooooox:radp/radp-bash-framework)

[![CI: COPR](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/build-copr-package.yml?label=CI%3A%20COPR)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-copr-package.yml)
[![CI: OBS](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/build-obs-package.yml?label=CI%3A%20OBS)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-obs-package.yml)
[![CI: Homebrew](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/update-homebrew-tap.yml?label=Homebrew%20tap)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/update-homebrew-tap.yml)

[![COPR packages](https://img.shields.io/badge/COPR-packages-4b8bbe)](https://download.copr.fedorainfracloud.org/results/xooooooooox/radp/)
[![OBS packages](https://img.shields.io/badge/OBS-packages-4b8bbe)](https://software.opensuse.org//download.html?project=home%3Axooooooooox%3Aradp&package=radp-bash-framework)

模块化 Bash 框架，兼具两大目标：**将工程化实践引入 Shell 脚本**（结构化引导、配置管理、日志、工具集、代码规范）和**快速构建 CLI
应用**（脚手架、注解驱动命令、自动发现、Shell 补全）。

## 特性

### Bash 工程化

- **两阶段预检 + 引导** - POSIX 阶段一验证 Bash 版本；Bash 阶段二检查依赖（`gnu-getopt`、`yq`）；引导阶段串联所有组件
- **YAML 配置** - 分层配置系统（框架默认值 → 用户配置 → 环境变量），自动映射为变量
- **日志系统** - 多级别结构化日志（`debug`/`info`/`warn`/`error`），可配置输出格式
- **工具集** - 7 个域、40+ 文件、60+ 公开函数：OS 检测、dry-run 执行、文件 I/O、网络、YAML 解析等
- **IDE 支持** - BashSupport Pro 集成，支持框架函数和变量的代码补全

### 代码规范

- **变量命名** - 作用域前缀：`gr_*`（全局只读）、`gw_*`（全局可写）、`gwxa_*`（全局数组）
- **函数命名** - `radp_*`（公开 API）、`radp_nr_*`（nameref 引用）、`__fw_*`（框架内部）
- **POSIX vs Bash 分层** - 入口脚本和阶段一预检使用 POSIX；引导及之后使用 Bash 特性
- **ShellCheck 集成** - 代码库中保留 ShellCheck 注解
- **代码风格** - 2 空格缩进、变量加引号、Bash 语境下使用 `[[ ]]` 而非 `[ ]`

### CLI 开发

- **CLI 脚手架** - 使用 `radp-bf new myapp` 生成完整的 CLI 项目
- **脚手架升级** - 使用 `radp-bf upgrade` 将现有项目升级至最新脚手架
- **注解驱动命令** - 使用注释元数据定义命令（`@cmd`、`@arg`、`@option`）
- **自动发现** - 从目录结构自动发现命令，支持嵌套子命令
- **Shell 补全** - 自动生成 Bash/Zsh 补全脚本
- **内置全局选项** - 所有 CLI 应用自动拥有 `--config`、`--verbose`、`--debug`
- **开发/安装模式** - 基于 `_ide.sh` 标记文件自动检测配置路径

## 系统要求

- Bash 4.3+
- GNU getopt（用于 CLI 参数解析，缺失时自动安装）
  - Linux：包含在 `util-linux` 中
  - macOS：`brew install gnu-getopt`
- [yq](https://github.com/mikefarah/yq)（用于 YAML 解析，缺失时自动安装）

## 安装

### Homebrew (macOS)

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

### 脚本安装

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash
```

### 便携式二进制文件（单文件）

下载即用，无需安装：

```shell
# 标准版 (~100KB) - macOS Apple Silicon
curl -fsSL -o radp-bf \
  https://github.com/xooooooooox/radp-bash-framework/releases/latest/download/radp-bf-portable-darwin-arm64
chmod +x radp-bf && sudo mv radp-bf /usr/local/bin/

# 完整版 (~20MB，零依赖) - macOS Apple Silicon
curl -fsSL -o radp-bf \
  https://github.com/xooooooooox/radp-bash-framework/releases/latest/download/radp-bf-portable-full-darwin-arm64
chmod +x radp-bf && sudo mv radp-bf /usr/local/bin/
```

可用平台：`linux-amd64`、`linux-arm64`、`darwin-amd64`、`darwin-arm64`

更多安装方式（RPM、OBS、便携式、手动安装、升级）请参阅[安装指南](docs/installation.md)。

## 快速开始

### 作为框架使用

在任意 Bash 脚本中 source `init.sh` 即可使用框架的工程化能力：

```bash
#!/usr/bin/env bash
source "$(radp-bf path init)"

# 日志
radp_log_info "Starting task..."
radp_log_debug "Debug details here"

# OS 检测
distro=$(radp_os_get_distro_id)
arch=$(radp_os_get_distro_arch)
radp_log_info "Running on $distro ($arch)"

# YAML 配置（来自 config.yaml）
echo "API URL: $gr_radp_extend_myapp_api_url"

# Dry-run 模式
radp_set_dry_run "${DRY_RUN:-}"
radp_exec "Install package" apt-get install -y nginx
```

### 创建 CLI 项目

```shell
radp-bf new myapp
cd myapp
./bin/myapp --help
```

生成的项目结构：

```
myapp/
├── bin/myapp                 # 入口脚本
├── src/main/shell/
│   ├── commands/             # 命令实现
│   │   ├── hello.sh          # myapp hello
│   │   └── version.sh        # myapp version
│   └── config/
│       ├── config.yaml       # 配置文件
│       └── _ide.sh           # IDE 支持 & 开发模式标记
├── .radp-cli/                # 脚手架元数据（用于升级）
└── install.sh                # 安装脚本
```

### 升级现有项目

当框架更新后，升级项目的脚手架文件：

```shell
radp-bf upgrade # 升级当前目录
radp-bf upgrade ./myapp --dry-run # 预览变更
radp-bf upgrade --force # 覆盖已修改的文件
radp-bf -v upgrade . # 带详细输出的升级
```

升级命令通过 `.radp-cli/` 元数据目录跟踪变更，并检测用户修改。

更多选项请参阅[升级 CLI 项目](docs/installation.md#upgrade-cli-projects)。

### 定义命令

命令使用注解元数据：

```bash
# src/main/shell/commands/greet.sh

# @cmd
# @desc Greet someone
# @arg name!              必填参数
# @option -l, --loud      大声问候

cmd_greet() {
  local name="$1"
  local msg="Hello, $name!"

  if [[ "${opt_loud:-}" == "true" ]]; then
    echo "${msg^^}"
  else
    echo "$msg"
  fi
}
```

```shell
$ myapp greet World
Hello, World!

$ myapp greet --loud World
HELLO, WORLD!
```

### 子命令

通过创建目录来组织命令组：

```
commands/
├── db/
│   ├── migrate.sh    # myapp db migrate
│   └── seed.sh       # myapp db seed
└── hello.sh          # myapp hello
```

### 配置

YAML 配置自动映射为变量：

```yaml
# config/config.yaml
radp:
  extend:
    myapp:
      api_url: https://api.example.com
```

在代码中访问：

```bash
echo "$gr_radp_extend_myapp_api_url" # https://api.example.com
```

通过环境变量覆盖：

```shell
GX_RADP_EXTEND_MYAPP_API_URL=http://localhost:8080 myapp hello
```

### Shell 补全

```shell
# Bash
myapp completion bash >~/.local/share/bash-completion/completions/myapp

# Zsh
myapp completion zsh >~/.zfunc/_myapp
```

## 代码规范

框架建立了一套命名约定，使 Shell 项目保持一致性和可读性。

### 变量命名

| 前缀       | 作用域  | 示例                        |
|----------|------|---------------------------|
| `gr_*`   | 全局只读 | `gr_fw_root_path`         |
| `gw_*`   | 全局可写 | `gw_fw_run_initialized`   |
| `gwxa_*` | 全局数组 | `gwxa_fw_sourced_scripts` |

CLI 命令还使用 `opt_*`、`args_*` 和 `gopt_*` 变量（由注解自动生成）。

### 函数命名

| 模式            | 含义               | 示例                         |
|---------------|------------------|----------------------------|
| `radp_*`      | 公开 API           | `radp_log_info`            |
| `radp_nr_*`   | Nameref（调用者传变量名） | `radp_nr_arr_merge_unique` |
| `radp_*_is_*` | 布尔谓词（返回 0/1）     | `radp_os_is_pkg_installed` |
| `__fw_*`      | 框架内部（非用户接口）      | `__fw_bootstrap`           |

完整规范请参阅[代码风格指南](docs/developer/code-style.md)。

## radp-bf CLI

`radp-bf` 命令行工具用于管理框架操作：

```shell
radp-bf new <name >[dir] # 创建新 CLI 项目
radp-bf upgrade [dir] [opts] # 升级现有项目脚手架
radp-bf path <name> # 打印框架路径（init|launcher|root）
radp-bf completion <shell> # 生成 Shell 补全（bash|zsh）
radp-bf upgrade # 升级至最新版本
radp-bf version # 显示框架版本
```

**全局选项**（适用于所有命令）：

```shell
radp-bf -v upgrade . # 详细输出（info 日志）
radp-bf --debug upgrade . # 调试输出（debug 日志）
```

**radp-bf 的 Shell 补全：**

```shell
# Bash
radp-bf completion bash >~/.local/share/bash-completion/completions/radp-bf

# Zsh
radp-bf completion zsh >~/.zfunc/_radp-bf
```

## 文档

- [安装指南](docs/installation.md) - 所有安装方式和升级说明
- [快速开始](docs/getting-started.md) - 创建第一个 CLI 项目
- [CLI 开发指南](docs/user-guide/cli-development.md) - 构建 CLI 应用的完整指南
- [命令注解](docs/user-guide/annotations.md) - `@cmd`、`@arg`、`@option`、`@example` 参考
- [配置系统](docs/configuration.md) - YAML 配置系统和环境变量
- [API 参考](docs/reference/api.md) - 工具集函数和 IDE 集成
- [代码风格指南](docs/developer/code-style.md) - 变量/函数命名、POSIX vs Bash 分层、ShellCheck

## 工具集 API

框架提供 60+ 公开函数，按域组织：

| 域             | 主要函数                                                                                                                                   | 说明                |
|---------------|----------------------------------------------------------------------------------------------------------------------------------------|-------------------|
| `radp_log_*`  | `debug`, `info`, `warn`, `error`                                                                                                       | 结构化日志             |
| `radp_os_*`   | `get_distro_id`, `get_distro_pm`, `get_distro_arch`, `is_pkg_installed`, `install_pkgs`, `disable_swap`, `sysctl_configure_persistent` | OS 检测、包管理、系统配置    |
| `radp_io_*`   | `get_path_abs`, `download`, `extract`, `mktemp_dir`, `yaml_get_value`, `prompt_confirm`                                                | 文件 I/O、下载、YAML 解析 |
| `radp_exec_*` | `exec`, `exec_sudo`, `set_dry_run`, `is_dry_run`, `retry`, `wait_until`                                                                | 带 dry-run 支持的命令执行 |
| `radp_net_*`  | `github_download_asset`, `github_latest_release`                                                                                       | 网络和 GitHub API 工具 |
| `radp_cli_*`  | `discover`, `dispatch`, `help`, `parse_args`, `scaffold_new`, `upgrade`                                                                | CLI 基础设施          |
| `radp_core_*` | `get_fw_install_version`, `nr_arr_merge_unique`                                                                                        | 核心工具和数组操作         |
| `radp_ide_*`  | `ide_init`, `ide_add_commands_dir`                                                                                                     | IDE 代码补全支持        |

完整文档请参阅 [API 参考](docs/reference/api.md)。

## 相关项目

- [radp-vagrant-framework](https://github.com/xooooooooox/radp-vagrant-framework) - YAML 驱动的 Vagrant 框架
- [homelabctl](https://github.com/xooooooooox/homelabctl) - Homelab 基础设施 CLI

## 贡献

请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解开发设置、测试和发版流程。

## 许可证

[MIT](LICENSE)
