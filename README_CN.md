# radp-bash-framework

```
    ____  ___    ____  ____     ____  ___   _____ __  __
   / __ \/   |  / __ \/ __ \   / __ )/   | / ___// / / /
  / /_/ / /| | / / / / /_/ /  / __  / /| | \__ \/ /_/ /
 / _, _/ ___ |/ /_/ / ____/  / /_/ / ___ |___/ / __  /
/_/ |_/_/  |_/_____/_/      /_____/_/  |_/____/_/ /_/

```

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
- **注解驱动命令** - 使用注释元数据定义命令（`@cmd`、`@arg`、`@option`）
- **自动发现** - 从目录结构自动发现命令，支持嵌套子命令
- **Shell 补全** - 自动生成 Bash/Zsh 补全脚本
- **YAML 配置** - 分层配置系统，支持环境变量覆盖
- **日志系统** - 结构化日志，支持多级别（debug/info/warn/error）
- **OS 检测** - 跨平台工具，检测发行版、架构、包管理器
- **路径工具** - 文件系统辅助函数、路径解析

## 依赖

- Bash 4.3+
- [yq](https://github.com/mikefarah/yq)（用于 YAML 解析，缺失时自动安装）

## 安装

### Homebrew (macOS/Linux)

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

### 脚本安装 (curl)

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash
```

从指定分支或标签安装：

```shell
bash install.sh --ref main
bash install.sh --ref v1.0.0-rc1
```

### RPM (Fedora/RHEL/CentOS)

```shell
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y radp-bash-framework
```

更多安装方式（OBS、手动安装、升级）请参阅 [安装指南](docs/installation.md)。

### 加载框架

安装后，在 shell 中加载框架：

```shell
source "$(radp-bf path init)"
```

将此命令添加到 `~/.bashrc` 可实现自动加载。

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
│       └── config.yaml       # 配置文件
└── install.sh                # 安装脚本
```

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

## 文档

- [安装指南](docs/installation.md) - 所有安装方式和升级说明
- [命令注解](docs/annotations.md) - `@cmd`、`@arg`、`@option`、`@example` 参考
- [配置系统](docs/configuration.md) - YAML 配置和环境变量
- [API 参考](docs/api.md) - 工具函数参考

## 工具函数 API

框架按领域提供工具函数：

| 领域           | 函数                                                   | 说明       |
|--------------|------------------------------------------------------|----------|
| `radp_log_*` | `debug`, `info`, `warn`, `error`                     | 结构化日志    |
| `radp_os_*`  | `get_distro_id`, `get_distro_pm`, `is_pkg_installed` | 操作系统检测   |
| `radp_io_*`  | `get_path_abs`                                       | 文件系统工具   |
| `radp_cli_*` | `discover`, `dispatch`, `help`                       | CLI 基础设施 |

完整文档请参阅 [API 参考](docs/api.md)。

## 贡献

开发设置、测试和发布流程请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

[MIT](LICENSE)
