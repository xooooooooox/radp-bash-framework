#!/usr/bin/env bash
# toolkit module: os/07_cron.sh

#######################################
# Add or update crontab from a file
# Merges contents of a crontab file into user's crontab
# Arguments:
#   1 - user: User to update crontab for
#   2 - crontab_file: Path to crontab file to merge
# Globals:
#   gr_sudo - sudo command prefix
# Returns:
#   0 - Success
#   1 - Failure
# Examples:
#   radp_os_crontab_add "root" "/path/to/crontab"
#######################################
radp_os_crontab_add() {
  local user="${1:?'User required'}"
  local crontab_file="${2:?'Crontab file required'}"

  if [[ ! -f "$crontab_file" ]]; then
    radp_log_error "Crontab file not found: $crontab_file"
    return 1
  fi

  local temp_file
  temp_file=$(mktemp)

  # Get current crontab (suppress "no crontab for user" error)
  $gr_sudo crontab -u "$user" -l 2>/dev/null > "$temp_file" || true

  # Append new entries
  cat "$crontab_file" >> "$temp_file"

  # Install merged crontab
  $gr_sudo crontab -u "$user" "$temp_file" || {
    rm -f "$temp_file"
    radp_log_error "Failed to update crontab for user: $user"
    return 1
  }

  rm -f "$temp_file"
  radp_log_info "Crontab updated for user: $user"
  return 0
}

#######################################
# Create or update crontab from content string
# Replaces or adds crontab entries for a user
# Arguments:
#   1 - user: User to update crontab for
#   2 - content: Crontab content (multiline string)
# Globals:
#   gr_sudo - sudo command prefix
# Returns:
#   0 - Success
#   1 - Failure
# Examples:
#   radp_os_create_or_update_crontab "vagrant" "$crontab_content"
#######################################
radp_os_create_or_update_crontab() {
  local user="${1:?'User required'}"
  local content="${2:?'Content required'}"

  local temp_file
  temp_file=$(mktemp)

  # Write content to temp file
  echo "$content" > "$temp_file"

  # Install crontab
  $gr_sudo crontab -u "$user" "$temp_file" || {
    rm -f "$temp_file"
    radp_log_error "Failed to create/update crontab for user: $user"
    return 1
  }

  rm -f "$temp_file"
  radp_log_info "Crontab created/updated for user: $user"
  return 0
}

#######################################
# Remove crontab entries matching pattern
# Removes lines from user's crontab that match the pattern
# Arguments:
#   1 - user: User to update crontab for
#   2 - pattern: Grep pattern to match lines to remove
# Globals:
#   gr_sudo - sudo command prefix
# Returns:
#   0 - Success
#   1 - Failure
# Examples:
#   radp_os_crontab_remove "root" "backup.sh"
#   radp_os_crontab_remove "vagrant" "gitlab"
#######################################
radp_os_crontab_remove() {
  local user="${1:?'User required'}"
  local pattern="${2:?'Pattern required'}"

  local temp_file
  temp_file=$(mktemp)

  # Get current crontab and filter out matching lines
  $gr_sudo crontab -u "$user" -l 2>/dev/null | grep -v "$pattern" > "$temp_file" || true

  # Install filtered crontab
  if [[ -s "$temp_file" ]]; then
    $gr_sudo crontab -u "$user" "$temp_file" || {
      rm -f "$temp_file"
      radp_log_error "Failed to update crontab for user: $user"
      return 1
    }
  else
    # No entries left, remove crontab entirely
    $gr_sudo crontab -u "$user" -r 2>/dev/null || true
  fi

  rm -f "$temp_file"
  radp_log_info "Crontab entries matching '$pattern' removed for user: $user"
  return 0
}

#######################################
# List user's crontab entries
# Arguments:
#   1 - user: User to list crontab for (optional, defaults to current user)
# Returns:
#   0 - Success
#   1 - Failure or no crontab
# Outputs:
#   Crontab contents to stdout
#######################################
radp_os_crontab_list() {
  local user="${1:-$(whoami)}"

  if [[ "$user" == "$(whoami)" ]]; then
    crontab -l 2>/dev/null || {
      radp_log_debug "No crontab for current user"
      return 1
    }
  else
    $gr_sudo crontab -u "$user" -l 2>/dev/null || {
      radp_log_debug "No crontab for user: $user"
      return 1
    }
  fi
}
