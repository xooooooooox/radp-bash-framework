#!/usr/bin/env bash
set -euo pipefail

__deb_repo_root() {
  cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd
}

__deb_read_version() {
  local repo_root=$1
  local constants_file="$repo_root/src/main/shell/framework/bootstrap/context/vars/constants/constants.sh"
  local version

  version=$(sed -n 's/^declare -gr gr_fw_version=//p' "$constants_file" | head -n 1)
  if [[ -z "$version" ]]; then
    echo "Failed to read gr_fw_version from $constants_file" >&2
    return 1
  fi
  version=${version#v}
  echo "$version"
}

__deb_prepare_package_root() {
  local repo_root=$1
  local version=$2
  local package_name=$3
  local arch=$4
  local package_root=$5

  rm -rf "$package_root"
  mkdir -p "$package_root/DEBIAN" "$package_root/usr/lib/$package_name" "$package_root/usr/bin"

  cat >"$package_root/DEBIAN/control" <<EOF
Package: $package_name
Version: $version
Section: utils
Priority: optional
Architecture: $arch
Maintainer: xooooooooox <xozoz.sos@gmail.com>
Depends: bash, coreutils
Description: Modular Bash framework with structured context.
EOF

  cp -a "$repo_root/src/main/shell/bin" "$package_root/usr/lib/$package_name/"
  cp -a "$repo_root/src/main/shell/framework" "$package_root/usr/lib/$package_name/"

  chmod 0755 "$package_root/usr/lib/$package_name/bin/radp-bf"
  find "$package_root/usr/lib/$package_name/framework" -type f -name "*.sh" -exec chmod 0755 {} \;

  ln -s "/usr/lib/$package_name/bin/radp-bf" "$package_root/usr/bin/radp-bf"
  ln -s "/usr/lib/$package_name/bin/radp-bf" "$package_root/usr/bin/radp-bash-framework"
}

__deb_build_package() {
  local repo_root=$1
  local package_name=$2
  local version=$3
  local arch=$4
  local build_root=$5

  local package_root="$build_root/${package_name}_${version}_${arch}"
  local output_root="$build_root/output"
  local output_path="$output_root/${package_name}_${version}_${arch}.deb"

  mkdir -p "$output_root"
  __deb_prepare_package_root "$repo_root" "$version" "$package_name" "$arch" "$package_root"
  dpkg-deb --build "$package_root" "$output_path" >/dev/null
  echo "$output_path"
}

__main() {
  local repo_root
  repo_root=$(__deb_repo_root)

  local package_name=${RADP_DEB_PACKAGE_NAME:-radp-bash-framework}
  local arch=${RADP_DEB_ARCH:-all}
  local build_root=${RADP_DEB_BUILD_ROOT:-"$repo_root/packaging/deb/build"}
  local version=${RADP_DEB_VERSION:-}

  if [[ -z "$version" ]]; then
    version=$(__deb_read_version "$repo_root")
  fi

  __deb_build_package "$repo_root" "$package_name" "$version" "$arch" "$build_root"
}

__main "$@"
