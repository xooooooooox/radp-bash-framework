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

### RPM (Fedora/RHEL/CentOS via COPR)

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

### OBS repository (zypper / dnf / yum / apt)

OBS provides multi-distro builds. Replace `<DISTRO>` with the target path (e.g. `Fedora_39`, `openSUSE_Tumbleweed`, `xUbuntu_24.04`).

```shell
# openSUSE/SLES (zypper)
sudo zypper addrepo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo zypper refresh
sudo zypper install radp-bash-framework

# Fedora/RHEL/CentOS (dnf)
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo dnf install -y radp-bash-framework

# CentOS/RHEL (yum)
sudo yum-config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/radp.repo
sudo yum install -y radp-bash-framework

# Debian/Ubuntu (apt)
echo 'deb http://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/ /' \
  | sudo tee /etc/apt/sources.list.d/home:xooooooooox:radp.list
curl -fsSL https://download.opensuse.org/repositories/home:xooooooooox:radp/<DISTRO>/Release.key \
  | gpg --dearmor \
  | sudo tee /etc/apt/trusted.gpg.d/home_xooooooooox_radp.gpg > /dev/null
sudo apt-get update
sudo apt-get install -y radp-bash-framework
```

### Manual (Release assets / source)

Prebuilt installable packages are attached to each release:
<https://github.com/xooooooooox/radp-bash-framework/releases/latest>

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

## Upgrade

### Homebrew

```shell
brew upgrade radp-bash-framework
```

### RPM (Fedora/RHEL/CentOS via COPR)

```shell
sudo dnf clean metadata
sudo dnf upgrade --refresh -y radp-bash-framework
sudo yum clean expire-cache
sudo yum update -y radp-bash-framework
```

### OBS repository (zypper / dnf / yum / apt)

```shell
# openSUSE/SLES
sudo zypper refresh
sudo zypper update radp-bash-framework

# Fedora/RHEL/CentOS (dnf)
sudo dnf upgrade -y radp-bash-framework

# CentOS/RHEL (yum)
sudo yum update -y radp-bash-framework

# Debian/Ubuntu(apt)
sudo apt update
sudo apt install -y radp-bash-framework
```

### Manual (Release assets)

Download the new `.rpm`/`.deb` from the latest release and install it:

```shell
# RPM
sudo rpm -Uvh ./obs-radp-bash-framework-<version>-<release>.noarch.rpm

# DEB
sudo dpkg -i ./obs-radp-bash-framework_<version>-<release>_all.deb
sudo apt-get -f install
```

## Release

1. Update `gr_fw_version` in `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh` (format: `vx.y.z`).
2. Push to `main`.
3. Trigger the `create-version-tag` workflow to create/push the tag.
4. Wait for tag workflows (triggered by tag push or by the `create-version-tag` workflow run):
    - `update-homebrew-tap` updates the Homebrew formula.
5. The `create-version-tag` and `update-spec-version` workflows sync spec versions when the version changes.
6. The `build-copr-package` workflow triggers a COPR SCM build after `update-spec-version` completes successfully on `main` (only when the release tag exists).
7. The `build-obs-package` workflow syncs sources to OBS and triggers the OBS build (only when the release tag exists).
8. The `attach-release-artifacts` workflow pulls built packages from COPR/OBS and the Homebrew formula and uploads them to the GitHub Release for manual installs.

## GitHub Actions

### Create version tag (`create-version-tag.yml`)

- **Trigger:** Manual (`workflow_dispatch`), only runs when the branch is `main`.
- **Purpose:** Read `gr_fw_version` from `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh`, validate it matches `vx.y.z`, sync spec `Version`, and create/push the Git tag if it does not already exist.

### Update spec version (`update-spec-version.yml`)

- **Trigger:** Push to `main`, or successful completion of the `create-version-tag` workflow on `main`.
- **Purpose:** Validate `gr_fw_version` follows `vx.y.z`, update spec `Version` to `x.y.z` when the version changes.

### Build COPR package (`build-copr-package.yml`)

- **Trigger:** Successful completion of the `update-spec-version` workflow on `main`.
- **Purpose:** Trigger a COPR SCM build using the updated spec at `packaging/copr/radp-bash-framework.spec`, skipping the build when the release tag is missing (the SCM source is generated from the tag).

### Update Homebrew tap (`update-homebrew-tap.yml`)

- **Trigger:** On push of a version tag (`v*`), successful completion of the `create-version-tag` workflow on `main`, or manual (`workflow_dispatch`).
- **Purpose:** Validate the tag matches `gr_fw_version`, build release metadata from the tag, update the Homebrew tap formula, and push the changes to the tap repository.

### Build OBS package (`build-obs-package.yml`)

- **Trigger:** Successful completion of the `update-spec-version` workflow on `main`, or manual (`workflow_dispatch`).
- **Purpose:** Sync the release tarball, spec, and Debian packaging metadata to OBS and trigger the build, skipping the build when the release tag is missing (the tarball is created from the tag).

### Attach release artifacts (`attach-release-artifacts.yml`)

- **Trigger:** Published GitHub Release, or manual (`workflow_dispatch` with optional tag).
- **Purpose:** Download built packages from COPR/OBS and the Homebrew tap formula, then upload them as Release assets for manual installation.
