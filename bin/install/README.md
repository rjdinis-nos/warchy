# Warchy Package Management System

This directory contains the core package management system for Warchy, providing a unified, configuration-based approach to installing and managing optional software packages.

## Overview

The package management system replaced individual install/remove scripts with a declarative configuration format. This refactoring (January 2026) eliminated 20+ duplicate scripts and centralized all package management logic into reusable helper functions.

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

3. **`warchy-install-helpers.sh`** - Shared helper functions library
   - Validation functions (sourced vs executed, operation type, package manager)
   - Package query functions (is_installed, get_package_type, etc.)
   - Configuration parsing (load_git_package_config, load_package_config)
   - Environment management (install_env_config, remove_env_config)
   - Command execution (run_install_commands)

## Usage

### Interactive Package Browser

The easiest way to manage packages is through the interactive UI:

```bash
warchy-packages
```

Or use the keyboard shortcut: `Alt+P`

This displays all available packages with their installation status and allows you to install/remove them interactively.

### Command-Line Installation

**Install a package via configuration:**
```bash
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install docker
```

**Remove a package:**
```bash
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" remove docker
```

**Important**: Use `source` (or `.`) to ensure environment variables are exported to your current shell session.

### Direct Package Installation

For simple package operations without configuration:

```bash
warchy-pkg install pacman package1 package2
warchy-pkg remove yay some-aur-package
```

This approach doesn't require sourcing and is useful for one-off installations.

## Configuration File Format

Package configurations are stored in `~/.config/warchy/install/` with a `.conf` extension.

### Regular Package Configuration

For packages available in official repos or AUR:

```ini
[package]
PACKAGE_NAME=package1 package2 package3
PACKAGE_INSTALLER=pacman  # or yay

[env]
MY_VAR="value"
ANOTHER_VAR="$HOME/.local/myapp"
PATH="$HOME/.local/myapp/bin"

[pre-install]
# Optional: Commands to run before package installation
echo "Preparing for installation..."
mkdir -p "$HOME/.local/myapp"

[post-install]
# Optional: Commands to run after package installation
sudo systemctl enable --now myservice.service
echo "Installation complete!"

[post-remove]
# Optional: Cleanup commands after package removal
sudo rm -rf /etc/myapp
rm -rf "$HOME/.local/myapp"
```

### Git-Based Package Configuration

For packages built from source:

```ini
[git]
GIT_REPO=https://github.com/user/repo.git

[dependencies]
BUILD_DEPS=base-devel cmake gcc
TEMP_BUILD_DEPS=pkgconf autoconf

[build]
# Commands to build and install
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build build
sudo cmake --install build

[env]
PATH="$HOME/.local/bin"
MY_APP_HOME="$HOME/.local/myapp"

[uninstall]
# Commands to uninstall
sudo cmake --build build --target uninstall
rm -rf "$HOME/.local/myapp"
```

## Configuration Sections

### `[package]` Section (Regular Packages)

- **`PACKAGE_NAME`** - Space-separated list of packages to install
- **`PACKAGE_INSTALLER`** - Either `pacman` or `yay`

### `[git]` Section (Git Packages)

- **`GIT_REPO`** - URL of the git repository to clone

### `[dependencies]` Section (Git Packages)

- **`BUILD_DEPS`** - Permanent build dependencies (installed and kept)
- **`TEMP_BUILD_DEPS`** - Temporary dependencies (installed, then removed after build)

### `[build]` Section (Git Packages)

Commands to build and install the package. Each line is executed sequentially.

### `[env]` Section

Environment variables to export. Special handling for `PATH`:

```ini
[env]
PATH="$HOME/.local/bin"  # Prepended to $PATH
GOPATH="$HOME/go"        # Exported as-is
```

**XDG Variables**: The following variables are automatically expanded:
- `$XDG_DATA_HOME` → `${XDG_DATA_HOME:-$HOME/.local/share}`
- `$XDG_CONFIG_HOME` → `${XDG_CONFIG_HOME:-$HOME/.config}`
- `$XDG_CACHE_HOME` → `${XDG_CACHE_HOME:-$HOME/.cache}`
- `$XDG_STATE_HOME` → `${XDG_STATE_HOME:-$HOME/.local/state}`

### `[pre-install]` Section (Regular Packages)

Commands executed before package installation. Useful for:
- Creating directories
- Setting up configurations
- Checking prerequisites

### `[post-install]` Section (Regular Packages)

Commands executed after successful package installation. Common uses:
- Enabling systemd services
- Creating symlinks
- Running initialization scripts
- Setting file permissions

### `[post-remove]` Section (Regular Packages)

Cleanup commands executed after package removal:
- Removing configuration files
- Cleaning up data directories
- Disabling services

### `[uninstall]` Section (Git Packages)

Commands to uninstall git-based packages. Similar to `post-remove` but for source-built software.

