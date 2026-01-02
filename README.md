# radp-bash-framework

```
    ____  ___    ____  ____     ____  ___   _____ __  __
   / __ \/   |  / __ \/ __ \   / __ )/   | / ___// / / /
  / /_/ / /| | / / / / /_/ /  / __  / /| | \__ \/ /_/ /
 / _, _/ ___ |/ /_/ / ____/  / /_/ / ___ |___/ / __  /
/_/ |_/_/  |_/_____/_/      /_____/_/  |_/____/_/ /_/

```

[![Copr build status](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/)

## Installation

### Homebrew

Click [here](https://github.com/xooooooooox/homebrew-radp/blob/main/Formula/radp-bash-framework.rb) see details.

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

After install, resolve the framework entrypoint:

```shell
source "$(radp-bf --print-run)"
```

### rpm (dnf/yum)

- If use `dnf`:

```shell
sudo dnf install -y dnf-plugins-core
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y radp-bash-framework
```

- If use `yum`:

```shell
sudo yum install -y epel-release
sudo yum install -y yum-plugin-copr
sudo yum copr enable -y xooooooooox/radp
sudo yum install -y radp-bash-framework
```

After install, resolve the framework entrypoint:

```shell
source "$(radp-bf --print-run)"
```

### apt-get

```shell
VERSION="<version>"
curl -L -o "radp-bash-framework_${VERSION}_all.deb" \
  "https://github.com/xooooooooox/radp-bash-framework/releases/download/v${VERSION}/radp-bash-framework_${VERSION}_all.deb"
sudo apt-get install -y "./radp-bash-framework_${VERSION}_all.deb"
```

After install, resolve the framework entrypoint:

```shell
source "$(radp-bf --print-run)"
```

### manual

TODO

## Upgrade

### Homebrew

```shell
brew upgrade radp-bash-framework
```

### rpm (dnf/yum)

```shell
sudo dnf upgrade -y radp-bash-framework
sudo yum update -y radp-bash-framework
```

### apt-get

```shell
VERSION="<version>"
curl -L -o "radp-bash-framework_${VERSION}_all.deb" \
  "https://github.com/xooooooooox/radp-bash-framework/releases/download/v${VERSION}/radp-bash-framework_${VERSION}_all.deb"
sudo apt-get install -y "./radp-bash-framework_${VERSION}_all.deb"
```

## Release

1. Update `gr_fw_version` in `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh` (format: `vx.y.z`).
2. Push to `main`.
3. Trigger the `create-version-tag` workflow to create/push the tag.
4. Wait for tag workflows:
    - `update-homebrew-tap` updates the Homebrew formula.
    - `build-deb-package` builds and uploads the `.deb` to the GitHub Release.
5. The `update-spec-version` workflow updates `packaging/copr/radp-bash-framework.spec` on `main` when the version changes.
6. The `build-copr-package` workflow triggers a COPR SCM build after `update-spec-version` completes successfully on `main`.

## GitHub Actions

### Create version tag (`create-version-tag.yml`)

- **Trigger:** Manual (`workflow_dispatch`), only runs when the branch is `main`.
- **Purpose:** Read `gr_fw_version` from `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh`, validate it matches `vx.y.z`, and create/push the Git tag if it does not already exist.

### Update spec version (`update-spec-version.yml`)

- **Trigger:** Push to `main`.
- **Purpose:** Validate `gr_fw_version` follows `vx.y.z`, ensure the matching tag exists, compare it against the latest tag's `gr_fw_version`, and update `packaging/copr/radp-bash-framework.spec` to `x.y.z` only when the version differs.

### Build COPR package (`build-copr-package.yml`)

- **Trigger:** Successful completion of the `update-spec-version` workflow on `main`.
- **Purpose:** Trigger a COPR SCM build using the updated spec at `packaging/copr/radp-bash-framework.spec`.

### Update Homebrew tap (`update-homebrew-tap.yml`)

- **Trigger:** On push of a version tag (`v*`) or manual (`workflow_dispatch`).
- **Purpose:** Build release metadata from the tag, update the Homebrew tap formula, and push the changes to the tap repository.

### Build deb package (`build-deb-package.yml`)

- **Trigger:** On push of a version tag (`v*`) or manual (`workflow_dispatch`).
- **Purpose:** Build the `.deb` package from the tagged source and upload it to the GitHub release.

