# GitHub Actions

## Workflows

### Create version tag (`create-version-tag.yml`)

- **Trigger:** Manual (`workflow_dispatch`), only runs when the branch is `main`.
- **Purpose:** Read `gr_fw_version` from `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh`, validate it matches `vx.y.z`, and create/push the Git tag if it does not already exist.

### Update spec version (`update-spec-version.yml`)

- **Trigger:** Push to `main`.
- **Purpose:** Validate `gr_fw_version` follows `vx.y.z`, ensure the matching tag exists, compare it against the latest tag's `gr_fw_version`, and update `packaging/rpm/radp-bash-framework.spec` to `x.y.z` only when the version differs.

### Build COPR package (`build-copr-package.yml`)

- **Trigger:** Successful completion of the `update-spec-version` workflow on `main`.
- **Purpose:** Trigger a COPR SCM build using the updated spec at `packaging/rpm/radp-bash-framework.spec`.

### Update Homebrew tap (`update-homebrew-tap.yml`)

- **Trigger:** On push of a version tag (`v*`) or manual (`workflow_dispatch`).
- **Purpose:** Build release metadata from the tag, update the Homebrew tap formula, and push the changes to the tap repository.

### Build deb package (`build-deb-package.yml`)

- **Trigger:** On push of a version tag (`v*`) or manual (`workflow_dispatch`).
- **Purpose:** Build the `.deb` package from the tagged source and upload it to the GitHub release.
