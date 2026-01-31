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

模块化 Bash 框架，用于构建 CLI 应用程序，提供结构化引导、配置管理和丰富的工具集。

## 特性

- **CLI 脚手架** - 使用 `radp-bf new myapp` 生成完整的 CLI 项目
- **CLI 脚手架升级** - 使用 `radp-bf upgrade` 升级现有 CLI 项目到最新脚手架
- **注解驱动命令** - 使用注释元数据定义命令（`@cmd`、`@arg`、`@option`）
- **自动发现** - 从目录结构自动发现命令，支持嵌套子命令
- **Shell 补全** - 自动生成 Bash/Zsh 补全脚本
- **YAML 配置** - 分层配置系统，支持环境变量覆盖
- **内置全局选项** - 所有 CLI 应用自动支持 `--config`、`--verbose`、`--debug`
- **日志系统** - 结构化日志，支持多级别（debug/info/warn/error）
- **OS 检测** - 跨平台工具，检测发行版、架构、包管理器
- **路径工具** - 文件系统辅助函数、路径解析
- **IDE 代码补全** - BashSupport Pro 集成，支持框架函数和变量自动补全
- **开发/安装模式** - 基于 `_ide.sh` 标记自动检测配置路径

## 依赖

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

### 脚本安装 (curl)

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash
```

更多安装方式（RPM、OBS、手动安装、升级）请参阅 [安装指南](docs/installation.md)。

## 快速开始

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

当框架更新时，升级项目的脚手架文件：

```shell
radp-bf upgrade                     # 升级当前目录
radp-bf upgrade ./myapp --dry-run   # 预览变更
radp-bf upgrade --force             # 覆盖已修改的文件
radp-bf -v upgrade .                # 带详细输出的升级
```

升级命令通过 `.radp-cli/` 元数据目录跟踪变更并检测用户修改。

更多升级相关说明, 请参阅[如何升级已创建的项目](docs/installation.md#upgrade-cli-projects).

### 定义命令

使用注解定义命令：

```bash
# src/main/shell/commands/greet.sh

# @cmd
# @desc 问候某人
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

创建目录实现命令分组：

```
commands/
├── db/
│   ├── migrate.sh    # myapp db migrate
│   └── seed.sh       # myapp db seed
└── hello.sh          # myapp hello
```

### 配置

YAML 配置自动映射为 Shell 变量：

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

## radp-bf 命令行工具

`radp-bf` 命令行工具管理框架操作：

```shell
radp-bf new <name> [dir]      # 创建新 CLI 项目
radp-bf upgrade [dir] [opts]  # 升级现有项目脚手架
radp-bf path <name>           # 打印框架路径 (init|launcher|root)
radp-bf completion <shell>    # 生成 Shell 补全脚本 (bash|zsh)
radp-bf version               # 显示框架版本
```

**全局选项**（适用于任何命令）：

```shell
radp-bf -v upgrade .          # 详细输出（info 日志）
radp-bf --debug upgrade .     # 调试输出（debug 日志）
```

**radp-bf 的 Shell 补全：**

```shell
# Bash
radp-bf completion bash > ~/.local/share/bash-completion/completions/radp-bf

# Zsh
radp-bf completion zsh > ~/.zfunc/_radp-bf
```

## 文档

- [安装指南](docs/installation.md) - 所有安装方式和升级说明
- [CLI 开发指南](docs/cli-development.md) - 构建 CLI 应用完整指南
- [命令注解](docs/annotations.md) - `@cmd`、`@arg`、`@option`、`@example` 参考
- [配置系统](docs/configuration.md) - YAML 配置和环境变量
- [API 参考](docs/api.md) - 工具函数和 IDE 集成

## 工具函数 API

框架按领域提供工具函数：

| 领域            | 函数                                                   | 说明       |
|---------------|------------------------------------------------------|----------|
| `radp_log_*`  | `debug`, `info`, `warn`, `error`                     | 结构化日志    |
| `radp_os_*`   | `get_distro_id`, `get_distro_pm`, `is_pkg_installed` | 操作系统检测   |
| `radp_io_*`   | `get_path_abs`                                       | 文件系统工具   |
| `radp_exec_*` | `exec`, `exec_sudo`, `set_dry_run`, `is_dry_run`     | 干运行模式支持  |
| `radp_cli_*`  | `discover`, `dispatch`, `help`                       | CLI 基础设施 |

完整文档请参阅 [API 参考](docs/api.md)。

## 贡献

开发设置、测试和发布流程请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

[MIT](LICENSE)
