#!/usr/bin/env bash
# toolkit module: io/05_yaml.sh
# Lightweight YAML parsing utilities (no external dependencies)
#
# These functions provide simple YAML parsing using only grep/sed.
# For complex YAML operations (nested structures, references, merging),
# use the yq-based functions in autoconfigure.sh instead.
#
# Limitations:
#   - Only supports simple key: value pairs (no nested objects)
#   - Only supports simple lists (- item format)
#   - Does not handle multi-line values
#   - Does not handle YAML anchors/aliases

#######################################
# Extract a scalar value from YAML content
# Parses simple "key: value" format, handles quoted values
# Arguments:
#   1 - key: The YAML key to extract
#   2 - content: YAML content (optional, reads from stdin if not provided)
# Outputs:
#   The value for the specified key (quotes stripped)
# Returns:
#   0 - Success (value found or empty)
# Examples:
#   radp_io_yaml_get_value "name" "$yaml_content"
#   radp_io_yaml_get_value "version" < config.yaml
#   echo "$yaml" | radp_io_yaml_get_value "author"
#######################################
radp_io_yaml_get_value() {
  local key="${1:?'Missing key argument'}"
  local content="${2:-$(cat)}"

  # Match "key:" at start of line (with optional leading whitespace)
  # Extract everything after "key: ", strip surrounding quotes
  echo "$content" \
    | grep -E "^[[:space:]]*${key}:" \
    | head -1 \
    | sed "s/^[[:space:]]*${key}:[[:space:]]*//" \
    | sed 's/^["'"'"']//' \
    | sed 's/["'"'"']$//'
}

#######################################
# Extract list items from YAML content
# Parses simple "- item" format from stdin
# Arguments:
#   None (reads from stdin)
# Outputs:
#   List items, one per line (leading "- " stripped)
# Returns:
#   0 - Success
# Examples:
#   radp_io_yaml_get_list < list.yaml
#   echo "$yaml_list" | radp_io_yaml_get_list
#   # Given:
#   #   - foo
#   #   - bar
#   # Returns:
#   #   foo
#   #   bar
#######################################
radp_io_yaml_get_list() {
  grep -E '^[[:space:]]*-[[:space:]]' | sed 's/^[[:space:]]*-[[:space:]]*//'
}

#######################################
# Extract a specific section from YAML content
# Returns all lines from "key:" until the next top-level key
# Useful for extracting nested content to parse further
# Arguments:
#   1 - key: The section key to extract
#   2 - content: YAML content (optional, reads from stdin if not provided)
# Outputs:
#   All lines belonging to the section (including nested content)
# Returns:
#   0 - Success
# Examples:
#   radp_io_yaml_get_section "dependencies" "$yaml_content"
#   # Given:
#   #   dependencies:
#   #     - foo
#   #     - bar
#   #   other: value
#   # Returns:
#   #   dependencies:
#   #     - foo
#   #     - bar
#######################################
radp_io_yaml_get_section() {
  local key="${1:?'Missing key argument'}"
  local content="${2:-$(cat)}"

  echo "$content" | awk -v key="$key" '
    # Match the target section header
    $0 ~ "^" key ":" {
      printing = 1
      print
      next
    }
    # Stop at next top-level key (no leading whitespace)
    printing && /^[a-zA-Z_]/ {
      printing = 0
    }
    # Print lines while in section
    printing {
      print
    }
  '
}

#######################################
# Check if a key exists in YAML content
# Arguments:
#   1 - key: The YAML key to check
#   2 - content: YAML content (optional, reads from stdin if not provided)
# Returns:
#   0 - Key exists
#   1 - Key not found
# Examples:
#   if radp_io_yaml_has_key "enabled" "$yaml_content"; then
#     echo "Key exists"
#   fi
#######################################
radp_io_yaml_has_key() {
  local key="${1:?'Missing key argument'}"
  local content="${2:-$(cat)}"

  echo "$content" | grep -qE "^[[:space:]]*${key}:"
}
