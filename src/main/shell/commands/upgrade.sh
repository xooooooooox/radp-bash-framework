#!/usr/bin/env bash
# @cmd
# @desc Upgrade radp-bf to the latest version
# @meta passthrough

cmd_upgrade() {
  radp_cli_upgrade_self "$@"
}
