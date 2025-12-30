#!/usr/bin/env bash
# TODO v1.0-2025/12/31: del

set -euo pipefail

__fail() {
  echo "[TEST][FAIL] $*" >&2
  exit 1
}

__assert_eq() {
  local expected=${1?}
  local actual=${2?}
  local msg=${3:-}
  if [[ "$expected" != "$actual" ]]; then
    __fail "assert_eq failed. expected='$expected' actual='$actual' ${msg:+($msg)}"
  fi
}

__assert_contains() {
  local haystack=${1?}
  local needle=${2?}
  local msg=${3:-}
  if [[ "$haystack" != *"$needle"* ]]; then
    __fail "assert_contains failed. needle='$needle' ${msg:+($msg)}\n---haystack---\n$haystack\n--------------"
  fi
}

__repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd
}

__run_case() {
  # usage: __run_case <bash_script_string>
  local script=${1:?}
  if [[ "${RADP_TEST_TRACE:-0}" == "1" ]]; then
    bash -x -c "$script"
  else
    bash -c "$script"
  fi
}

__run_case_checked() {
  # usage: __run_case_checked <out_var_name> <bash_script_string>
  local -n __nr_out__=${1:?}
  local script=${2:?}

  set +e
  __nr_out__=$(__run_case "$script" 2>&1)
  local rc=$?
  set -e

  return "$rc"
}

__test_merge_priority_and_forbidden_override() {
  local repo_root auto_script fw_dir user_dir
  repo_root=$(__repo_root)
  auto_script="$repo_root/src/main/shell/framework/context/vars/configurable/auto_configurable.sh"

  fw_dir=$(mktemp -d)
  user_dir=$(mktemp -d)
  trap 'rm -rf "$fw_dir" "$user_dir"' RETURN

  cat >"$fw_dir/framework_config.yaml" <<'YAML'
radp:
  env: prod
  framework:
    config:
      path: /tmp/fwpath
      filename: framework_config.yaml
  user:
    config:
      automap: false
      path: ${radp.framework.config.path}/../config
      filename: config.yaml
  log:
    level: warn
YAML

  cat >"$user_dir/config.yaml" <<'YAML'
radp:
  env: dev
  framework:
    config:
      path: /tmp/should_not_take
  log:
    level: error
YAML

  local out
  __run_case_checked out "
    set -e
    export gr_fw_root_path=\"$repo_root/src/main/shell/framework\"
    export GX_RADP_FRAMEWORK_CONFIG_PATH=\"$fw_dir\"
    export GX_RADP_FRAMEWORK_CONFIG_FILENAME='framework_config.yaml'
    export GX_RADP_USER_CONFIG_PATH=\"$user_dir\"
    export GX_RADP_USER_CONFIG_FILENAME='config.yaml'
    # 触发初始化
    source \"$auto_script\"
    echo \"gr_radp_env=\$gr_radp_env\"
    echo \"gr_radp_log_level=\$gr_radp_log_level\"
    echo \"YAML_RADP_FRAMEWORK_CONFIG_PATH=\$YAML_RADP_FRAMEWORK_CONFIG_PATH\"
  " || __fail "case failed:\n$out"

  __assert_contains "$out" "gr_radp_env=dev" "user should override framework"
  __assert_contains "$out" "gr_radp_log_level=error" "user should override framework"
  __assert_contains "$out" "YAML_RADP_FRAMEWORK_CONFIG_PATH=/tmp/fwpath" "user override of radp.framework.* should be ignored"
  __assert_contains "$out" "not allowed to be overridden" "should warn for forbidden override"
}

