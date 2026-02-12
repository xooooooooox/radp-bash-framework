#!/usr/bin/env bash
# @cmd
# @desc [DEPRECATED] Use 'upgrade' instead
# @meta passthrough

cmd_self_update() {
  radp_log_warn "'self-update' is deprecated. Use '$(basename "$0") upgrade' instead."
  radp_cli_upgrade_self "$@"
}
