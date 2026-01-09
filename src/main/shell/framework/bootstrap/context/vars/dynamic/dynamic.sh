#!/usr/bin/env bash

declare -g gr_sudo
gr_sudo=$([ "${EUID:-$(id -u)}" -ne 0 ] && printf 'sudo' || printf '')
readonly gr_sudo

