# GitHub Actions

## 工作流

### 创建版本标签（`create-version-tag.yml`）

- **触发方式：** 手动触发（`workflow_dispatch`），仅在 `main` 分支运行。
- **用途：** 从 `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh` 读取 `gr_fw_version`，校验是否符合 `vx.y.z`，并在不存在该标签时创建并推送。

### 更新 spec 版本（`update-spec-version.yml`）

- **触发方式：** `main` 分支推送。
- **用途：** 校验 `gr_fw_version` 是否符合 `vx.y.z`，确保对应标签已存在，并与最新标签中的 `gr_fw_version` 对比，仅在版本不同的情况下更新 `packaging/rpm/radp-bash-framework.spec` 的 `Version` 字段为 `x.y.z`。

### 构建 COPR 包（`build-copr-package.yml`）

- **触发方式：** `update-spec-version` 工作流在 `main` 分支成功完成后触发。
- **用途：** 使用 `packaging/rpm/radp-bash-framework.spec` 触发 COPR SCM 构建。

### 更新 Homebrew tap（`update-homebrew-tap.yml`）

- **触发方式：** 推送版本标签（`v*`）或手动触发（`workflow_dispatch`）。
- **用途：** 根据标签生成发布元数据，更新 Homebrew tap 的 formula，并将变更推送到 tap 仓库。

### 构建 deb 包（`build-deb-package.yml`）

- **触发方式：** 推送版本标签（`v*`）或手动触发（`workflow_dispatch`）。
- **用途：** 基于标签源码构建 `.deb` 包，并上传到 GitHub Release。

