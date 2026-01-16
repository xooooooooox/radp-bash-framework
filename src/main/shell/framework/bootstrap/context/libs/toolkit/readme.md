# Toolkit 拆分与命名设计

## 目标与约束
- toolkit 是框架底层通用库，不承载业务逻辑，保持轻依赖、可复用。
- 拆分依据“领域职责 + 纯函数/副作用分层”，避免 `common/utils/advanced` 这类含糊分类。
- 上层模块可依赖下层模块，禁止反向依赖。
- 函数命名可读、可检索：看到名字就能判断行为与副作用。

## 拆分方案（按领域分层）
`__fw_source_scripts` 会递归加载 `toolkit/` 下所有 `.sh` 文件并全局排序。为保证可预测顺序：
- 文件名必须带数字前缀（`01_xxx.sh`），避免跨目录依赖。
- 若确实有跨目录依赖，优先调整模块边界或合并到同域内。

```
toolkit/
  core/            # 纯语言/数据结构/字符串/版本
    01_vars.sh
    02_array.sh
    03_map.sh
    04_string.sh
    05_version.sh
  exec/            # 命令执行/重试/重执行
    01_run.sh
    02_retry.sh
    03_reexec.sh
  io/              # 文件/交互
    01_fs.sh
    02_prompt.sh
    03_banner.sh
  net/             # 网络/地址/校验/ssh
    01_reach.sh
    02_iface.sh
    03_validate.sh
    04_ssh.sh
  os/              # OS/资源/安全/用户/cron/shell
    01_distro.sh
    02_security.sh
    03_resource.sh
    04_sysctl.sh
    05_user.sh
    06_shell.sh
    07_cron.sh
  pkg/             # 包管理封装
    01_install.sh
    02_apt.sh
    03_brew.sh
  cli/             # CLI 解析/帮助/分发/自省
    01_parse.sh
    02_help.sh
    03_introspect.sh
    04_dispatch.sh
```

## 命名规则
- 公共函数：`radp_<domain>_<verb>[_<object>]`，domain 与模块/子域一致（var/arr/map/str/ver/exec/fs/net/os/pkg/cli 等）。
- 布尔判断：`*_is_*` / `*_has_*` 或 `is_/has_` 前缀；返回 0/1。
- 有副作用的函数使用明确动词：`enable/disable/append/upsert/ensure/reset`。
- 需要 `nameref` 的函数统一 `radp_nr_` 前缀；第一个参数为变量名，不带 `$`。
- 输出走 `stdout`，错误日志用 `radp_log_error`，返回码严格表达成功/失败。

## 旧函数 -> 新函数映射（建议）
### core/vars|array|map|string|version
- `radp_lang_check_var_type` -> `radp_var_require_type` (`core/01_vars.sh`)
- `radp_lang_check_if_arr_contains` -> `radp_arr_contains` (`core/02_array.sh`)
- `radp_nr_lang_add_item_to_set` -> `radp_nr_arr_add_unique` (`core/02_array.sh`)
- `radp_nr_lang_copy_from_map` -> `radp_nr_map_copy` (`core/03_map.sh`)
- `radp_nr_merge_map` -> `radp_nr_map_merge` (`core/03_map.sh`)
- `radp_nr_lang_convert_str_to_assoc_arr` -> `radp_nr_map_parse_kv` (`core/03_map.sh`)
- `radp_nr_utils_print_assoc_arr` -> `radp_nr_map_format` (`core/03_map.sh`)
- `radp_utils_desensitize_str` -> `radp_str_mask_secrets` (`core/04_string.sh`)
- `radp_utils_get_strong_random_password` -> `radp_sec_random_password` (`core/04_string.sh`)
- `radp_utils_check_version_satisfied` -> `radp_ver_is_at_least` (`core/05_version.sh`)

### exec/
- `radp_utils_run` -> `radp_exec_run` (`exec/01_run.sh`)
- `radp_utils_retry` -> `radp_exec_retry` (`exec/02_retry.sh`)
- `radp_utils_rerun_command_line` -> `radp_exec_reexec` (`exec/03_reexec.sh`)

### io/
- `radp_io_append_single_line_to_file` -> `radp_fs_append_line` (`io/01_fs.sh`)
- `radp_os_get_absolute_path` -> `radp_path_abs` (`io/01_fs.sh`)
- `radp_io_prompt_continue` -> `radp_prompt_confirm` (`io/02_prompt.sh`)
- `radp_nr_io_prompt_inputs` -> `radp_nr_prompt_read` (`io/02_prompt.sh`)
- `radp_io_output_banner_file` -> `radp_fs_write_banner` (`io/03_banner.sh`)

