# radp-bash-framework

## 安装

安装后建议在当前 shell 加载入口：

```bash
source "$(radp-bf --print-run)"
```

如需每次启动自动加载，可将上述命令写入 `~/.bashrc` 或其它 shell 配置。

### Homebrew

详情见: <https://github.com/xooooooooox/homebrew-radp/blob/main/Formula/radp-bash-framework.rb>.

```bash
brew tap xooooooooox/radp
brew install radp-bash-framework
```

### rpm (dnf/yum)

- `dnf`:

```shell
sudo dnf install -y dnf-plugins-core
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y radp-bash-framework
```

- `yum`:

```shell
sudo yum install -y epel-release
sudo yum install -y yum-plugin-copr
sudo yum copr enable -y xooooooooox/radp
sudo yum install -y radp-bash-framework
```

### OBS (zypper/apt/dnf)

OBS 提供多发行版的 RPM/DEB 构建。添加对应 OBS 仓库后安装：

```shell
# openSUSE/SLES
sudo zypper addrepo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo zypper refresh
sudo zypper install radp-bash-framework

# Fedora/RHEL/CentOS (replace <DISTRO> with your distro path, e.g. Fedora_39)
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo dnf install -y radp-bash-framework

# CentOS/RHEL (yum)
sudo yum-config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo yum install -y radp-bash-framework

# Debian/Ubuntu (replace <DISTRO> with your distro codename)
echo "deb https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/ /" | sudo tee /etc/apt/sources.list.d/radp-bash-framework.list
curl -fsSL https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/radp-bash-framework.gpg
sudo apt-get update
sudo apt-get install -y radp-bash-framework
```

### apt-get

```bash
VERSION="<version>"
curl -L -o "radp-bash-framework_${VERSION}_all.deb" \
  "https://github.com/xooooooooox/radp-bash-framework/releases/download/v${VERSION}/radp-bash-framework_${VERSION}_all.deb"
sudo apt-get install -y "./radp-bash-framework_${VERSION}_all.deb"
```

### 本地直接使用

将整个 `src/main/shell/framework` 目录拷贝到本地并使用：

```bash
source /path/to/framework/run.sh
```

### 手动安装

TODO

## 升级

### Homebrew

```bash
brew upgrade radp-bash-framework
```

### rpm (dnf/yum)

```bash
sudo dnf clean metadata
sudo dnf upgrade --refresh -y radp-bash-framework
sudo yum clean expire-cache
sudo yum update -y radp-bash-framework
```

### OBS (zypper/apt-get/yum/dnf)

```shell
# openSUSE/SLES
sudo zypper refresh
sudo zypper update radp-bash-framework

# Fedora/RHEL/CentOS (dnf)
sudo dnf upgrade -y radp-bash-framework

# CentOS/RHEL (yum)
sudo yum update -y radp-bash-framework

# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y radp-bash-framework
```

### apt-get

```bash
VERSION="<version>"
curl -L -o "radp-bash-framework_${VERSION}_all.deb" \
  "https://github.com/xooooooooox/radp-bash-framework/releases/download/v${VERSION}/radp-bash-framework_${VERSION}_all.deb"
sudo apt-get install -y "./radp-bash-framework_${VERSION}_all.deb"
```

## 发布

1. 更新 `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh` 中的 `gr_fw_version`(格式：`vx.y.z`)。
2. 推送到 `main` 分支。
3. 手动触发 `create-version-tag` 工作流创建并推送版本标签(或直接推送合法的 `vX.Y.Z` 标签)。
4. 等待标签相关工作流执行完成(由标签推送或 `create-version-tag` 工作流触发)：
    - `update-homebrew-tap` 更新 Homebrew 的 formula。
    - `build-deb-package` 构建并上传 `.deb` 到 GitHub Release。
5. `update-spec-version` 会在 `main` 分支版本变化时更新 `packaging/copr/radp-bash-framework.spec`。
6. `build-copr-package` 会在 `update-spec-version` 成功完成后触发 COPR SCM 构建(仅在版本标签存在时执行)。
7. `build-obs-package` 会同步源码到 OBS 并触发 OBS 构建(仅在版本标签存在时执行)。

## Github Actions

### 创建版本标签(`create-version-tag.yml`)

- **触发方式：** 手动触发(`workflow_dispatch`)，仅在 `main` 分支运行。
- **用途：** 从 `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh` 读取 `gr_fw_version`，校验是否符合 `vx.y.z`，并在不存在该标签时创建并推送。

### 更新 spec 版本(`update-spec-version.yml`)

- **触发方式：** `main` 分支推送、推送版本标签(`v*`)，或 `create-version-tag` 工作流在 `main` 分支成功完成后触发。
- **用途：** 校验 `gr_fw_version` 是否符合 `vx.y.z`，确保对应标签已存在，并与最新标签中的 `gr_fw_version` 对比，仅在版本不同的情况下更新 `packaging/copr/radp-bash-framework.spec` 的 `Version` 字段为 `x.y.z`。

### 构建 COPR 包(`build-copr-package.yml`)

- **触发方式：** `update-spec-version` 工作流在 `main` 分支成功完成后触发。
- **用途：** 使用 `packaging/copr/radp-bash-framework.spec` 触发 COPR SCM 构建，若版本标签不存在则跳过(SCM 源码基于标签归档)。

### 更新 Homebrew tap(`update-homebrew-tap.yml`)

- **触发方式：** 推送版本标签(`v*`)、`create-version-tag` 工作流在 `main` 分支成功完成后触发，或手动触发(`workflow_dispatch`)。
- **用途：** 根据标签生成发布元数据，更新 Homebrew tap 的 formula，并将变更推送到 tap 仓库。

### 构建 deb 包(`build-deb-package.yml`)

- **触发方式：** 推送版本标签(`v*`)、`create-version-tag` 工作流在 `main` 分支成功完成后触发，或手动触发(`workflow_dispatch`)。
- **用途：** 基于标签源码构建 `.deb` 包，并上传到 GitHub Release。

### 构建 OBS 包(`build-obs-package.yml`)

- **触发方式：** `update-spec-version` 工作流在 `main` 分支成功完成后触发，或手动触发(`workflow_dispatch`)。
- **用途：** 同步源码 tarball、spec 和 Debian 打包元数据到 OBS 并触发构建，若版本标签不存在则跳过(tarball 基于标签归档)。
