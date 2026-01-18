#!/usr/bin/env bash
set -eEuo pipefail

# ---------------------------
# Validation Helper Functions
# ---------------------------

# Check if being sourced or executed
# BASH_SOURCE[0]: the current script file (helper)
# BASH_SOURCE[1]: the script that sourced the helper script
# ${0}: equal to BASH_SOURCE[1] when called and equal to '-bash' when sourced
check_if_script_is_sourced() {
  if [[ "${BASH_SOURCE[1]}" == "${0}" ]]; then
    gum style --foreground 196 "Error: This script must be sourced, not executed."
    gum style --foreground 220 "Usage: source $0"
    gum style --foreground 220 "   or:      . $0"
    exit 1
  fi
}

# Check if being executed (not sourced)
# BASH_SOURCE[0]: the current script file
# ${0}: the name of the script when executed, or shell name when sourced
check_if_script_is_executed() {
  if [[ "${BASH_SOURCE[1]}" != "${0}" ]]; then
    gum style --foreground 196 "Error: This script must be executed, not sourced."
    gum style --foreground 220 "Usage: $(basename "${BASH_SOURCE[1]}") <arguments>"
    return 1
  fi
}

# Check and validate operation type (install or remove)
get_operation() {
  if [ $# -eq 0 ]; then
    gum style --foreground 196 "✖ Error: Operation required." >&2
    echo "Usage: install or remove" >&2
    return 1
  fi

  local operation="$1"

  # Validate operation
  if [[ "$operation" != "install" && "$operation" != "remove" ]]; then
    gum style --foreground 196 "✖ Error: Invalid operation. Use 'install' or 'remove'." >&2
    return 1
  fi

  # Return the operation via echo so it can be captured
  echo "$operation"
}

# Check and validate package manager type (pacman or yay)
get_package_manager() {
  if [ $# -eq 0 ]; then
    gum style --foreground 196 "✖ Error: Package manager required." >&2
    echo "Usage: pacman or yay" >&2
    return 1
  fi

  local pkg_manager="$1"

  # Validate package manager
  if [[ "$pkg_manager" != "pacman" && "$pkg_manager" != "yay" ]]; then
    gum style --foreground 196 "✖ Error: Invalid package manager. Use 'pacman' or 'yay'." >&2
    return 1
  fi

  # Return the package manager via echo so it can be captured
  echo "$pkg_manager"
}
