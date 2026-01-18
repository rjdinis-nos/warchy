#!/usr/bin/env bash
set -eEuo pipefail

# ---------------------------
# Helper Functions
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
    return 1
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

# Check if a package is installed
is_installed() {
  local pkg="$1"
  local pkg_type="$2"
  
  if [[ "$pkg_type" == "git" ]]; then
    # For git packages, check if binary exists in PATH
    command -v "$pkg" &>/dev/null && return 0
    return 1
  else
    # For regular packages, check package managers
    pacman -Qq "$pkg" &>/dev/null && return 0
    yay -Qq "$pkg" &>/dev/null 2>&1 && return 0
    return 1
  fi
}

# Get package type from config file (git or package)
get_package_type() {
  local config_file="$1"
  
  if grep -q '^\[git\]$' "$config_file" 2>/dev/null; then
    echo "git"
  else
    echo "package"
  fi
}

# Parse package names from config file
get_package_names() {
  local config_file="$1"
  local pkg_type="$2"
  
  if [[ "$pkg_type" == "git" ]]; then
    # For git packages, extract the repo name
    local repo=$(grep '^GIT_REPO=' "$config_file" 2>/dev/null | cut -d= -f2- | sed 's|.*/||' | sed 's|\.git$||')
    echo "$repo"
  else
    # For regular packages, extract PACKAGE_NAME
    grep '^PACKAGE_NAME=' "$config_file" 2>/dev/null | cut -d= -f2- | tr ' ' '\n' | head -1
  fi
}

# Get installer type from config file
get_installer() {
  local config_file="$1"
  local pkg_type="$2"
  
  if [[ "$pkg_type" == "git" ]]; then
    echo "git"
  else
    grep '^PACKAGE_INSTALLER=' "$config_file" 2>/dev/null | cut -d= -f2-
  fi
}

