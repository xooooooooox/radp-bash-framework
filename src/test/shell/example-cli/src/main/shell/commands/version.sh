#!/usr/bin/env bash
# @cmd
# @desc Show version information

cmd_version() {
    # Version is loaded from config/config.yaml (radp.extend.example_cli.version)
    echo "example-cli ${gr_radp_extend_example_cli_version:-v0.1.0}"
}
