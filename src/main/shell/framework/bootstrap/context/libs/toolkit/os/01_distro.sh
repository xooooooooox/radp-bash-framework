#!/usr/bin/env bash
# toolkit module: os/01_distro.sh

#######################################
# Get distro architecture.
# Globals:
#   gr_distro_arch
# Outputs:
#   Prints distro architecture
# Returns:
#   0 - Success
#######################################
radp_os_get_distro_arch() {
  if [[ -n "${gr_distro_arch:-}" ]]; then
    echo "$gr_distro_arch"
    return 0
  fi
  local distro_arch
  IFS=':' read -r distro_arch _ _ _ _ _ < <(__fw_os_get_distro_info)
  echo "$distro_arch"
}

#######################################
# Get distro OS kernel name.
# Globals:
#   gr_distro_os
# Outputs:
#   Prints distro OS name
# Returns:
#   0 - Success
#######################################
radp_os_get_distro_os() {
  if [[ -n "${gr_distro_os:-}" ]]; then
    echo "$gr_distro_os"
    return 0
  fi
  local distro_os
  IFS=':' read -r _ distro_os _ _ _ _ < <(__fw_os_get_distro_info)
  echo "$distro_os"
}

#######################################
# Get distro ID.
# Globals:
#   gr_distro_id
# Outputs:
#   Prints distro ID
# Returns:
#   0 - Success
#######################################
radp_os_get_distro_id() {
  if [[ -n "${gr_distro_id:-}" ]]; then
    echo "$gr_distro_id"
    return 0
  fi
  local distro_id
  IFS=':' read -r _ _ distro_id _ _ _ < <(__fw_os_get_distro_info)
  echo "$distro_id"
}

#######################################
# Get distro name.
# Globals:
#   gr_distro_name
# Outputs:
#   Prints distro name
# Returns:
#   0 - Success
#######################################
radp_os_get_distro_name() {
  if [[ -n "${gr_distro_name:-}" ]]; then
    echo "$gr_distro_name"
    return 0
  fi
  local distro_name
  IFS=':' read -r _ _ _ distro_name _ _ < <(__fw_os_get_distro_info)
  echo "$distro_name"
}

#######################################
# Get distro version.
# Globals:
#   gr_distro_version
# Outputs:
#   Prints distro version
# Returns:
#   0 - Success
#######################################
radp_os_get_distro_version() {
  if [[ -n "${gr_distro_version:-}" ]]; then
    echo "$gr_distro_version"
    return 0
  fi
  local distro_version
  IFS=':' read -r _ _ _ _ distro_version _ < <(__fw_os_get_distro_info)
  echo "$distro_version"
}

#######################################
# Get package manager for current distro.
# Globals:
#   gr_distro_pm
# Outputs:
#   Prints package manager name
# Returns:
#   0 - Success
#######################################
radp_os_get_distro_pm() {
  if [[ -n "${gr_distro_pm:-}" ]]; then
    echo "$gr_distro_pm"
    return 0
  fi
  local distro_pm
  IFS=':' read -r _ _ _ _ _ distro_pm < <(__fw_os_get_distro_info)
  echo "$distro_pm"
}

#######################################
# Check if a package is installed for a given package manager.
# Globals:
#   None
# Arguments:
#   1 - pm: package manager name
#   2 - pkg: package name
# Returns:
#   0 - installed
#   1 - not installed or unsupported pm
#######################################
radp_os_is_pkg_installed() {
  local pm=${1:?}
  local pkg="${2:-}"

  case "$pm" in
  yum | dnf)
    rpm -q "$pkg" >/dev/null 2>&1
    ;;
  apt | apt-get)
    dpkg -s "$pkg" >/dev/null 2>&1
    ;;
  brew)
    command -v brew >/dev/null 2>&1 || return 1
    brew list --formula --versions "$pkg" >/dev/null 2>&1
    ;;
  *)
    return 1
    ;;
  esac
}

