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
  --show-config         Show configuration
  --show-config --all   Show configuration with extensions
  --show-config --json  Show configuration in JSON format

Examples:
  radp-bf new my-cli                    # Create new CLI project
  radp-bf new my-cli ~/projects         # Create in specific directory
  radp-bf upgrade                       # Upgrade current project
  radp-bf upgrade --dry-run             # Preview upgrade changes
  radp-bf upgrade globals               # Add _globals.sh to project
  radp-bf upgrade workflows             # Update CI/CD workflows
  radp-bf --show-config                 # Show configuration
  radp-bf completion bash               # Generate bash completion
  source "$(radp-bf path launcher)" "$@"  # Entry script pattern
EOF
}
