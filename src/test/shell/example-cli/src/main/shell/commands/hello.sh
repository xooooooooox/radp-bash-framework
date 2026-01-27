#!/usr/bin/env bash
# @cmd
# @desc Say hello (example command)
# @arg name Name to greet
# @option -u, --uppercase Convert to uppercase
# @example hello
# @example hello World
# @example hello --uppercase World

cmd_hello() {
    local name="${1:-World}"
    local message="Hello, $name!"

    if [[ "${opt_uppercase:-}" == "true" ]]; then
        message="${message^^}"
    fi

    echo "$message"
}
