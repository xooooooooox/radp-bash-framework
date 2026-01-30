#!/usr/bin/env bash
# @cmd
# @desc Show version information

# Application version
# Update this value when releasing a new version
declare -gr gr_app_version="v0.0.1"

cmd_version() {
    echo "example-cli $(radp_get_install_version "${gr_app_version}")"
}
