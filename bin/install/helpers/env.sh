#!/usr/bin/env bash
set -eEuo pipefail

# ---------------------------
# Environment Helper Functions
# ---------------------------

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
