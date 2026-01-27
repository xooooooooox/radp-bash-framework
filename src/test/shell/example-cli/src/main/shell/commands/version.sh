#!/usr/bin/env bash
# @cmd
# @desc Show version information

cmd_version() {
    # Version is loaded from src/main/shell/vars/constants.sh
    echo "example-cli ${gr_example_cli_version:-v0.1.0}"
}