#######################################
# Install packages with optional PM-specific overrides.
# Globals:
#   gr_sudo
# Arguments:
#   [packages...] - default packages
# Options:
#   --update     - update before install
#   --dry-run    - only print commands
#   --check-only - only check missing packages
#   --map <str>  - map string "pm:pkg1,pkg2;pm2:pkg3"
#   --pm <pm> <pkg...> -- - override packages for a specific pm
# Returns:
#   0 - Success or all packages already installed
#   1 - Error
#   2 - Missing packages when --check-only
#######################################
radp_os_install_pkgs() {
  local update_before_install=false
  local dry_run=false
  local check_only=false

  # default packages (cross-platform)
  local -a pkgs_default=()

  # overrides collected for current pm
  local -a pkgs_override_add=()

  # optional: mapping string
  local map_str=""

  local cur_pm
  cur_pm=$(radp_os_get_distro_pm)
  if [[ -z "$cur_pm" || "$cur_pm" == "unknown" ]]; then
    radp_log_error "Unknown package manager"
    return 1
  fi

  local -a pm_aliases=("$cur_pm")
  case "$cur_pm" in
  apt-get) pm_aliases+=("apt") ;;
  apt) pm_aliases+=("apt-get") ;;
  esac

  # parse args
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    --update)
      update_before_install=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --check-only)
      check_only=true
      shift
      ;;
    --map)
      map_str="${2:-}"
      shift 2
      ;;
    --pm)
      # --pm <pm> <pkg...> --
      local block_pm="${2:-}"
      shift 2
      local -a block_pkgs=()
      while [[ "$#" -gt 0 && "$1" != "--" ]]; do
        block_pkgs+=("$1")
        shift
      done
      [[ "${1:-}" == "--" ]] && shift

      # if block_pm matches current pm, apply
      local want_pm
      want_pm="$block_pm"
      if [[ -n "$want_pm" ]]; then
        local pm_key
        for pm_key in "${pm_aliases[@]}"; do
          if [[ "$want_pm" == "$pm_key" ]]; then
            pkgs_override_add+=("${block_pkgs[@]}")
            break
          fi
        done
      fi
      ;;
    --)
      shift
      break
      ;;
    *)
      pkgs_default+=("$1")
      shift
      ;;
    esac
  done

  # parse --map if provided: "apt:a,b;yum:x;brew:y"
  if [[ -n "$map_str" ]]; then
    local pair
    local _pairs
    IFS=';' read -ra _pairs <<<"$map_str"
    for pair in "${_pairs[@]}"; do
      local k v
      IFS=':' read -r k v <<<"$pair"
      [[ -z "$k" || -z "$v" ]] && continue
      if [[ "$k" == "$cur_pm" ]]; then
        local -a arr=()
        IFS=',' read -ra arr <<<"$v"
        pkgs_override_add+=("${arr[@]}")
      fi
    done
  fi

  # final packages = default + overrides (dedupe, keep order)
  local -a final_pkgs=()
  radp_nr_arr_merge_unique final_pkgs pkgs_default pkgs_override_add

  if [[ "${#final_pkgs[@]}" -eq 0 ]]; then
    radp_log_error "No packages specified"
    return 1
  fi

  # filter already installed
  local -a to_install=()
  for p in "${final_pkgs[@]}"; do
    if ! radp_os_is_pkg_installed "$cur_pm" "$p"; then
      to_install+=("$p")
    fi
  done

  if [[ "$check_only" == "true" ]]; then
    if [[ "${#to_install[@]}" -eq 0 ]]; then
      radp_log_info "All packages already installed: ${final_pkgs[*]}"
      return 0
    else
      radp_log_info "Missing packages: ${to_install[*]}"
      return 2
    fi
  fi

  if [[ "${#to_install[@]}" -eq 0 ]]; then
    radp_log_info "All packages already installed: ${final_pkgs[*]}"
    return 0
  fi

  # update
  if [[ "$update_before_install" == "true" ]]; then
    case "$cur_pm" in
    yum) $dry_run && radp_log_info "[dry-run] yum makecache/upgrade" || "$gr_sudo" yum makecache -y ;;
    dnf) $dry_run && radp_log_info "[dry-run] dnf makecache/upgrade" || "$gr_sudo" dnf makecache -y ;;
    apt | apt-get) $dry_run && radp_log_info "[dry-run] apt-get update" || "$gr_sudo" apt-get update ;;
    brew) $dry_run && radp_log_info "[dry-run] brew update" || "$gr_sudo" brew update ;;
    *)
      radp_log_error "Unsupported pkg manager: $cur_pm"
      return 1
      ;;
    esac
  fi

  # install
  case "$cur_pm" in
  yum)
    if [[ "$dry_run" == "true" ]]; then
      radp_log_info "[dry-run] yum install -y ${to_install[*]}"
    else
      "$gr_sudo" yum install -y "${to_install[@]}"
    fi
    ;;
  dnf)
    if [[ "$dry_run" == "true" ]]; then
      radp_log_info "[dry-run] dnf install -y ${to_install[*]}"
    else
      "$gr_sudo" dnf install -y "${to_install[@]}"
    fi
    ;;
  apt | apt-get)
    if [[ "$dry_run" == "true" ]]; then
      radp_log_info "[dry-run] apt-get install -y ${to_install[*]}"
    else
      "$gr_sudo" apt-get install -y "${to_install[@]}"
    fi
    ;;
  brew)
    if [[ "$dry_run" == "true" ]]; then
      radp_log_info "[dry-run] brew install ${to_install[*]}"
    else
      brew install "${to_install[@]}"
    fi
    ;;
  *)
    radp_log_error "Unsupported pkg manager: $cur_pm"
    return 1
    ;;
  esac
}
