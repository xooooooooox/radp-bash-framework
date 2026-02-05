#!/usr/bin/env bash
# toolkit module: os/10_user.sh
# User and group management functions

#######################################
# Check if a user belongs to a specific group
# Arguments:
#   1 - user: Username to check
#   2 - group: Group name to check membership in
# Returns:
#   0 - User is in the group
#   1 - User is not in the group or error
#######################################
radp_os_user_in_group() {
  local user="${1:?'Username required'}"
  local group="${2:?'Group name required'}"

  # Check if group exists
  if ! getent group "$group" &>/dev/null; then
    radp_log_debug "Group '$group' does not exist"
    return 1
  fi

  # Check if user is in the group
  if getent group "$group" | grep -qE "(:|,)${user}(,|$)"; then
    return 0
  fi

  # Also check primary group
  local user_primary_group
  user_primary_group=$(id -gn "$user" 2>/dev/null)
  if [[ "$user_primary_group" == "$group" ]]; then
    return 0
  fi

  return 1
}

#######################################
# Ensure a group exists, creating it if necessary
# Arguments:
#   1 - group: Group name to ensure exists
# Returns:
#   0 - Group exists or was created
#   1 - Failed to create group
#######################################
radp_os_ensure_group() {
  local group="${1:?'Group name required'}"

  if getent group "$group" &>/dev/null; then
    radp_log_debug "Group '$group' already exists"
    return 0
  fi

  radp_log_info "Creating group '$group'..."
  radp_exec_sudo "Create group '$group'" groupadd "$group" || {
    radp_log_error "Failed to create group '$group'"
    return 1
  }

  radp_log_info "Group '$group' created"
  return 0
}

#######################################
# Add a user to a group
# Arguments:
#   1 - user: Username to add
#   2 - group: Group name to add user to
# Returns:
#   0 - User added or already in group
#   1 - Failed to add user
#######################################
radp_os_user_add_to_group() {
  local user="${1:?'Username required'}"
  local group="${2:?'Group name required'}"

  # Check if user exists
  if ! id "$user" &>/dev/null; then
    radp_log_error "User '$user' does not exist"
    return 1
  fi

  # Check if already in group
  if radp_os_user_in_group "$user" "$group"; then
    radp_log_info "User '$user' is already in group '$group'"
    return 0
  fi

  # Ensure group exists
  radp_os_ensure_group "$group" || return 1

  # Add user to group
  radp_log_info "Adding user '$user' to group '$group'..."
  radp_exec_sudo "Add user '$user' to group '$group'" usermod -aG "$group" "$user" || {
    radp_log_error "Failed to add user '$user' to group '$group'"
    return 1
  }

  radp_log_info "User '$user' added to group '$group'"
  radp_log_warn "User needs to log out and back in for group membership to take effect"
  return 0
}

#######################################
# Remove a user from a group
# Arguments:
#   1 - user: Username to remove
#   2 - group: Group name to remove user from
# Returns:
#   0 - User removed or not in group
#   1 - Failed to remove user
#######################################
radp_os_user_remove_from_group() {
  local user="${1:?'Username required'}"
  local group="${2:?'Group name required'}"

  # Check if user is in group
  if ! radp_os_user_in_group "$user" "$group"; then
    radp_log_info "User '$user' is not in group '$group'"
    return 0
  fi

  radp_log_info "Removing user '$user' from group '$group'..."
  radp_exec_sudo "Remove user '$user' from group '$group'" gpasswd -d "$user" "$group" || {
    radp_log_error "Failed to remove user '$user' from group '$group'"
    return 1
  }

  radp_log_info "User '$user' removed from group '$group'"
  return 0
}

#######################################
# Get current username
# Returns:
#   Prints the current username
#######################################
radp_os_get_current_user() {
  echo "${USER:-$(whoami)}"
}
