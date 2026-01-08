# radp-bash-framework

[![COPR build status](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/status_image/last_build.png)](https://download.copr.fedorainfracloud.org/results/xooooooooox/radp/)
[![COPR packages](https://img.shields.io/badge/COPR-packages-4b8bbe)](https://download.copr.fedorainfracloud.org/results/xooooooooox/radp/)

[![OBS package build status](https://build.opensuse.org/projects/home:xooooooooox:radp/packages/radp-bash-framework/badge.svg)](https://build.opensuse.org/package/show/home:xooooooooox:radp/radp-bash-framework)
[![OBS packages](https://img.shields.io/badge/OBS-packages-4b8bbe)](https://software.opensuse.org//download.html?project=home%3Axooooooooox%3Aradp&package=radp-bash-framework)

[![CI: COPR](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/build-copr-package.yml?label=CI%3A%20COPR)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-copr-package.yml)
[![CI: OBS](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/build-obs-package.yml?label=CI%3A%20OBS)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-obs-package.yml)
[![CI: Homebrew](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/update-homebrew-tap.yml?label=Homebrew%20tap)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/update-homebrew-tap.yml)

## QuickStart

### Installation

安装后建议在当前 shell 加载入口：

```shell
source "$(radp-bf --print-run)"
```

如需每次启动自动加载，可将上述命令写入 `~/.bashrc` 或其它 shell 配置。

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

#### OBS repository (zypper / dnf / yum / apt)

OBS 提供多发行版的 RPM/DEB 构建。替换 `<DISTRO>` 为目标发行版路径（例如 `Fedora_39`、`openSUSE_Tumbleweed`、`xUbuntu_24.04`）。

```shell
# openSUSE/SLES (zypper)
sudo zypper addrepo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo zypper refresh
sudo zypper install radp-bash-framework

# Fedora/RHEL/CentOS (dnf)
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo dnf install -y radp-bash-framework

# CentOS/RHEL (yum)
sudo yum-config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo yum install -y radp-bash-framework

# Debian/Ubuntu (apt)
echo 'deb http://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/ /' \
  | sudo tee /etc/apt/sources.list.d/home:xooooooooox:radp.list
curl -fsSL https://download.opensuse.org/repositories/home:xooooooooox:radp/<DISTRO>/Release.key \
  | gpg --dearmor \
  | sudo tee /etc/apt/trusted.gpg.d/home_xooooooooox_radp.gpg > /dev/null
sudo apt-get update
sudo apt-get install -y radp-bash-framework
```

#### Manual (Release assets / source)

每次发布都会附带可直接安装的包：<https://github.com/xooooooooox/radp-bash-framework/releases/latest>

下载 `.rpm` 或 `.deb` 资产（文件名前缀通常为 `obs-` 或 `copr-`）后安装：

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

### Upgrade

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

#### OBS repository (zypper / dnf / yum / apt)

```shell
# openSUSE/SLES
sudo zypper refresh
sudo zypper update radp-bash-framework

# Fedora/RHEL/CentOS (dnf)
sudo dnf upgrade -y radp-bash-framework

# CentOS/RHEL (yum)
sudo yum update -y radp-bash-framework

# Debian/Ubuntu(apt)
sudo apt update
sudo apt install -y radp-bash-framework
```

#### Manual (Release assets)

从最新 Release 下载新的 `.rpm`/`.deb` 包后安装即可升级：

```shell
# RPM
sudo rpm -Uvh ./obs-radp-bash-framework-<version>-<release>.noarch.rpm

# DEB
sudo dpkg -i ./obs-radp-bash-framework_<version>-<release>_all.deb
sudo apt-get -f install
```

## CI

### How to release

1. 触发 `release-prep`（输入 `vX.Y.Z`）生成发布分支 `workflow/vX.Y.Z` 并创建 PR：更新 `gr_fw_version`、同步 spec、插入 changelog 条目。
2. 在 PR 中补充/整理 changelog 后合并到 `main`。
3. PR 合并后会自动触发 `create-version-tag`（或手动触发）校验版本/changelog/spec 并创建/推送标签。
4. 标签相关工作流执行：
    - `update-homebrew-tap` 更新 Homebrew 的 formula。
5. `update-spec-version` 在 `create-version-tag` 成功完成后执行（必要时可手动触发）。
6. `build-copr-package` 会在 `update-spec-version` 成功完成后触发 COPR SCM 构建（仅当标签指向本次 workflow 运行提交）。
7. `build-obs-package` 会同步源码到 OBS 并触发构建（仅当标签指向本次 workflow 运行提交）。
8. `attach-release-packages` 会从 COPR/OBS 拉取构建产物及 Homebrew formula，并上传到 GitHub Release 便于手工安装。

### GitHub Actions

#### Release prep (`release-prep.yml`)

- **Trigger:** 手动触发(`workflow_dispatch`)，仅在 `main` 分支运行。
- **Purpose:** 创建发布分支 `workflow/vX.Y.Z` 并生成 PR：更新 `gr_fw_version`、同步 spec、插入带 TODO 的 changelog 条目供审阅。

#### Create version tag (`create-version-tag.yml`)

- **Trigger:** `main` 分支手动触发(`workflow_dispatch`)，或合并 `workflow/vX.Y.Z` 的 PR 时自动触发。
- **Purpose:** 读取 `gr_fw_version`，校验 `vx.y.z`、changelog 条目与 spec 版本一致性，并在不存在该标签时创建并推送。

#### Update spec version (`update-spec-version.yml`)

- **Trigger:** `create-version-tag` 工作流在 `main` 分支成功完成后触发，或手动触发(`workflow_dispatch`)。
- **Purpose:** 校验 `gr_fw_version` 是否符合 `vx.y.z`，更新 spec 的 `Version` 字段为 `x.y.z`，在版本变化。

#### Build COPR package (`build-copr-package.yml`)

- **Trigger:** `update-spec-version` 工作流在 `main` 分支成功完成后触发。
- **Purpose:** 使用 `packaging/copr/radp-bash-framework.spec` 触发 COPR SCM 构建，若版本标签不存在则跳过(SCM 源码基于标签归档)。

#### Update Homebrew tap (`update-homebrew-tap.yml`)

- **Trigger:** 推送版本标签(`v*`)、`create-version-tag` 工作流在 `main` 分支成功完成后触发，或手动触发(`workflow_dispatch`)。
- **Purpose:** 校验标签与 `gr_fw_version` 一致，生成发布元数据，更新 Homebrew tap 的 formula，并将变更推送到 tap 仓库。

#### Build OBS package (`build-obs-package.yml`)

- **Trigger:** `update-spec-version` 工作流在 `main` 分支成功完成后触发，或手动触发(`workflow_dispatch`)。
- **Purpose:** 同步源码 tarball、spec 和 Debian 打包元数据到 OBS 并触发构建，若版本标签不存在则跳过(tarball 基于标签归档)。

#### Attach release packages (`attach-release-packages.yml`)

- **Trigger:** 发布 GitHub Release，或手动触发(`workflow_dispatch`，可指定 tag)。
- **Purpose:** 从 COPR/OBS 下载构建好的包，以及 Homebrew tap 的 formula，并将它们上传为 Release 资产，方便手工安装。
