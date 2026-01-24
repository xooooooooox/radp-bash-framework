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

## 快速开始

### 安装

安装后建议在当前 shell 加载入口：

```shell
source "$(radp-bf --print-run)"
```

如需每次启动自动加载，可将上述命令写入 `~/.bashrc` 或其它 shell 配置。

#### 脚本安装（curl / wget / fetch）

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash
```

或：

```shell
wget -qO- https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash
fetch -qo- https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash
```

可选变量：

```shell
RADP_BF_VERSION=vX.Y.Z \
RADP_BF_REF=main \
RADP_BF_INSTALL_DIR="$HOME/.local/lib/radp-bash-framework" \
RADP_BF_BIN_DIR="$HOME/.local/bin" \
RADP_BF_ALLOW_ANY_DIR=1 \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh)"
```

`RADP_BF_REF` 支持分支、标签或 commit，并且优先级高于 `RADP_BF_VERSION`。
如果自定义安装目录不以 `radp-bash-framework` 结尾，请同时设置 `RADP_BF_ALLOW_ANY_DIR=1`。
默认路径：`~/.local/lib/radp-bash-framework` 和 `~/.local/bin`。

重复执行脚本可完成升级。

#### Homebrew

详情见: <https://github.com/xooooooooox/homebrew-radp/blob/main/Formula/radp-bash-framework.rb>.

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

#### RPM (Fedora/RHEL/CentOS via COPR)

```shell
# dnf
sudo dnf install -y dnf-plugins-core
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y radp-bash-framework

# yum
sudo yum install -y epel-release
sudo yum install -y yum-plugin-copr
sudo yum copr enable -y xooooooooox/radp
sudo yum install -y radp-bash-framework
```

#### OBS 仓库 (dnf / yum / apt)

OBS 提供多发行版的 RPM/DEB 构建。替换 `<DISTRO>` 为目标发行版路径（例如 `CentOS_7`、`openSUSE_Tumbleweed`、`xUbuntu_24.04`）。

```shell
# CentOS/RHEL (yum)
sudo yum-config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo yum install -y radp-bash-framework

# Debian/Ubuntu (apt)
echo 'deb http://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/ /' | sudo tee /etc/apt/sources.list.d/home:xooooooooox:radp.list
curl -fsSL https://download.opensuse.org/repositories/home:xooooooooox:radp/<DISTRO>/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_xooooooooox_radp.gpg > /dev/null
sudo apt update
sudo apt install radp-bash-framework

# Fedora/RHEL/CentOS (dnf)
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo dnf install -y radp-bash-framework
```

#### 手动安装（Release 制品 / 源码）

每次发布都会附带可直接安装的包：<https://github.com/xooooooooox/radp-bash-framework/releases/latest>

下载 `.rpm` 或 `.deb` 制品（文件名前缀通常为 `obs-` 或 `copr-`）后安装：

```shell
# RPM (Fedora/RHEL/CentOS)
sudo rpm -Uvh ./obs-radp-bash-framework-<version>-<release>.noarch.rpm
# or
sudo dnf install ./obs-radp-bash-framework-<version>-<release>.noarch.rpm

# DEB (Debian/Ubuntu)
sudo dpkg -i ./obs-radp-bash-framework_<version>-<release>_all.deb
sudo apt-get -f install
```

或直接从源码运行：

```shell
source /path/to/framework/run.sh
```

### 升级

#### Homebrew

```shell
brew upgrade radp-bash-framework
```

#### RPM (Fedora/RHEL/CentOS via COPR)

```shell
sudo dnf clean metadata
sudo dnf upgrade --refresh -y radp-bash-framework
sudo yum clean expire-cache
sudo yum update -y radp-bash-framework
```

#### OBS 仓库 (dnf / yum / apt)

```shell
# CentOS/RHEL (yum)
sudo yum update -y radp-bash-framework

# Debian/Ubuntu(apt)
sudo apt update
sudo apt install -y radp-bash-framework

# Fedora/RHEL/CentOS (dnf)
sudo dnf upgrade -y radp-bash-framework
```

#### 手动升级（Release 制品）

从最新 Release 下载新的 `.rpm`/`.deb` 包后安装即可升级：

```shell
# RPM
sudo rpm -Uvh ./obs-radp-bash-framework-<version>-<release>.noarch.rpm

# DEB
sudo dpkg -i ./obs-radp-bash-framework_<version>-<release>_all.deb
sudo apt-get -f install
```

## 框架内置工具包

### CLI 工具包

radp-bash-framework 内置 CLI 工具包，支持基于注解的命令定义、自动帮助生成、Shell 补全等功能。

#### 创建新项目

```shell
radp-bf new myapp
cd myapp
./bin/myapp --help
```

生成的项目结构如下：

```
myapp/
├── bin/
│   └── myapp                    # CLI 入口脚本
├── src/main/shell/
│   ├── commands/                # 命令实现
│   │   ├── hello.sh             # myapp hello
│   │   ├── version.sh           # myapp version
│   │   └── completion.sh        # myapp completion
│   ├── config/
│   │   ├── config.yaml          # 基础配置
│   │   └── config-dev.yaml      # 开发环境配置覆盖
│   ├── libs/                    # 项目私有库
│   └── vars/
│       └── constants.sh         # 版本常量 (gr_myapp_version)
├── packaging/
│   ├── copr/myapp.spec          # COPR RPM spec
│   └── obs/
│       ├── myapp.spec           # OBS RPM spec
│       └── debian/              # Debian 打包文件
├── .github/workflows/           # CI/CD 工作流
├── install.sh                   # 通用安装脚本
├── CHANGELOG.md
├── README.md
└── .gitignore
```

#### 命令注解

使用注释元数据定义命令：

```bash
# @cmd
# @desc 命令描述
# @arg name!         必填参数
# @arg items~        可变参数（多个值）
# @option -v, --verbose          布尔标志
# @option -e, --env <name>       带值选项
# @option -c, --config <file>    带值选项
# @example hello World
# @example hello --verbose World

