# Dependency Binaries for radp-bf Portable Full Version

This directory contains information about bundled dependencies for the portable full version of radp-bash-framework.

## Dependencies

| Dependency     | Version         | Description                          |
|----------------|-----------------|--------------------------------------|
| **bash**       | 5.2.015-1.2.3-2 | Bash shell (static binary for Linux) |
| **gnu-getopt** | 2.39            | GNU getopt from util-linux           |
| **yq**         | v4.44.1         | YAML processor                       |

## Sources

### bash (Linux)

- **Source**: [robxu9/bash-static](https://github.com/robxu9/bash-static/releases)
- **Platforms**: linux-amd64, linux-arm64
- **Note**: macOS uses Homebrew bash or system bash via wrapper script

### yq

- **Source**: [mikefarah/yq](https://github.com/mikefarah/yq/releases)
- **Platforms**: All (official binaries available)

### gnu-getopt

- **Source**: util-linux package
- **Platforms**: Linux (system getopt), macOS (Homebrew gnu-getopt wrapper)
- **Note**: For Linux builds, the system getopt is bundled if building on the same architecture

## Building Dependencies Manually

### Static bash (Linux)

```bash
# Using musl for static linking
git clone https://github.com/robxu9/bash-static.git
cd bash-static
./build.sh
```

### Static gnu-getopt (Linux)

```bash
# Download util-linux
curl -LO https://github.com/util-linux/util-linux/archive/refs/tags/v2.39.tar.gz
tar xzf v2.39.tar.gz
cd util-linux-2.39

# Configure and build only getopt with static linking
./autogen.sh
./configure \
  --disable-all-programs \
  --enable-getopt \
  --enable-static \
  LDFLAGS="-static"
make getopt

# Binary will be at ./getopt
```

### yq

Pre-built binaries are available from the official releases:

```bash
# Example for linux-amd64
curl -LO https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_amd64
chmod +x yq_linux_amd64
mv yq_linux_amd64 yq
```

## Verification

All binaries should be verified against checksums in `checksums.txt` before use.

## Updating Dependencies

1. Update version numbers in `bundle-deps.sh`
2. Download new binaries and compute SHA256 checksums
3. Update `checksums.txt` with new checksums
4. Test the portable full build on all target platforms
