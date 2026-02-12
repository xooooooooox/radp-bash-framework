#!/usr/bin/env bash
# @cmd
# @desc [DEPRECATED] Use 'upgrade' instead
# @meta passthrough
# @flag --check Only check for updates
# @flag --force Force upgrade even if at latest
# @flag -y, --yes Skip confirmation prompt
# @option --version <version> Target specific version

cmd_self_update() {
  radp_log_warn "'self-update' is deprecated. Use '$(basename "$0") upgrade' instead."
  radp_cli_upgrade_self "$@"
}
