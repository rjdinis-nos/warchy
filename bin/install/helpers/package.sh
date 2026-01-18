#!/usr/bin/env bash
set -eEuo pipefail

# ---------------------------
# Package Helper Functions
# ---------------------------

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

# Check git package version and determine if installation is needed
# Returns 0 if should install, 1 if should skip
# Sets INSTALLED_VERSION and REPO_VERSION as side effects
check_git_package_version() {
  local package="$1"
  local git_repo="$2"
  local version_check_command="${3:-}"
  
  INSTALLED_VERSION=""
  REPO_VERSION=""
  
  # If no version check command provided, always install
  if [ -z "$version_check_command" ]; then
    return 0
  fi
  
  # Get installed version
  set +e
  INSTALLED_VERSION=$(eval "$version_check_command" 2>/dev/null | head -1)
  set -e
  
  # If not installed, proceed with installation
  if [ -z "$INSTALLED_VERSION" ]; then
    return 0
  fi
  
  # Get latest version from git repository
  gum style --foreground 245 "→ Checking repository version..."
  set +e
  REPO_VERSION=$(git ls-remote --tags --refs "$git_repo" 2>/dev/null | grep -oP 'refs/tags/v?\K[\d.]+' | sort -V | tail -1)
  set -e
  
  # If couldn't fetch repo version from tags, try parsing PKGBUILD
  if [ -z "$REPO_VERSION" ]; then
    gum style --foreground 245 "→ Tags not found, checking PKGBUILD..."
    set +e
    local temp_clone="/tmp/.warchy-version-check-$$"
    if git clone --depth 1 --filter=blob:none --no-checkout "$git_repo" "$temp_clone" >/dev/null 2>&1; then
      cd "$temp_clone" && git checkout HEAD -- PKGBUILD >/dev/null 2>&1
      REPO_VERSION=$(grep -m1 '^pkgver=' PKGBUILD 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'")
      cd - >/dev/null
      rm -rf "$temp_clone"
    fi
    set -e
  fi
  
  # If still couldn't fetch repo version from tags/PKGBUILD, try commit hash
  if [ -z "$REPO_VERSION" ]; then
    gum style --foreground 245 "→ Checking latest commit hash..."
    set +e
    REPO_VERSION=$(git ls-remote "$git_repo" HEAD 2>/dev/null | awk '{print substr($1,1,7)}')
    set -e
  fi
  
  # If still couldn't fetch repo version, show warning and proceed
  if [ -z "$REPO_VERSION" ]; then
    gum style --foreground 220 "⚠ Could not check repository version, proceeding with installation"
    return 0
  fi
  
  # If installed version looks like a commit hash (alphanumeric, 7+ chars), compare with latest commit
  if [[ "$INSTALLED_VERSION" =~ ^[a-f0-9]{7,}$ ]]; then
    # Get latest commit hash for comparison
    set +e
    local latest_commit=$(git ls-remote "$git_repo" HEAD 2>/dev/null | awk '{print substr($1,1,7)}')
    set -e
    
    if [ "$INSTALLED_VERSION" = "$latest_commit" ]; then
      gum style --foreground 82 "✔ $package $INSTALLED_VERSION is already installed (up to date)"
      return 1
    else
      gum style --foreground 245 "→ Upgrading $package from $INSTALLED_VERSION to $latest_commit"
      return 0
    fi
  fi
  
  # Compare semantic versions
  if [ "$INSTALLED_VERSION" = "$REPO_VERSION" ]; then
    gum style --foreground 82 "✔ $package v$INSTALLED_VERSION is already installed (up to date)"
    return 1
  elif [ "$(printf '%s\n' "$INSTALLED_VERSION" "$REPO_VERSION" | sort -V | head -1)" = "$REPO_VERSION" ]; then
    gum style --foreground 82 "✔ $package v$INSTALLED_VERSION is already installed (newer than repository v$REPO_VERSION)"
    return 1
  else
    gum style --foreground 245 "→ Upgrading $package from v$INSTALLED_VERSION to v$REPO_VERSION"
    return 0
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
  
  # Extract version check command
  VERSION_CHECK_COMMAND=$(sed -n '/^\[version\]$/,/^\[/p' "$config_file" 2>/dev/null | grep -v '^\[' | grep -v '^\s*#' | grep -v '^\s*$' || true)
  
  # Extract dependencies
  BUILD_DEPS=$(sed -n '/^\[dependencies\]$/,/^\[/p' "$config_file" 2>/dev/null | grep -v '^\[' | grep -v '^\s*#' | grep -E '^BUILD_DEPS=' | cut -d= -f2- || true)
  TEMP_BUILD_DEPS=$(sed -n '/^\[dependencies\]$/,/^\[/p' "$config_file" 2>/dev/null | grep -v '^\[' | grep -v '^\s*#' | grep -E '^TEMP_BUILD_DEPS=' | cut -d= -f2- || true)
  
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
