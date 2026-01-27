# Installation Guide

## Quick Install

### Homebrew (macOS/Linux)

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

### Script Install

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash
```

The script auto-detects available package managers and uses them if possible.

#### Script Options

```shell
RADP_BF_VERSION=v1.0.0 \
  RADP_BF_INSTALL_MODE=auto \
  RADP_BF_INSTALL_DIR="$HOME/.local/lib/radp-bash-framework" \
  RADP_BF_BIN_DIR="$HOME/.local/bin" \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh)"
```

| Variable                | Description                                                              | Default                            |
|-------------------------|--------------------------------------------------------------------------|------------------------------------|
| `RADP_BF_INSTALL_MODE`  | `auto`, `manual`, or specific: `homebrew`, `dnf`, `yum`, `apt`, `zypper` | `auto`                             |
| `RADP_BF_VERSION`       | Specific version (e.g., `v1.0.0`)                                        | latest                             |
| `RADP_BF_REF`           | Branch/tag/commit (manual mode only, takes precedence over VERSION)      | -                                  |
| `RADP_BF_INSTALL_DIR`   | Installation directory (manual mode only)                                | `~/.local/lib/radp-bash-framework` |
| `RADP_BF_BIN_DIR`       | Binary symlink directory (manual mode only)                              | `~/.local/bin`                     |
| `RADP_BF_ALLOW_ANY_DIR` | Allow custom install dir not ending with `radp-bash-framework`           | `0`                                |

## Package Manager Install

### RPM (Fedora/RHEL/CentOS via COPR)

```shell
# dnf
sudo dnf install -y dnf-plugins-core
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y radp-bash-framework

# yum
sudo yum install -y epel-release yum-plugin-copr
sudo yum copr enable -y xooooooooox/radp
sudo yum install -y radp-bash-framework
```

### OBS Repository

OBS provides multi-distro builds. Replace `<DISTRO>` with your target (e.g., `CentOS_7`, `openSUSE_Tumbleweed`,
`xUbuntu_24.04`).

**Debian/Ubuntu (apt):**

```shell
echo 'deb http://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/ /' | \
  sudo tee /etc/apt/sources.list.d/home:xooooooooox:radp.list
curl -fsSL https://download.opensuse.org/repositories/home:xooooooooox:radp/ <DISTRO >/Release.key | \
  gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_xooooooooox_radp.gpg >/dev/null
sudo apt update
sudo apt install radp-bash-framework
```

**Fedora/RHEL/CentOS (dnf):**

```shell
sudo dnf config-manager --add-repo \
  https://download.opensuse.org/repositories/home:/xooooooooox:/radp/ <DISTRO >/radp.repo
sudo dnf install -y radp-bash-framework
```

**CentOS/RHEL (yum):**

```shell
sudo yum-config-manager --add-repo \
  https://download.opensuse.org/repositories/home:/xooooooooox:/radp/ <DISTRO >/radp.repo
sudo yum install -y radp-bash-framework
```

## Manual Install

Download packages from [GitHub Releases](https://github.com/xooooooooox/radp-bash-framework/releases/latest):

```shell
# RPM
sudo rpm -Uvh ./obs-radp-bash-framework- <version >- <release >.noarch.rpm

# DEB
sudo dpkg -i ./obs-radp-bash-framework_ <version >- <release >_all.deb
sudo apt-get -f install
```

Or run directly from source:

```shell
source /path/to/radp-bash-framework/src/main/shell/framework/init.sh
```

## Load the Framework

After installation, load the framework in your shell:

```shell
source "$(radp-bf path init)"
```

Add to `~/.bashrc` for automatic loading on shell startup.

## Upgrade

### Homebrew

```shell
brew upgrade radp-bash-framework
```

### Script

Re-run the install script:

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash
```

### RPM (COPR)

```shell
# dnf
sudo dnf clean metadata
sudo dnf upgrade --refresh -y radp-bash-framework

# yum
sudo yum clean expire-cache
sudo yum update -y radp-bash-framework
```

### OBS Repository

```shell
# apt
sudo apt update
sudo apt install -y radp-bash-framework

# dnf
sudo dnf upgrade -y radp-bash-framework

# yum
sudo yum update -y radp-bash-framework
```

### Manual

Download new package from releases and install:

```shell
# RPM
sudo rpm -Uvh ./obs-radp-bash-framework- <version >- <release >.noarch.rpm

# DEB
sudo dpkg -i ./obs-radp-bash-framework_ <version >- <release >_all.deb
```
