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

After installing, load the framework entrypoint in your shell:

```shell
source "$(radp-bf --print-run)"
```

You can place that command in your shell profile (e.g. `~/.bashrc`) for automatic loading.

### Homebrew

Click [here](https://github.com/xooooooooox/homebrew-radp/blob/main/Formula/radp-bash-framework.rb) see details.

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
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

### OBS (zypper/apt/dnf)

OBS provides multi-distro builds for RPM/DEB. Add the repository from your OBS project, then install:

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

```shell
VERSION="<version>"
curl -L -o "radp-bash-framework_${VERSION}_all.deb" \
  "https://github.com/xooooooooox/radp-bash-framework/releases/download/v${VERSION}/radp-bash-framework_${VERSION}_all.deb"
sudo apt-get install -y "./radp-bash-framework_${VERSION}_all.deb"
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

```shell
VERSION="<version>"
curl -L -o "radp-bash-framework_${VERSION}_all.deb" \
  "https://github.com/xooooooooox/radp-bash-framework/releases/download/v${VERSION}/radp-bash-framework_${VERSION}_all.deb"
sudo apt-get install -y "./radp-bash-framework_${VERSION}_all.deb"
```

## Release

1. Update `gr_fw_version` in `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh` (format: `vx.y.z`).
2. Push to `main`.
3. Trigger the `create-version-tag` workflow to create/push the tag (or push a valid `vX.Y.Z` tag directly).
4. Wait for tag workflows (triggered by tag push or by the `create-version-tag` workflow run):
    - `update-homebrew-tap` updates the Homebrew formula.
    - `build-deb-package` builds and uploads the `.deb` to the GitHub Release.
5. The `update-spec-version` workflow updates `packaging/copr/radp-bash-framework.spec` on `main` when the version changes.
6. The `build-copr-package` workflow triggers a COPR SCM build after `update-spec-version` completes successfully on `main` (only when the release tag exists).
7. The `build-obs-package` workflow syncs sources to OBS and triggers the OBS build (only when the release tag exists).

## GitHub Actions

### Create version tag (`create-version-tag.yml`)

- **Trigger:** Manual (`workflow_dispatch`), only runs when the branch is `main`.
- **Purpose:** Read `gr_fw_version` from `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh`, validate it matches `vx.y.z`, and create/push the Git tag if it does not already exist.

### Update spec version (`update-spec-version.yml`)

- **Trigger:** Push to `main`, push a version tag (`v*`), or successful completion of the `create-version-tag` workflow on `main`.
- **Purpose:** Validate `gr_fw_version` follows `vx.y.z`, ensure the matching tag exists, compare it against the latest tag's `gr_fw_version`, and update `packaging/copr/radp-bash-framework.spec` to `x.y.z` only when the version differs.

### Build COPR package (`build-copr-package.yml`)

- **Trigger:** Successful completion of the `update-spec-version` workflow on `main`.
- **Purpose:** Trigger a COPR SCM build using the updated spec at `packaging/copr/radp-bash-framework.spec`, skipping the build when the release tag is missing (the SCM source is generated from the tag).

### Update Homebrew tap (`update-homebrew-tap.yml`)

- **Trigger:** On push of a version tag (`v*`), successful completion of the `create-version-tag` workflow on `main`, or manual (`workflow_dispatch`).
- **Purpose:** Build release metadata from the tag, update the Homebrew tap formula, and push the changes to the tap repository.

### Build deb package (`build-deb-package.yml`)

- **Trigger:** On push of a version tag (`v*`), successful completion of the `create-version-tag` workflow on `main`, or manual (`workflow_dispatch`).
- **Purpose:** Build the `.deb` package from the tagged source and upload it to the GitHub release.

### Build OBS package (`build-obs-package.yml`)

- **Trigger:** Successful completion of the `update-spec-version` workflow on `main`, or manual (`workflow_dispatch`).
- **Purpose:** Sync the release tarball, spec, and Debian packaging metadata to OBS and trigger the build, skipping the build when the release tag is missing (the tarball is created from the tag).
