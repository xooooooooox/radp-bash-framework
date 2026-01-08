# radp-bash-framework

```
    ____  ___    ____  ____     ____  ___   _____ __  __
   / __ \/   |  / __ \/ __ \   / __ )/   | / ___// / / /
  / /_/ / /| | / / / / /_/ /  / __  / /| | \__ \/ /_/ /
 / _, _/ ___ |/ /_/ / ____/  / /_/ / ___ |___/ / __  /
/_/ |_/_/  |_/_____/_/      /_____/_/  |_/____/_/ /_/

```

[![Copr build status](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/)
[![OBS package build status](https://build.opensuse.org/projects/home:xooooooooox:radp/packages/radp-bash-framework/badge.svg)](https://build.opensuse.org/package/show/home:xooooooooox:radp/radp-bash-framework)
[![CI: COPR](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/build-copr-package.yml?label=CI%3A%20COPR)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-copr-package.yml)
[![CI: OBS](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/build-obs-package.yml?label=CI%3A%20OBS)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-obs-package.yml)
[![CI: Homebrew](https://img.shields.io/github/actions/workflow/status/xooooooooox/radp-bash-framework/update-homebrew-tap.yml?label=Homebrew%20tap)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/update-homebrew-tap.yml)

[![COPR packages](https://img.shields.io/badge/COPR-packages-4b8bbe)](https://download.copr.fedorainfracloud.org/results/xooooooooox/radp/)
[![OBS packages](https://img.shields.io/badge/OBS-packages-4b8bbe)](https://software.opensuse.org//download.html?project=home%3Axooooooooox%3Aradp&package=radp-bash-framework)

## QuickStart

### Installation

After installing, load the framework entrypoint in your shell:

```shell
source "$(radp-bf --print-run)"
```

You can place that command in your shell profile (e.g. `~/.bashrc`) for automatic loading.

#### Script (curl / wget / fetch)

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/tools/install.sh | bash
```

Or:

```shell
wget -qO- https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/tools/install.sh | bash
fetch -qo- https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/tools/install.sh | bash
```

Optional variables:

```shell
RADP_BF_VERSION=vX.Y.Z \
RADP_BF_REF=main \
RADP_BF_INSTALL_DIR="$HOME/.local/lib/radp-bash-framework" \
RADP_BF_BIN_DIR="$HOME/.local/bin" \
RADP_BF_ALLOW_ANY_DIR=1 \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/tools/install.sh)"
```

`RADP_BF_REF` can be a branch, tag, or commit and takes precedence over `RADP_BF_VERSION`.
If you set a custom install dir that does not end with `radp-bash-framework`, also set `RADP_BF_ALLOW_ANY_DIR=1`.
Defaults: `~/.local/lib/radp-bash-framework` and `~/.local/bin`.

Re-run the script to upgrade.

#### Homebrew

Click [here](https://github.com/xooooooooox/homebrew-radp/blob/main/Formula/radp-bash-framework.rb) see details.

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

#### OBS repository (dnf / yum / apt)

OBS provides multi-distro builds. Replace `<DISTRO>` with the target path (e.g. `CentOS_7`, `openSUSE_Tumbleweed`, `xUbuntu_24.04`).

```shell
# CentOS/RHEL (yum)
sudo yum-config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo yum install -y radp-bash-framework

# Debian/Ubuntu (apt)
echo 'deb http://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/ /' | sudo tee /etc/apt/sources.list.d/home:xooooooooox:radp.list
curl -fsSL https://download.opensuse.org/repositories/home:xooooooooox:radp/<DISTRO>/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_xooooooooox_radp.gpg > /dev/null
sudo apt update
sudo apt install radp-bash-framework

# Fedora/RHEL/CentOS (dnf)
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo dnf install -y radp-bash-framework
```

#### Manual (Release assets / source)

Prebuilt installable packages are attached to each release: <https://github.com/xooooooooox/radp-bash-framework/releases/latest>

Download the `.rpm` or `.deb` asset (prefixed with `obs-` or `copr-`) and install:

```shell
# RPM (Fedora/RHEL/CentOS)
sudo rpm -Uvh ./obs-radp-bash-framework-<version>-<release>.noarch.rpm
# or
sudo dnf install ./obs-radp-bash-framework-<version>-<release>.noarch.rpm

# DEB (Debian/Ubuntu)
sudo dpkg -i ./obs-radp-bash-framework_<version>-<release>_all.deb
sudo apt-get -f install
```

Or run directly from source:

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
# dnf
sudo dnf clean metadata
sudo dnf upgrade --refresh -y radp-bash-framework

# yum
sudo yum clean expire-cache
sudo yum update -y radp-bash-framework
```

#### OBS repository (dnf / yum / apt)

```shell
# CentOS/RHEL (yum)
sudo yum update -y radp-bash-framework

# Debian/Ubuntu(apt)
sudo apt update
sudo apt install -y radp-bash-framework

# Fedora/RHEL/CentOS (dnf)
sudo dnf upgrade -y radp-bash-framework
```

#### Manual (Release assets)

Download the new `.rpm`/`.deb` from the latest release and install it:

```shell
# RPM
sudo rpm -Uvh ./obs-radp-bash-framework-<version>-<release>.noarch.rpm

# DEB
sudo dpkg -i ./obs-radp-bash-framework_<version>-<release>_all.deb
sudo apt-get -f install
```

## CI

### How to release

1. Trigger `release-prep` with a `bump_type` (patch/minor/major/manual, default patch). For manual, provide `vX.Y.Z`. This updates `gr_fw_version`, syncs spec versions, and adds a changelog entry (branch `workflow/vX.Y.Z` + PR).
2. Review/edit the changelog in the PR and merge to `main`.
3. `create-version-tag` runs automatically on merge (or trigger it manually) to validate the version/changelog/spec and create/push the tag.
4. Tag workflows run:
    - `update-homebrew-tap` updates the Homebrew formula.
5. `update-spec-version` runs after `create-version-tag` (or manually if needed).
6. `build-copr-package` triggers after `update-spec-version` completes on `main` (only when the release tag points to the workflow run commit).
7. `build-obs-package` syncs sources to OBS and triggers the build (only when the release tag points to the workflow run commit).
8. `attach-release-packages` pulls built packages from COPR/OBS and the Homebrew formula and uploads them to the GitHub Release for manual installs.

### GitHub Actions

#### Release prep (`release-prep.yml`)

- **Trigger:** Manual (`workflow_dispatch`) on `main`.
- **Purpose:** Create a release branch (`workflow/vX.Y.Z`) from the resolved version (patch/minor/major bump, or manual `vX.Y.Z`), update `gr_fw_version`, sync spec versions, insert a changelog entry with a TODO list of commits, and open a PR for review.

#### Create version tag (`create-version-tag.yml`)

- **Trigger:** Manual (`workflow_dispatch`) on `main`, or merge of a `workflow/vX.Y.Z` PR.
- **Purpose:** Read `gr_fw_version`, validate `vx.y.z`, the changelog entry, and spec versions, then create/push the Git tag if it does not already exist.

#### Update spec version (`update-spec-version.yml`)

- **Trigger:** Successful completion of the `create-version-tag` workflow on `main`, or manual (`workflow_dispatch`).
- **Purpose:** Validate `gr_fw_version` follows `vx.y.z`, update spec `Version` to `x.y.z` when the version changes.

#### Build COPR package (`build-copr-package.yml`)

- **Trigger:** Successful completion of the `update-spec-version` workflow on `main`.
- **Purpose:** Trigger a COPR SCM build using the updated spec at `packaging/copr/radp-bash-framework.spec`, skipping the build when the release tag is missing (the SCM source is generated from the tag).

#### Update Homebrew tap (`update-homebrew-tap.yml`)

- **Trigger:** On push of a version tag (`v*`), successful completion of the `create-version-tag` workflow on `main`, or manual (`workflow_dispatch`).
- **Purpose:** Validate the tag matches `gr_fw_version`, build release metadata from the tag, update the Homebrew tap formula, and push the changes to the tap repository.

#### Build OBS package (`build-obs-package.yml`)

- **Trigger:** Successful completion of the `update-spec-version` workflow on `main`, or manual (`workflow_dispatch`).
- **Purpose:** Sync the release tarball, spec, and Debian packaging metadata to OBS and trigger the build, skipping the build when the release tag is missing (the tarball is created from the tag).

#### Attach release packages (`attach-release-packages.yml`)

- **Trigger:** Published GitHub Release, or manual (`workflow_dispatch` with optional tag).
- **Purpose:** Download built packages from COPR/OBS and the Homebrew tap formula, then upload them as Release assets for manual installation.