__test_env_overrides_yaml() {
  local repo_root auto_script fw_dir user_dir
  repo_root=$(__repo_root)
  auto_script="$repo_root/src/main/shell/framework/context/vars/configurable/auto_configurable.sh"

  fw_dir=$(mktemp -d)
  user_dir=$(mktemp -d)
  trap 'rm -rf "$fw_dir" "$user_dir"' RETURN

  cat >"$fw_dir/framework_config.yaml" <<'YAML'
radp:
  env: prod
YAML

  cat >"$user_dir/config.yaml" <<'YAML'
radp:
  env: dev
YAML

  local out
  __run_case_checked out "
    set -e
    export gr_fw_root_path=\"$repo_root/src/main/shell/framework\"
    export GX_RADP_FRAMEWORK_CONFIG_PATH=\"$fw_dir\"
    export GX_RADP_FRAMEWORK_CONFIG_FILENAME='framework_config.yaml'
    export GX_RADP_USER_CONFIG_PATH=\"$user_dir\"
    export GX_RADP_USER_CONFIG_FILENAME='config.yaml'
    export GX_RADP_ENV='staging'
    source \"$auto_script\"
    echo \"gr_radp_env=\$gr_radp_env\"
  " || __fail "case failed:\n$out"

  __assert_contains "$out" "gr_radp_env=staging" "GX_* should override YAML_*"
}

__test_user_config_automap_generate_config_sh() {
  local repo_root auto_script fw_dir user_dir
  repo_root=$(__repo_root)
  auto_script="$repo_root/src/main/shell/framework/context/vars/configurable/auto_configurable.sh"

  fw_dir=$(mktemp -d)
  user_dir=$(mktemp -d)
  trap 'rm -rf "$fw_dir" "$user_dir"' RETURN

  cat >"$fw_dir/framework_config.yaml" <<'YAML'
radp:
  user:
    config:
      automap: true
      filename: config.yaml
YAML

  cat >"$user_dir/config.yaml" <<'YAML'
radp:
  user:
    config:
      automap: true
app:
  name: myapp
YAML

  local out
  __run_case_checked out "
    set -e
    export gr_fw_root_path=\"$repo_root/src/main/shell/framework\"
    export GX_RADP_FRAMEWORK_CONFIG_PATH=\"$fw_dir\"
    export GX_RADP_FRAMEWORK_CONFIG_FILENAME='framework_config.yaml'
    export GX_RADP_USER_CONFIG_PATH=\"$user_dir\"
    export GX_RADP_USER_CONFIG_FILENAME='config.yaml'
    source \"$auto_script\"
    echo \"gr_app_name=\${gr_app_name-}\"
  " || __fail "case failed:\n$out"

  [[ -f "$user_dir/config.sh" ]] || __fail "expected generated file: $user_dir/config.sh"
  __assert_contains "$(cat "$user_dir/config.sh")" "declare -gr gr_app_name" "generated config.sh should include mapping for app.name"
  __assert_contains "$out" "gr_app_name=myapp" "generated config.sh should be sourced and gr_app_name should be set"
}

__test_user_config_automap_disabled_no_generation() {
  local repo_root auto_script fw_dir user_dir
  repo_root=$(__repo_root)
  auto_script="$repo_root/src/main/shell/framework/context/vars/configurable/auto_configurable.sh"

  fw_dir=$(mktemp -d)
  user_dir=$(mktemp -d)
  trap 'rm -rf "$fw_dir" "$user_dir"' RETURN

  cat >"$fw_dir/framework_config.yaml" <<'YAML'
radp:
  user:
    config:
      automap: false
      filename: config.yaml
YAML

  cat >"$user_dir/config.yaml" <<'YAML'
radp:
  user:
    config:
      automap: false
app:
  name: myapp
YAML

  local out
  __run_case_checked out "
    set -e
    export gr_fw_root_path=\"$repo_root/src/main/shell/framework\"
    export GX_RADP_FRAMEWORK_CONFIG_PATH=\"$fw_dir\"
    export GX_RADP_FRAMEWORK_CONFIG_FILENAME='framework_config.yaml'
    export GX_RADP_USER_CONFIG_PATH=\"$user_dir\"
    export GX_RADP_USER_CONFIG_FILENAME='config.yaml'
    source \"$auto_script\"
  " || __fail "case failed:\n$out"

  [[ ! -f "$user_dir/config.sh" ]] || __fail "config.sh should not be generated when automap=false"
}

__main() {
  if ! command -v yq >/dev/null 2>&1; then
    __fail "yq is required to run tests"
  fi

  __test_merge_priority_and_forbidden_override
  __test_env_overrides_yaml
  __test_user_config_automap_generate_config_sh
  __test_user_config_automap_disabled_no_generation
  echo "[TEST] all auto_configurable tests passed"
}

__main