### net/
- `radp_net_check_ip_port_reachable` -> `radp_net_is_port_reachable` (`net/01_reach.sh`)
- `radp_net_check_hosts_reachability` -> `radp_net_are_hosts_reachable` (`net/01_reach.sh`)
- `radp_net_get_ip_by_eth` -> `radp_net_get_ip_by_iface` (`net/02_iface.sh`)
- `radp_net_get_eth_by_ip` -> `radp_net_get_iface_by_ip` (`net/02_iface.sh`)
- `radp_regex_match_format_ip_port` -> `radp_net_is_ip_port` (`net/03_validate.sh`)
- `radp_regex_match_format_ip` -> `radp_net_is_ip` (`net/03_validate.sh`)
- `radp_utils_remote_run` -> `radp_ssh_run` (`net/04_ssh.sh`)

### os/
- `radp_os_get_distro_info` -> `radp_os_detect_distro` (`os/01_distro.sh`)
- `radp_os_disable_selinux` -> `radp_os_selinux_disable` (`os/02_security.sh`)
- `radp_os_disable_firewalld` -> `radp_os_firewall_disable` (`os/02_security.sh`)
- `radp_os_check_if_ssh_password_auth` -> `radp_ssh_is_password_auth_enabled` (`os/02_security.sh`)
- `radp_os_disable_swap` -> `radp_os_swap_disable` (`os/03_resource.sh`)
- `radp_os_check_minimum_cpu_cores` -> `radp_os_require_cpu_cores` (`os/03_resource.sh`)
- `radp_os_check_minimum_ram` -> `radp_os_require_ram` (`os/03_resource.sh`)
- `radp_os_sysctl_param_check` -> `radp_os_sysctl_check_value` (`os/04_sysctl.sh`)
- `radp_os_check_user_exists` -> `radp_user_exists` (`os/05_user.sh`)
- `radp_os_reset_linux_password` -> `radp_user_password_reset` (`os/05_user.sh`)
- `radp_os_get_ssh_home` -> `radp_user_ssh_home` (`os/05_user.sh`)
- `radp_os_chsh_for_user` -> `radp_user_set_shell` (`os/05_user.sh`)
- `radp_os_append_path` -> `radp_shell_path_append` (`os/06_shell.sh`)
- `radp_os_check_bash_version` -> `radp_shell_bash_is_at_least` (`os/06_shell.sh`)
- `radp_os_create_or_update_crontab` -> `radp_cron_upsert` (`os/07_cron.sh`)
- `radp_os_enable_sudo_without_password` -> `radp_sudo_enable_nopasswd` (`os/02_security.sh`)
- `radp_os_check_if_is_sudoer` -> `radp_sudo_user_has_access` (`os/02_security.sh`)
- `radp_os_add_sudoer` -> `radp_sudo_user_grant_nopasswd` (`os/02_security.sh`)

### pkg/
- `radp_os_pkg_install` -> `radp_pkg_install` (`pkg/01_install.sh`)
- `radp_alias_apt_get` -> `radp_pkg_apt_get` (`pkg/02_apt.sh`)
- `radp_alias_brew` -> `radp_pkg_brew` (`pkg/03_brew.sh`)
- `radp_alias_source` -> `radp_shell_reload_rc` (`os/06_shell.sh`)

### cli/
- `radp_nr_cli_parse_common_options` -> `radp_nr_cli_parse_common_options` (`cli/01_parse.sh`)
- `radp_nr_cli_parser` -> `radp_nr_cli_parser` (`cli/01_parse.sh`)
- `radp_cli_print_brief_help` -> `radp_cli_print_brief_help` (`cli/02_help.sh`)
- `radp_nr_cli_print_detail_help` -> `radp_nr_cli_print_detail_help` (`cli/02_help.sh`)
- `radp_cli_print_help_of_invalid_subcmd_function` -> `radp_cli_print_invalid_subcmd_help` (`cli/02_help.sh`)
- `radp_cli_get_subcmd_by_script_file` -> `radp_cli_subcmd_from_script` (`cli/03_introspect.sh`)
- `radp_cli_get_subcmd_available_functions` -> `radp_cli_subcmd_functions` (`cli/03_introspect.sh`)
- `radp_cli_get_executor_options_processor_function_name` -> `radp_cli_subcmd_opts_processor` (`cli/03_introspect.sh`)
- `radp_cli_getexecutor_manual_file` -> `radp_cli_subcmd_manual_file` (`cli/03_introspect.sh`)
- `__framework_cli_check_if_straight_run_executor_file` -> `__fw_cli_is_direct_exec` (`cli/04_dispatch.sh`)
- `__framework_cli_run_subcmd` -> `__fw_cli_dispatch_subcmd` (`cli/04_dispatch.sh`)
- `__framework_cli_get_prog_name` -> `__fw_cli_prog_name` (`cli/04_dispatch.sh`)
