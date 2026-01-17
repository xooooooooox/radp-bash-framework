# Toolkit

## 目标与约束
- toolkit 是框架底层通用库，不承载业务逻辑，保持轻依赖、可复用。
- 拆分依据“领域职责 + 纯函数/副作用分层”
- 上层模块可依赖下层模块，禁止反向依赖。
- 函数命名可读、可检索: 看到名字就能判断行为与副作用。

## 拆分方案

> 按领域分层

`__fw_source_scripts` 会递归加载 `toolkit/` 下所有 `.sh` 文件并全局排序。为保证可预测顺序：
- 文件名必须带数字前缀（`01_xxx.sh`），避免跨目录依赖。
- 若确实有跨目录依赖，优先调整模块边界或合并到同域内。

```
toolkit/
  core/            # 纯语言/数据结构/字符串/版本
    01_vars.sh      # 变量/类型断言、nameref 安全校验
    02_array.sh     # 索引数组工具、集合去重
    03_map.sh       # 关联数组合并、复制、KV 解析
    04_string.sh    # 字符串处理、脱敏、随机密钥/密码
    05_version.sh   # 语义化版本比较
  exec/            # 命令执行/重试/重执行
    01_run.sh       # 带日志/脱敏的命令执行包装
    02_retry.sh     # 重试策略封装
    03_reexec.sh    # 重新执行当前命令行
  io/              # 文件/交互
    01_fs.sh        # 路径归一、文件追加/生成
    02_prompt.sh    # 交互式/非交互式输入、确认
    03_banner.sh    # 文本横幅生成
  net/             # 网络/地址/校验/ssh
    01_reach.sh     # 端口/主机连通性探测
    02_iface.sh     # 网卡与 IP 查询
    03_validate.sh  # IP/IP:PORT 格式校验
    04_ssh.sh       # SSH 远程执行
  os/              # OS/资源/安全/用户/cron/shell
    01_distro.sh    # 发行版探测、包管理器推断
    02_security.sh  # selinux/firewall/ssh/sudo 安全项
    03_resource.sh  # swap/CPU/RAM 检查或关闭
    04_sysctl.sh    # sysctl 读写/校验
    05_user.sh      # 用户存在性、密码、ssh home、shell
    06_shell.sh     # shell 配置、PATH 追加、bash 版本校验
    07_cron.sh      # crontab 更新/合并
  cli/             # CLI 解析/帮助/分发/自省
    01_parse.sh     # getopt 包装、通用参数解析
    02_help.sh      # usage/帮助输出
    03_introspect.sh# 子命令/函数自省与映射
    04_dispatch.sh  # 子命令调度、直连执行判定
```

## 命名规则
- 公共函数：`radp_<domain>_<verb>[_<object>]`，domain 与模块/子域一致（var/arr/map/str/ver/exec/fs/net/os/pkg/cli 等）。
- 布尔判断：`*_is_*` / `*_has_*` 或 `is_/has_` 前缀；返回 0/1。
- 有副作用的函数使用明确动词：`enable/disable/append/upsert/ensure/reset`。
- 需要 `nameref` 的函数统一 `radp_nr_` 前缀；第一个参数为变量名，不带 `$`。
- 输出走 `stdout`，错误日志用 `radp_log_error`，返回码严格表达成功/失败。
