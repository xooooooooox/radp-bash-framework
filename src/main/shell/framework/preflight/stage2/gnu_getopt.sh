#!/usr/bin/env bash
# Stage 2 module: GNU getopt check and installation
#
# BSD getopt (macOS default) doesn't support long options.
# This module ensures GNU getopt is available.

# GNU getopt paths on different systems
readonly __GNU_GETOPT_PATHS=(
  "/opt/homebrew/opt/gnu-getopt/bin/getopt"  # macOS Homebrew arm64
  "/usr/local/opt/gnu-getopt/bin/getopt"      # macOS Homebrew intel
  "/usr/bin/getopt"                           # Linux
  "/bin/getopt"                               # Linux (alternative)
)

#######################################
# Check if getopt is GNU getopt
# Arguments:
#   1 - getopt binary path
# Returns:
#   0 - GNU getopt
#   1 - BSD getopt or not found
#######################################
__is_gnu_getopt() {
  local getopt_bin="$1"
  [[ ! -x "$getopt_bin" ]] && return 1

  # GNU getopt --test returns exit code 4
  "$getopt_bin" --test >/dev/null 2>&1
  [[ $? -eq 4 ]]
}

#######################################
# Find GNU getopt path
# Outputs:
#   Path to GNU getopt if found
# Returns:
#   0 - found
#   1 - not found
#######################################
__find_gnu_getopt() {
  # Check known paths
  for path in "${__GNU_GETOPT_PATHS[@]}"; do
    if __is_gnu_getopt "$path"; then
      echo "$path"
      return 0
    fi
  done

  # Check default getopt
  local default_getopt
  default_getopt=$(command -v getopt 2>/dev/null)
  if [[ -n "$default_getopt" ]] && __is_gnu_getopt "$default_getopt"; then
    echo "$default_getopt"
    return 0
  fi

  return 1
}

#######################################
# Check if GNU getopt is available
# Globals:
#   gr_gnu_getopt_path - Set to GNU getopt path if found
# Returns:
#   0 - available
#   1 - not available
#######################################
__check_gnu_getopt() {
  local path
  path=$(__find_gnu_getopt)

  if [[ -n "$path" ]]; then
    gr_gnu_getopt_path="$path"
    export gr_gnu_getopt_path
    return 0
  fi

  return 1
}

#######################################
# Install GNU getopt
# Globals:
#   gr_gnu_getopt_path - Set to GNU getopt path on success
# Returns:
#   0 - success
#   1 - failed
#######################################
__install_gnu_getopt() {
  local os
  os=$(__stage2_detect_os)

  case "$os" in
    darwin)
      # macOS: install via Homebrew
      if ! command -v brew >/dev/null 2>&1; then
        __stage2_log_error "GNU getopt requires Homebrew on macOS"
        __stage2_log_error "Install Homebrew: https://brew.sh"
        __stage2_log_error "Then run: brew install gnu-getopt"
        return 1
      fi

      __stage2_log_info "Installing gnu-getopt via Homebrew..."
      if ! brew install gnu-getopt >/dev/null 2>&1; then
        __stage2_log_error "Failed to install gnu-getopt"
        return 1
      fi
      ;;

    linux)
      # Linux: install util-linux
      local pm
      pm=$(__stage2_detect_pm)

      case "$pm" in
        apt)  __stage2_install_packages util-linux ;;
        dnf)  __stage2_install_packages util-linux ;;
        yum)  __stage2_install_packages util-linux ;;
        apk)  __stage2_install_packages util-linux ;;
        *)
          __stage2_log_error "Cannot install GNU getopt: unsupported package manager"
          return 1
          ;;
      esac
      ;;

    *)
      __stage2_log_error "Cannot install GNU getopt: unsupported OS ($os)"
      return 1
      ;;
  esac

  # Find and export the path
  local path
  path=$(__find_gnu_getopt)
  if [[ -z "$path" ]]; then
    __stage2_log_error "GNU getopt installed but not found"
    return 1
  fi

  gr_gnu_getopt_path="$path"
  export gr_gnu_getopt_path
  __stage2_log_info "GNU getopt: $gr_gnu_getopt_path"
  return 0
}
