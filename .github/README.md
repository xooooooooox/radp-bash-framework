# GitHub Actions

## Workflows

### Create version tag (`create-version-tag.yml`)

- **Trigger:** Manual (`workflow_dispatch`), only runs when the branch is `main`.
- **Purpose:** Read `gr_fw_version` from `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh`, validate it matches `vx.y.z`, and create/push the Git tag if it does not already exist.

### Update spec version (`update-spec-version.yml`)

- **Trigger:** Push to `main` that changes `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh` and the matching tag already exists.
- **Purpose:** Validate `gr_fw_version` follows `vx.y.z`, then update `packaging/rpm/radp-bash-framework.spec` to `x.y.z` and commit the change.

### Update Homebrew tap (`update-homebrew-tap.yml`)

- **Trigger:** On push of a version tag (`v*`) or manual (`workflow_dispatch`).
- **Purpose:** Build release metadata from the tag, update the Homebrew tap formula, and push the changes to the tap repository.
