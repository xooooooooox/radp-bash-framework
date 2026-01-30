# Installation Guide

## Quick Install

### Homebrew (macOS)

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
bash install.sh --ref main
bash install.sh --ref v1.0.0-rc1
bash install.sh --mode manual
bash install.sh --mode dnf

curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash -s -- --ref main
```

| Option              | Description                                                              | Default                            |
|---------------------|--------------------------------------------------------------------------|------------------------------------|
| `--ref <ref>`       | Install from a git ref (branch, tag, SHA). Implies manual install.       | latest release                     |
| `--mode <mode>`     | `auto`, `manual`, or specific: `homebrew`, `dnf`, `yum`, `apt`, `zypper` | `auto`                             |
| `--install-dir <d>` | Manual install location                                                  | `~/.local/lib/radp-bash-framework` |
| `--bin-dir <d>`     | Symlink location                                                         | `~/.local/bin`                     |

Environment variables (`RADP_BF_REF`, `RADP_BF_VERSION`, `RADP_BF_INSTALL_MODE`, `RADP_BF_INSTALL_DIR`,
`RADP_BF_BIN_DIR`) are also supported as fallbacks.

When `--ref` is used and a package-manager version is already installed, the script automatically removes it first to
avoid conflicts.

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

## Uninstalling

### Uninstall Script (Recommended)

```shell
bash uninstall.sh
bash uninstall.sh --yes # Skip confirmation
```

The script auto-detects both package-manager and manual installations and removes them.

### Homebrew

```shell
brew uninstall radp-bash-framework
```

### DNF

```shell
sudo dnf remove radp-bash-framework
```

### Manual

```shell
rm -rf ~/.local/lib/radp-bash-framework
rm -f ~/.local/bin/radp-bf ~/.local/bin/radp-bash-framework
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

## Upgrade CLI Projects

After upgrading the framework, you can also upgrade your CLI projects' scaffold files:

```shell
# Preview changes
radp-bf upgrade --dry-run

# Apply changes
radp-bf upgrade

# Upgrade specific project
radp-bf upgrade ./myproject

# Verbose output for debugging
radp-bf -v upgrade .
radp-bf --debug upgrade .
```

The upgrade command:
- Tracks scaffold version in `.radp-cli/version`
- Detects user modifications via checksums in `.radp-cli/checksums/`
- Skips modified files unless `--force` is specified

See [CLI Development Guide](cli-development.md#upgrading-projects) for details.

## radp-bf Global Options

The `radp-bf` CLI supports global options that work with any command:

| Option          | Description                          |
|-----------------|--------------------------------------|
| `-v, --verbose` | Enable verbose output (info logs)    |
| `--debug`       | Enable debug output (debug logs)     |
| `-h, --help`    | Show help                            |

Example:

```shell
radp-bf -v new myapp           # Create project with verbose output
radp-bf --debug upgrade .      # Upgrade with debug logging
```

## radp-bf Shell Completion

Shell completion is **automatically installed** with all installation methods (Homebrew, dnf, apt, install.sh).

After installation, restart your shell or run `source ~/.bashrc` / `source ~/.zshrc`.

### Manual Installation

If you need to manually regenerate or install completions:

```shell
# Bash
radp-bf completion bash > ~/.local/share/bash-completion/completions/radp-bf

# Zsh
mkdir -p ~/.zfunc
radp-bf completion zsh > ~/.zfunc/_radp-bf

# For zsh, ensure fpath is configured in ~/.zshrc:
#   fpath=(~/.zfunc $fpath)
#   autoload -Uz compinit && compinit
```
