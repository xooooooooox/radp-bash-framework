# radp-bash-framework

## 安装

### Homebrew

详情见: <https://github.com/xooooooooox/homebrew-radp/blob/main/Formula/radp-bash-framework.rb>.

```bash
brew tap xooooooooox/radp
brew install radp-bash-framework
```

安装后，可以通过以下方式获取 `run.sh` 的路径：

```bash
source "$(radp-bf --print-run)"
```

### yum

### dnf

### npm

```bash
npm install -g radp-bash-framework
```

安装后，可以通过以下方式获取 `run.sh` 的路径：

```bash
source "$(radp-bf --print-run)"
```

### apt-get

```bash
VERSION="<version>"
curl -L -o "radp-bash-framework_${VERSION}_all.deb" \
  "https://github.com/xooooooooox/radp-bash-framework/releases/download/v${VERSION}/radp-bash-framework_${VERSION}_all.deb"
sudo apt-get install -y "./radp-bash-framework_${VERSION}_all.deb"
```

安装后，可以通过以下方式获取 `run.sh` 的路径：

```bash
source "$(radp-bf --print-run)"
```

"#{## 本地直接使用

将整个 `src/main/shell/framework` 目录拷贝到本地并使用：

```bash
source /path/to/framework/run.sh
```

### 手动安装

TODO

## 发布

1. 更新 `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh` 中的 `gr_fw_version`（格式：`vx.y.z`）。
2. 推送到 `main` 分支。
3. 手动触发 `create-version-tag` 工作流创建并推送版本标签。
4. 等待标签相关工作流执行完成：
    - `update-homebrew-tap` 更新 Homebrew 的 formula。
    - `build-deb-package` 构建并上传 `.deb` 到 GitHub Release。
5. `update-spec-version` 会在 `main` 分支版本变化时更新 `packaging/rpm/radp-bash-framework.spec`。