## Environment Variable Management

The package manager handles environment variables in two ways:

1. **Current Session**: Variables are exported to your current shell (requires sourcing)
2. **Persistent Storage**: Variables are saved to `~/.config/bash/envs`

On install:
- Adds variables to `~/.config/bash/envs`
- Exports variables to current shell session
- PATH entries are prepended (not replaced)

On remove:
- Removes variables from `~/.config/bash/envs`
- Unsets variables from current shell session
- PATH entries are filtered out

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
is_installed(pkg, type)           # Check if package is installed
get_package_type(config_file)     # Return "git" or "package"
get_package_names(config_file, type)  # Extract package names
get_installer(config_file, type)  # Get installer type (pacman/yay/git)
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

### Example: Adding a New Package

1. Create `~/.config/warchy/install/mypackage.conf`:

```ini
[package]
PACKAGE_NAME=mypackage mypackage-docs
PACKAGE_INSTALLER=pacman

[env]
MYPACKAGE_HOME="$HOME/.local/mypackage"
PATH="$HOME/.local/mypackage/bin"

[post-install]
mkdir -p "$HOME/.local/mypackage"
mypackage init
```

2. Install the package:

```bash
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install mypackage
```

3. Test the installation:
   - Verify packages are installed: `pacman -Q mypackage`
   - Check environment variables: `echo $MYPACKAGE_HOME`
   - Confirm PATH updates: `which mypackage`

### Example: Git-Based Package

```ini
[git]
GIT_REPO=https://github.com/user/mytool.git

[dependencies]
BUILD_DEPS=base-devel
TEMP_BUILD_DEPS=autoconf automake

[build]
./autogen.sh
./configure --prefix=/usr/local
make
sudo make install

[env]
PATH="/usr/local/bin"

[uninstall]
sudo make uninstall
```

## Error Handling

The package management system uses strict error handling:

- **Bash Strict Mode**: All scripts use `set -eEuo pipefail`
- **Exit Codes**: Non-zero exit codes halt execution
- **Validation**: Input parameters are validated before processing
- **User Feedback**: Clear error messages with `gum` styling

### Common Error Messages

**"Error: This script must be sourced, not executed"**
- Solution: Use `source` or `.` instead of executing directly
- Example: `source warchy-pkg-manager install docker`

**"Error: Config file not found"**
- Solution: Ensure the config file exists in `~/.config/warchy/install/`
- Check: `ls ~/.config/warchy/install/mypackage.conf`

**"Error: PACKAGE_NAME not defined"**
- Solution: Add `PACKAGE_NAME=` line in `[package]` section

**"Error: Invalid operation"**
- Solution: Use either `install` or `remove` as the operation

## Migration from Old System

The old individual install/remove scripts have been deprecated:

| Old Script | New Method |
|------------|------------|
| `warchy-install-docker` | `source warchy-pkg-manager install docker` |
| `warchy-remove-docker` | `source warchy-pkg-manager remove docker` |
| `warchy-install-go` | `source warchy-pkg-manager install go` |
| `warchy-remove-go` | `source warchy-pkg-manager remove go` |

All old scripts have been removed and replaced with configuration files.

## Benefits of the New System

1. **Reduced Duplication**: Eliminated 20+ similar scripts
2. **Centralized Logic**: All package operations use shared helpers
3. **Easy Extension**: Add new packages by creating config files
4. **Consistent UX**: Same behavior across all packages
5. **Better Maintenance**: Changes to helpers benefit all packages
6. **Environment Integration**: Automatic shell session variable export
7. **Declarative**: Package behavior defined in simple INI format

## Development

### Testing a Configuration

```bash
# Test install
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install mypackage

# Verify environment
echo $MY_VAR
which mycommand

# Test remove
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" remove mypackage

# Verify cleanup
echo $MY_VAR  # Should be empty
```

### Debugging

Enable verbose output for troubleshooting:

```bash
set -x  # Enable bash debug mode
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install mypackage
set +x  # Disable debug mode
```

Check the configuration parsing:

```bash
# Inspect what will be installed
grep '^PACKAGE_NAME=' ~/.config/warchy/install/mypackage.conf

# Check environment variables
grep -A 10 '^\[env\]' ~/.config/warchy/install/mypackage.conf
```

## Contributing

When adding new package configurations:

1. Follow the existing format and conventions
2. Test both install and remove operations
3. Verify environment variables are properly set/unset
4. Document any special requirements or post-install steps
5. Use meaningful comments in pre/post install sections

## Related Documentation

- [AGENT.md](../../AGENT.md) - AI development guidelines
- [CHANGELOG.md](../../CHANGELOG.md) - Package manager refactoring details
- [Root README](../../README.md) - General project overview
- [Helper Functions Source](warchy-install-helpers.sh) - Implementation details
