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

### rpm

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

## Release

1. Update `gr_fw_version` in `src/main/shell/framework/bootstrap/context/vars/constants/constants.sh` (format: `vx.y.z`).
2. Push to `main`.
3. Trigger the `create-version-tag` workflow to create/push the tag.
4. Wait for tag workflows:
    - `update-homebrew-tap` updates the Homebrew formula.
    - `build-deb-package` builds and uploads the `.deb` to the GitHub Release.
5. The `update-spec-version` workflow updates `packaging/rpm/radp-bash-framework.spec` on `main` when the version changes.
