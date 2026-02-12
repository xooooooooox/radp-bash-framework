#!/usr/bin/env bash
# @cmd
# @desc Create a new CLI project based on radp-bash-framework
# @arg name! Project name (must start with a letter, alphanumeric with hyphens/underscores)
# @arg dir Target directory (default: current directory with project name)
# @example scaffold new my-cli
# @example scaffold new my-cli ~/projects

cmd_scaffold_new() {
  local name="${1:-}"
  local dir="${2:-}"

  if [[ -z "$name" ]]; then
    radp_log_error "Project name required"
    echo "Usage: radp-bf scaffold new <project-name> [target-dir]" >&2
    return 1
  fi

  radp_cli_scaffold_new "$name" "$dir"
}
