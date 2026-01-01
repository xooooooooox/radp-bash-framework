# GitHub Actions

## 工作流

### 创建版本标签（`create-version-tag.yml`）

- **触发方式：** 手动触发（`workflow_dispatch`），仅在 `main` 分支运行。
- **用途：** 从 `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh` 读取 `gr_fw_version`，校验是否符合 `vx.y.z`，并在不存在该标签时创建并推送。

### 更新 Homebrew tap（`update-homebrew-tap.yml`）

- **触发方式：** 推送版本标签（`v*`）或手动触发（`workflow_dispatch`）。
- **用途：** 根据标签生成发布元数据，更新 Homebrew tap 的 formula，并将变更推送到 tap 仓库。
