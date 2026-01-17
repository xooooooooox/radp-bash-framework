#!/usr/bin/env bash
# toolkit module: core/02_array.sh

#######################################
# Merge multiple arrays into a destination array with de-duplication.
# Globals:
#   None
# Arguments:
#   1 - dest_array_name: destination array variable name
#   2..N - src_array_name: source array variable names
# Returns:
#   0 - Success
#######################################
radp_nr_arr_merge_unique() {
  local -n __nr_dest_arr__=${1:?}
  shift

  __nr_dest_arr__=()

  local -A seen=()
  local src_name
  for src_name in "$@"; do
    [[ -z "$src_name" ]] && continue
    local -n __nr_src_arr__="$src_name"
    local item
    for item in "${__nr_src_arr__[@]}"; do
      [[ -z "$item" ]] && continue
      if [[ -z "${seen[$item]:-}" ]]; then
        __nr_dest_arr__+=("$item")
        seen[$item]=1
      fi
    done
  done
}
