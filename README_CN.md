# radp-bash-framework

```
    ____  ___    ____  ____     ____  ___   _____ __  __
   / __ \/   |  / __ \/ __ \   / __ )/   | / ___// / / /
  / /_/ / /| | / / / / /_/ /  / __  / /| | \__ \/ /_/ /
 / _, _/ ___ |/ /_/ / ____/  / /_/ / ___ |___/ / __  /
/_/ |_/_/  |_/_____/_/      /_____/_/  |_/____/_/ /_/

```

[![GitHub Release](https://img.shields.io/github/v/release/xooooooooox/radp-bash-framework?label=Release)](https://github.com/xooooooooox/radp-bash-framework/releases)

模块化 Bash 框架，用于构建 CLI 应用程序，提供结构化引导、配置管理和丰富的工具集。

## 特性

- **CLI 脚手架** - 使用 `radp-bf new myapp` 生成完整的 CLI 项目
- **注解驱动命令** - 使用注释元数据定义命令（`@cmd`、`@arg`、`@option`）
- **自动发现** - 从目录结构自动发现命令，支持嵌套子命令
- **YAML 配置** - 分层配置系统，支持环境变量覆盖
- **日志系统** - 结构化日志，支持多级别

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

## 快速开始

```shell
# 创建项目
radp-bf new myapp
cd myapp
./bin/myapp --help

# 添加命令
# src/main/shell/commands/greet.sh
```

```bash
# @cmd
# @desc 问候某人
# @arg name!

cmd_greet() {
  echo "Hello, $1!"
}
```

```shell
$ ./bin/myapp greet World
Hello, World!
```

## 文档

详细文档请参阅 [docs/](docs/) 目录：

- [安装指南](docs/installation.md)
- [快速开始](docs/getting-started.md)
- [CLI 开发指南](docs/user-guide/cli-development.md)
- [配置系统](docs/configuration.md)
- [API 参考](docs/reference/api.md)

## 相关项目

- [radp-vagrant-framework](https://github.com/xooooooooox/radp-vagrant-framework) - YAML 驱动的 Vagrant 框架
- [homelabctl](https://github.com/xooooooooox/homelabctl) - Homelab 基础设施 CLI

## 贡献

请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

[MIT](LICENSE)