# Load git package configuration from config file
load_git_package_config() {
  local config_file="$1"

  if [ ! -f "$config_file" ]; then
    gum style --foreground 196 "✖ Error: Config file not found: $config_file"
    return 1 2>/dev/null || exit 1
  fi

  # Extract git variables from [git] section
  local git_section=$(sed -n '/^\[git\]$/,/^\[/p' "$config_file" | grep -v '^\[' | grep -v '^\s*#' | grep -E '^[A-Z_]+=')
  eval "$git_section"

  # Validate mandatory variables
  if [ -z "${GIT_REPO:-}" ]; then
    gum style --foreground 196 "✖ Error: GIT_REPO not defined in $config_file"
    return 1 2>/dev/null || exit 1
  fi

  # Extract environment variables from [env] section
  local env_section=$(sed -n '/^\[env\]$/,/^\[/p' "$config_file" | grep -v '^\[' | grep -v '^\s*#')
  ENV_CONFIG=$(echo "$env_section" | awk '
    /^PATH=/ { 
      sub(/^PATH=/, ""); 
      gsub(/"/, "", $0);
      print "export PATH=\"" $0 ":$PATH\"";
      next 
    }
    /^[A-Z_]+=/ { 
      gsub(/\$XDG_DATA_HOME/, "${XDG_DATA_HOME:-$HOME/.local/share}");
      gsub(/\$XDG_CONFIG_HOME/, "${XDG_CONFIG_HOME:-$HOME/.config}");
      gsub(/\$XDG_CACHE_HOME/, "${XDG_CACHE_HOME:-$HOME/.cache}");
      gsub(/\$XDG_STATE_HOME/, "${XDG_STATE_HOME:-$HOME/.local/state}");
      print "export " $0;
      next 
    }
    { print }
  ')
  
  ENV_FILE="${ENV_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/bash/envs}"
  
  # Extract build commands
  BUILD_COMMANDS=$(sed -n '/^\[build\]$/,/^\[/p' "$config_file" 2>/dev/null | grep -v '^\[' | grep -v '^\s*#' | grep -v '^\s*$' || true)
  
  # Extract dependencies
  BUILD_DEPS=$(sed -n '/^\[dependencies\]$/,/^\[/p' "$config_file" 2>/dev/null | grep -v '^\[' | grep -v '^\s*#' | grep -E '^[A-Z_]+=' | grep 'BUILD_DEPS=' | cut -d= -f2- || true)
  TEMP_BUILD_DEPS=$(sed -n '/^\[dependencies\]$/,/^\[/p' "$config_file" 2>/dev/null | grep -v '^\[' | grep -v '^\s*#' | grep -E '^[A-Z_]+=' | grep 'TEMP_BUILD_DEPS=' | cut -d= -f2- || true)
  
  # Extract uninstall commands
  UNINSTALL_COMMANDS=$(sed -n '/^\[uninstall\]$/,/^\[/p' "$config_file" 2>/dev/null | grep -v '^\[' | grep -v '^\s*#' | grep -v '^\s*$' || true)
}

# Load package configuration from config file
load_package_config() {
  local config_file="$1"

  if [ ! -f "$config_file" ]; then
    gum style --foreground 196 "✖ Error: Config file not found: $config_file"
    return 1 2>/dev/null || exit 1
  fi

  # Extract package variables from [package] section and safely parse them
  local package_section=$(sed -n '/^\[package\]$/,/^\[/p' "$config_file" | grep -v '^\[' | grep -v '^\s*#' | grep -E '^[A-Z_]+=')
  
  # Parse PACKAGE_NAME and PACKAGE_INSTALLER without eval to avoid executing package names
  PACKAGE_NAME=$(echo "$package_section" | grep '^PACKAGE_NAME=' | cut -d= -f2-)
  PACKAGE_INSTALLER=$(echo "$package_section" | grep '^PACKAGE_INSTALLER=' | cut -d= -f2-)

  # Validate mandatory variables
  if [ -z "${PACKAGE_NAME:-}" ]; then
    gum style --foreground 196 "✖ Error: PACKAGE_NAME not defined in $config_file"
    return 1 2>/dev/null || exit 1
  fi

  if [ -z "${PACKAGE_INSTALLER:-}" ]; then
    gum style --foreground 196 "✖ Error: PACKAGE_INSTALLER not defined in $config_file"
    return 1 2>/dev/null || exit 1
  fi

  # Extract environment variables from [env] section and add export prefix
  local env_section=$(sed -n '/^\[env\]$/,/^\[/p' "$config_file" | grep -v '^\[' | grep -v '^\s*#')
  ENV_CONFIG=$(echo "$env_section" | awk '
    /^PATH=/ { 
      # For PATH, prepend the value to existing PATH
      sub(/^PATH=/, ""); 
      gsub(/"/, "", $0);
      print "export PATH=\"" $0 ":$PATH\"";
      next 
    }
    /^[A-Z_]+=/ { 
      # Replace XDG variables with their default fallbacks
      gsub(/\$XDG_DATA_HOME/, "${XDG_DATA_HOME:-$HOME/.local/share}");
      gsub(/\$XDG_CONFIG_HOME/, "${XDG_CONFIG_HOME:-$HOME/.config}");
      gsub(/\$XDG_CACHE_HOME/, "${XDG_CACHE_HOME:-$HOME/.cache}");
      gsub(/\$XDG_STATE_HOME/, "${XDG_STATE_HOME:-$HOME/.local/state}");
      print "export " $0;
      next 
    }
    { print }
  ')
  
  # Set default ENV_FILE if not already set
  ENV_FILE="${ENV_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/bash/envs}"
  
  # Extract pre-install commands if present
  PRE_INSTALL_COMMANDS=$(sed -n '/^\[pre-install\]$/,/^\[/p' "$config_file" 2>/dev/null | grep -v '^\[' | grep -v '^\s*#' | grep -v '^\s*$' || true)
  
  # Extract post-install commands if present
  POST_INSTALL_COMMANDS=$(sed -n '/^\[post-install\]$/,/^\[/p' "$config_file" 2>/dev/null | grep -v '^\[' | grep -v '^\s*#' | grep -v '^\s*$' || true)
  
  # Extract post-remove commands if present
  POST_REMOVE_COMMANDS=$(sed -n '/^\[post-remove\]$/,/^\[/p' "$config_file" 2>/dev/null | grep -v '^\[' | grep -v '^\s*#' | grep -v '^\s*$' || true)
}

# Run install commands (pre-install or post-install)
run_install_commands() {
  local command_type="$1"  # "pre-install" or "post-install"
  local package="$2"
  local commands="$3"
  
  # Check if there are commands to run
  if [ -z "$commands" ]; then
    return 0
  fi
  
  echo
  gum style --foreground 212 "→ Running ${command_type} commands for $package"
  
  # Execute commands as a complete bash script to handle multi-line structures
  set +e
  bash -c "$commands"
  cmd_exit_code=$?
  set -e
  
  if [ $cmd_exit_code -ne 0 ]; then
    gum style --foreground 220 "  ⚠ Warning: Commands failed with exit code $cmd_exit_code"
  else
    gum style --foreground 212 "✔ ${command_type^} commands completed"
  fi
  echo
}

# Remove a block of text in a file between start_marker and end_marker
remove_marked_block() {
  local env_file="$1"
  local start_marker="$2"
  local end_marker="$3"

  # Escape $ for sed usage
  local escaped_end_marker="${end_marker//$/\\$}"

  if [ -f "$env_file" ]; then
    if grep -qF "$start_marker" "$env_file" && grep -qF "$end_marker" "$env_file"; then
      sed -i "\|$start_marker|,\|$escaped_end_marker|d" "$env_file"
    fi
  else
    gum style --foreground 214 "→ Environments file $env_file does not exist"
  fi
}

# Append a block to a file idempotently
_add_env_to_file() {
  local env_file="$1"
  local env_config="$2"

  # Check if env_config is empty
  if [ -z "$env_config" ]; then
    return 0
  fi

  if [ -f "$env_file" ]; then
    # Determine start and end markers from the block
    local start_marker="$(head -n1 <<<"$env_config")"
    local end_marker="$(tail -n1 <<<"$env_config")"

    # Remove any existing block in the file
    remove_marked_block "$env_file" "$start_marker" "$end_marker"
    # Append newline if last line is not empty
    [ -s "$env_file" ] && [ "$(tail -n1 "$env_file")" != "" ] && echo >>"$env_file" || true

    # Append the new block
    echo "$env_config" >>"$env_file"

    # Append newline if the last line is not empty
    [ -s "$env_file" ] && [ "$(tail -c1 "$env_file")" != "" ] && echo >>"$env_file" || true
  else
    gum style --foreground 214 "→ Environments file $env_file does not exist"
  fi
}

_remove_env_from_file() {
  local env_file="$1"
  local env_config="$2"

  # Check if env_config is empty
  if [ -z "$env_config" ]; then
    return 0
  fi

  # Extract markers from env_config
  local start_marker="$(head -n1 <<<"$env_config")"
  local end_marker="$(tail -n1 <<<"$env_config")"

  # Remove marked block from file
  if [ -f "$env_file" ]; then
    remove_marked_block "$env_file" "$start_marker" "$end_marker"
  fi
}

_extract_path_value() {
  local path_line="$1"
  
  # Check if PATH line exists
  if [ -z "$path_line" ]; then
    return 0
  fi
  
  # Extract just the value part (between quotes, before :$PATH)
  local path_value=$(echo "$path_line" | /usr/bin/sed -E 's/^export PATH="([^"]+):.*"/\1/')
  # If no :$PATH suffix, just get the value
  if [ "$path_value" = "$path_line" ]; then
    path_value=$(echo "$path_line" | /usr/bin/sed -E 's/^export PATH="([^"]+)"/\1/')
  fi
  # Evaluate any variables in the path (temporarily disable unset variable checking)
  set +u
  path_value=$(eval echo "$path_value")
  set -u
  
  echo "$path_value"
}

_display_path_value() {
  local path_line="$1"
  
  # Check if PATH line exists
  if [ -z "$path_line" ]; then
    return 0
  fi
  
  local path_value=$(_extract_path_value "$path_line")
  
  if [ -n "$path_value" ]; then
    gum style --foreground 245 "→ Environment path to update:"
    echo "$(gum style --foreground 212 "   PATH")$(gum style --foreground 245 ": $path_value")"
  fi
}

_display_vars() {
  local env_vars="$1"
  
  # Check if env_vars exists
  if [ -z "$env_vars" ]; then
    return 0
  fi
  
  # Extract variable names for display
  local var_names=$(grep -oP 'export \K\w+' <<<"$env_vars" | tr '\n' ' ')
  
  # Display the variables
  if [ -n "$var_names" ]; then
    gum style --foreground 245 "→ Environment variables to update:"
    warchy-list-env-vars $var_names
  fi
}

_add_to_path() {
  local new_path="$1"

  # Check if PATH line exists
  if [ -z "$new_path" ]; then
    return 0
  fi

  # Export PATH modification
  eval "$new_path"

  # Display the PATH changes
  _display_path_value "$new_path"
}

_add_vars_to_session() {
  local new_vars="$1"
  
  # Check if new_vars exists
  if [ -z "$new_vars" ]; then
    return 0
  fi
  
  # Export the new variables to the current session
  eval "$new_vars"

  # Display the exported variables
  _display_vars "$new_vars"
}

_remove_vars_from_session() {
  local removed_vars="$1"
  
  # Check if removed_vars exists
  if [ -z "$removed_vars" ]; then
    return 0
  fi
  
  # Display the variables
  _display_vars "$removed_vars"
  
  # Extract variable names and unset them
  local var_names=$(grep -oP 'export \K\w+' <<<"$removed_vars" | tr '\n' ' ')
  if [ -n "$var_names" ]; then
    local -a vars=($var_names)
    for var in "${vars[@]}"; do
      unset "$var" 2>/dev/null || true
    done
  fi
}

_remove_from_path() {
  local removed_path="$1"
  
  # Check if PATH line exists
  if [ -z "$removed_path" ]; then
    return 0
  fi

  _display_path_value "$removed_path"
  
  local path_value=$(_extract_path_value "$removed_path")
  
  # Remove this value from PATH if it exists
  if [[ -n "$path_value" ]] && [[ ":$PATH:" == *":$path_value:"* ]]; then
    PATH="${PATH//:$path_value/}"
    PATH="${PATH//$path_value:/}"
    PATH="${PATH//$path_value/}"
    export PATH
  fi
}

install_env_config() {
  local env_file="$1"
  local env_config="$2"
  
  local new_vars=$(grep 'export ' <<<"$env_config" | grep -v 'export PATH=')
  local new_path=$(grep 'export PATH=' <<<"$env_config")
  
  # Only process and show messages if there are variables to configure
  if [ -n "$new_vars" ] || [ -n "$new_path" ]; then
    echo
    _add_vars_to_session "$new_vars"
    _add_to_path "$new_path"
    _add_env_to_file "$env_file" "$env_config"
    gum style --foreground 212 "✔ Environment variables added to file and exported to session"
    echo
  fi
}

remove_env_config() {
  local env_file="$1"
  local env_config="$2"
  
  local removed_vars=$(grep 'export ' <<<"$env_config" | grep -v 'export PATH=')
  local removed_path=$(grep 'export PATH=' <<<"$env_config")
  
  # Only process and show messages if there are variables to remove
  if [ -n "$removed_vars" ] || [ -n "$removed_path" ]; then
    echo
    _remove_from_path "$removed_path"
    _remove_vars_from_session "$removed_vars"
    _remove_env_from_file "$env_file" "$env_config"
    gum style --foreground 212 "✔ Environment variables removed from file and unset from session"
    echo
  fi
}