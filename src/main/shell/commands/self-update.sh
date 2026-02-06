#!/usr/bin/env bash
# @cmd
# @desc Update radp-bf to the latest version (portable installation only)
# @flag --check Only check for updates, don't download
# @flag --force Force update even if already at latest version
# @flag --full Download full version with bundled dependencies
# @example self-update
# @example self-update --check
# @example self-update --force
# @example self-update --full
# @meta passthrough

cmd_self_update() {
  radp_cli_self_update "$@"
}
