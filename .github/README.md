# GitHub Actions

## Workflows

### Create version tag (`create-version-tag.yml`)

- **Trigger:** Manual (`workflow_dispatch`), only runs when the branch is `main`.
- **Purpose:** Read `gr_fw_version` from `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh`, validate it matches `vx.y.z`, and create/push the Git tag if it does not already exist.

### Update Homebrew tap (`update-homebrew-tap.yml`)

- **Trigger:** On push of a version tag (`v*`) or manual (`workflow_dispatch`).
- **Purpose:** Build release metadata from the tag, update the Homebrew tap formula, and push the changes to the tap repository.
