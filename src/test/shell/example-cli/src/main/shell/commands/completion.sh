#!/usr/bin/env bash
# @cmd
# @desc Generate shell completion script
# @arg shell! Shell type (bash or zsh)
# @example completion bash > ~/.local/share/bash-completion/completions/example-cli
# @example completion zsh > ~/.zfunc/_example-cli

cmd_completion() {
    local shell="${1:-}"

    if [[ -z "$shell" ]]; then
        radp_log_error "Shell type required (bash or zsh)"
        return 1
    fi

    radp_cli_completion_generate "$shell"
}
