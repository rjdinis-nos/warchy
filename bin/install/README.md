# Warchy Package Management System

This directory contains the core package management tools for Warchy. For detailed information on creating and configuring packages, see [Configuration File Documentation](../../config/warchy/install/README.md).

## Overview

The package management system provides a unified, configuration-based approach to installing and managing software. This refactoring (January 2026) eliminated 20+ duplicate scripts and centralized all package management logic into reusable helper functions.

## Architecture

### Core Components

1. **`warchy-pkg`** - Direct package installer/remover
   - Handles pacman and yay package operations
   - Categorizes packages (to install, already installed, not found)
   - Provides clear status feedback
   - Must be executed (not sourced)

2. **`warchy-pkg-manager`** - Configuration-based package manager
   - Processes `.conf` files from `~/.config/warchy/install/`
   - Handles both regular and git-based packages
   - Manages environment variables (export to session + save to file)
   - Executes pre/post install/remove hooks
   - Must be sourced (to export variables to current shell)

3. **`warchy-install-helpers.sh`** - Shared helper functions loader
   - Sources all modular helper files for backward compatibility
   - `helpers/validation.sh` - Input validation and script execution mode checks
     - `check_if_script_is_sourced` / `check_if_script_is_executed`
     - `get_operation` / `get_package_manager`
   - `helpers/package.sh` - Package management, version checking, config parsing
     - `is_installed` / `get_package_type` / `get_package_names`
     - `check_git_package_version` - Version comparison for git packages
     - `load_git_package_config` / `load_package_config`
     - `run_install_commands`
   - `helpers/env.sh` - Environment variable management
     - `install_env_config` / `remove_env_config`
     - Internal functions for PATH and variable manipulation

## Quick Start

### Install a Package

```bash
# Interactive package browser
warchy-packages  # or Alt+P

# Command line
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install docker
```

### Remove a Package

```bash
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" remove docker
```

**Important**: Use `source` (or `.`) to export environment variables to your current shell.

### Direct Package Operations

For simple operations without configuration:

```bash
warchy-pkg install pacman package1 package2
warchy-pkg remove yay some-aur-package
```

## Configuration Files

Package configurations are stored in `~/.config/warchy/install/` with a `.conf` extension.

**See [Configuration File Documentation](../../config/warchy/install/README.md) for:**
- Detailed configuration format and examples
- All configuration sections reference
- Best practices and troubleshooting
- Step-by-step package creation guide

### Quick Reference

**Regular package** (from repos/AUR):
```ini
[package]
PACKAGE_NAME=package-name
PACKAGE_INSTALLER=pacman  # or yay
```

**Git package** (built from source):
```ini
[git]
GIT_REPO=https://github.com/user/repo.git

[dependencies]
TEMP_BUILD_DEPS=go cmake  # Removed after build
BUILD_DEPS=base-devel      # Kept permanently

[version]
mytool --version 2>&1 | grep -oP 'v\K[\d.]+' | head -1

[build]
make
sudo make install
```

For complete documentation, see [config/warchy/install/README.md](../../config/warchy/install/README.md).

## Environment Variable Management

Environment variables are handled in two ways:
1. **Current Session**: Exported to your current shell (requires sourcing)
2. **Persistent Storage**: Saved to `~/.config/bash/envs`

For details on configuring environment variables, see [Configuration Documentation](../../config/warchy/install/README.md#env-section).

## Available Packages

Current package configurations in Warchy:

| Package | Type | Description |
|---------|------|-------------|
| `docker` | pacman | Docker, Docker Compose, Buildx, LazyDocker |
| `gcloud` | yay | Google Cloud SDK |
| `go` | yay | Go programming language |
| `npm` | pacman | Node.js package manager |
| `opencode` | yay | VS Code for the web (code-server) |
| `pnpm` | pacman | Fast, disk space efficient package manager |
| `posting` | yay | Modern HTTP client TUI |
| `rust` | pacman | Rust programming language toolchain |
| `vhdm` | git | VHD management for WSL |
| `yay` | git | AUR helper for Arch Linux |

See configuration files in [config/warchy/install/](../../config/warchy/install/).

## Helper Functions Reference

### Validation Functions

```bash
check_if_script_is_sourced()      # Ensure script is sourced (not executed)
check_if_script_is_executed()     # Ensure script is executed (not sourced)
get_operation(op)                 # Validate and return "install" or "remove"
get_package_manager(pm)           # Validate and return "pacman" or "yay"
```

### Package Query Functions

```bash
is_installed(pkg, type)                      # Check if package is installed
get_package_type(config_file)                # Return "git" or "package"
get_package_names(config_file, type)         # Extract package names
get_installer(config_file, type)             # Get installer type (pacman/yay/git)
check_git_package_version(pkg, repo, cmd)    # Compare installed vs repo version (returns 0 if should install)
```

### Configuration Loading

```bash
load_git_package_config(config_file)     # Parse git package config
load_package_config(config_file)          # Parse regular package config
```

### Environment Management

```bash
install_env_config(env_file, env_config)  # Add vars to file + export to session
remove_env_config(env_file, env_config)   # Remove vars from file + unset from session
```

### Command Execution

```bash
run_install_commands(type, package, commands)  # Execute pre/post-install commands
```

## Creating Custom Package Configurations

See the [Configuration File Documentation](../../config/warchy/install/README.md) for:
- Step-by-step package creation guide
- Complete examples for all package types
- Best practices and troubleshooting
- Configuration sections reference

Quick example:

1. Create `~/.config/warchy/install/mypackage.conf`
2. Add appropriate sections (`[package]` or `[git]`)
3. Test: `source warchy-pkg-manager install mypackage`

For details, see [Creating a New Package Configuration](../../config/warchy/install/README.md#creating-a-new-package-configuration).

## Error Handling & Troubleshooting

The package management system uses strict error handling with `set -eEuo pipefail`.

### Common Issues

**"Error: This script must be sourced, not executed"**
- Use `source` or `.` instead of executing: `source warchy-pkg-manager install docker`

**"Error: Config file not found"**
- Check: `ls ~/.config/warchy/install/mypackage.conf`

For detailed troubleshooting, see [Configuration Documentation](../../config/warchy/install/README.md#troubleshooting).

## Benefits

1. **Reduced Duplication**: Eliminated 20+ similar scripts
2. **Centralized Logic**: All operations use shared helpers
3. **Easy Extension**: Add packages via config files
4. **Consistent UX**: Same behavior across all packages
5. **Better Maintenance**: Helper changes benefit all packages
6. **Environment Integration**: Automatic shell variable export
7. **Declarative**: Behavior defined in simple INI format
8. **Modular**: Helpers organized by responsibility
9. **Version Checking**: Skip reinstallation when up-to-date
10. **Smart Dependencies**: Preserve pre-installed build tools

## Related Documentation

- **[Configuration Files](../../config/warchy/install/README.md)** - Complete configuration reference
- **[AGENT.md](../../AGENT.md)** - AI development guidelines
- **[CHANGELOG.md](../../CHANGELOG.md)** - Package manager refactoring details
- **[Root README](../../README.md)** - Project overview
