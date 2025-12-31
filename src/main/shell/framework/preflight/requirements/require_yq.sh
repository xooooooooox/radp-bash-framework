#!/bin/sh

__fw_requirements_check_yq() {
  command -v yq >/dev/null 2>&1
}

__fw_requirements_prepare_yq() {
  if [ "$(uname)" = "Darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
      echo "Attempting to install yq via brew..."
      brew install yq
    else
      echo "Error: yq is missing and brew is not installed. Please install yq manually." >&2
      return 1
    fi
  else
    echo "Error: yq is missing. Please install it manually." >&2
    return 1
  fi
}
