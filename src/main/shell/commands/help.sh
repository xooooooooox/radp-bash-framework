#!/usr/bin/env bash
# @cmd
# @desc Show help information

cmd_help() {
  cat <<'EOF'
radp-bf - radp-bash-framework CLI

Usage:
  radp-bf [options] <command> [args...]

Commands:
  new <name> [dir]      Create a new CLI project
  upgrade [dir] [opts]  Upgrade existing project to latest scaffold
  path <name>           Print framework path (init|launcher|root)
  resolve-root <path>   Resolve project root from script path
  completion <shell>    Generate shell completion script
  self-update [opts]    Update radp-bf (portable only)
  version               Show version
  help                  Show this help

Global Options:
  -q, --quiet           Quiet mode (no output)
  -v, --verbose         Verbose output (info logs)
  --debug               Debug output (debug logs)
  --config              Show configuration
  --config --all        Show configuration with extensions
  --config --json       Show configuration in JSON format

Examples:
  radp-bf new my-cli
  radp-bf new my-cli ~/projects
  radp-bf upgrade --dry-run
  radp-bf -v upgrade .
  radp-bf path launcher
  source "$(radp-bf path launcher)" "$@"
EOF
}