cmd_hello() {
    local name="${1:-World}"

    if [[ "${opt_verbose:-}" == "true" ]]; then
        echo "Verbose mode enabled"
    fi

    echo "Hello, $name!"
}
```

#### 子命令

创建目录实现子命令分组：

```
src/main/shell/commands/
├── db/
│   ├── migrate.sh    # myapp db migrate
│   └── seed.sh       # myapp db seed
└── hello.sh          # myapp hello
```

#### 配置管理

框架使用 YAML 配置系统，自动映射为 Shell 变量：

```yaml
# src/main/shell/config/config.yaml
radp:
  env: default

  fw:
    banner-mode: on
    log:
      debug: false
      level: info
    user:
      config:
        automap: true

  extend:
    myapp:
      version: v1.0.0
      api_url: https://api.example.com
```

`radp.extend.*` 下的变量会自动映射为 `gr_radp_extend_*`：

```bash
# radp.extend.myapp.version -> gr_radp_extend_myapp_version
echo "$gr_radp_extend_myapp_version"  # v1.0.0
```

通过环境变量覆盖配置：

```shell
GX_RADP_FW_LOG_DEBUG=true myapp hello
```

#### Shell 补全

生成补全脚本：

```shell
# Bash
myapp completion bash > ~/.bash_completion.d/myapp

# Zsh
myapp completion zsh > ~/.zfunc/_myapp
```


## CI

### 发布流程

1. 触发 `release-prep` 选择 `bump_type`（patch/minor/major/manual，默认 patch）。手动模式需输入 `vX.Y.Z`。该流程会生成发布分支 `workflow/vX.Y.Z` 并创建 PR：更新 `gr_fw_version`、同步 spec、插入 changelog 条目。
2. 在 PR 中补充/整理 changelog 后合并到 `main`。
3. PR 合并后会自动触发 `create-version-tag`（或手动触发）校验版本/changelog/spec 并创建/推送标签。
4. 标签相关工作流执行：
    - `update-homebrew-tap` 更新 Homebrew 的 formula。
5. `update-spec-version` 在 `create-version-tag` 成功完成后执行（必要时可手动触发）。
6. `build-copr-package` 会在 `update-spec-version` 成功完成后触发 COPR SCM 构建（仅当标签指向本次 workflow 运行提交）。
7. `build-obs-package` 会同步源码到 OBS 并触发构建（仅当标签指向本次 workflow 运行提交）。
8. `attach-release-packages` 会从 COPR/OBS 拉取构建产物及 Homebrew formula，并上传到 GitHub Release 便于手工安装。

### GitHub Actions

#### 发布准备 (`release-prep.yml`)

- **触发方式：** 手动触发(`workflow_dispatch`)，仅在 `main` 分支运行。
- **用途：** 根据 `bump_type`（patch/minor/major 或手动 `vX.Y.Z`）创建发布分支 `workflow/vX.Y.Z` 并生成 PR：更新 `gr_fw_version`、同步 spec、插入带 TODO 的 changelog 条目供审阅。

#### 创建版本标签 (`create-version-tag.yml`)

- **触发方式：** `main` 分支手动触发(`workflow_dispatch`)，或合并 `workflow/vX.Y.Z` 的 PR 时自动触发。
- **用途：** 读取 `gr_fw_version`，校验 `vx.y.z`、changelog 条目与 spec 版本一致性，并在不存在该标签时创建并推送。

#### 更新 spec 版本 (`update-spec-version.yml`)

- **触发方式：** `create-version-tag` 工作流在 `main` 分支成功完成后触发，或手动触发(`workflow_dispatch`)。
- **用途：** 校验 `gr_fw_version` 是否符合 `vx.y.z`，更新 spec 的 `Version` 字段为 `x.y.z`，在版本变化。

#### 构建 COPR 包 (`build-copr-package.yml`)

- **触发方式：** `update-spec-version` 工作流在 `main` 分支成功完成后触发。
- **用途：** 使用 `packaging/copr/radp-bash-framework.spec` 触发 COPR SCM 构建，若版本标签不存在则跳过(SCM 源码基于标签归档)。

#### 更新 Homebrew tap (`update-homebrew-tap.yml`)

- **触发方式：** 推送版本标签(`v*`)、`create-version-tag` 工作流在 `main` 分支成功完成后触发，或手动触发(`workflow_dispatch`)。
- **用途：** 校验标签与 `gr_fw_version` 一致，生成发布元数据，更新 Homebrew tap 的 formula，并将变更推送到 tap 仓库。

#### 构建 OBS 包 (`build-obs-package.yml`)

- **触发方式：** `update-spec-version` 工作流在 `main` 分支成功完成后触发，或手动触发(`workflow_dispatch`)。
- **用途：** 同步源码 tarball、spec 和 Debian 打包元数据到 OBS 并触发构建，若版本标签不存在则跳过(tarball 基于标签归档)。

#### 附加发布产物 (`attach-release-packages.yml`)

- **触发方式：** 发布 GitHub Release，或手动触发(`workflow_dispatch`，可指定 tag)。
- **用途：** 从 COPR/OBS 下载构建好的包，以及 Homebrew tap 的 formula，并将它们上传为 Release 制品，方便手工安装。
