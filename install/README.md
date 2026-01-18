# Warchy Installation System

This directory contains the complete installation orchestration system for Warchy. The installation process is broken down into modular, sequential stages that configure an Arch Linux system from a vanilla state to a fully-configured development environment.

## Table of Contents

- [Overview](#overview)
- [Installation Flow](#installation-flow)
- [Directory Structure](#directory-structure)
- [Installation Stages](#installation-stages)
- [Environment Variables](#environment-variables)
- [Package Lists](#package-lists)
- [Logging System](#logging-system)
- [Error Handling](#error-handling)
- [Customizing Installation](#customizing-installation)
- [Testing](#testing)

## Overview

The Warchy installation system is designed with these principles:

- **Modular Design**: Each stage is a separate script with a single responsibility
- **Sequential Execution**: Stages run in a specific order with dependencies
- **Comprehensive Logging**: All operations are logged with timestamps
- **Guard Checks**: Pre-installation validation prevents incompatible installations
- **Idempotency**: Safe to re-run without causing issues
- **Configurability**: Environment variables control what gets installed

## Installation Flow

The installation process follows this sequence:

```
┌─────────────────────────────────────────────────────────────┐
│                    INSTALLATION START                        │
│                  (install/install.sh)                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STAGE 1: PRE-INSTALLATION                       │
│              (pre-install/)                                  │
│                                                              │
│  1. guard.sh           → System compatibility checks        │
│  2. show-env.sh        → Display environment variables      │
│  3. user.sh            → Validate user (not root)           │
│  4. pacman.sh          → Configure pacman                   │
│  5. first-run-mode.sh  → Detect installation mode           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│          STAGE 2: SYSTEM CONFIGURATION                       │
│          (config/)                                           │
│                                                              │
│  1. config.sh              → Copy configs & create dirs     │
│  2. scripts.sh             → Deploy utility scripts         │
│  3. systemd.sh             → Configure systemd services     │
│  4. ssh-flakiness.sh       → Fix SSH stability issues       │
│  5. fast-shutdown.sh       → Optimize shutdown time         │
│  6. usb-autosuspend.sh     → Configure USB power mgmt       │
│  7. increase-sudo-tries.sh → Increase sudo attempts         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│         STAGE 3: BASE PACKAGES (Optional)                    │
│         (packaging/)                                         │
│                                                              │
│  1. base.sh            → Install base system packages       │
│  2. localdb.sh         → Configure plocate database         │
│                                                              │
│  Installs from: warchy-base.packages                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│       STAGE 4: OPTIONAL PACKAGES (Optional)                  │
│       (packaging/ + bin/install/)                            │
│                                                              │
│  1. optional-pacman.sh     → Optional pacman packages       │
│  2. warchy-pkg-manager     → Install Go toolchain           │
│  3. warchy-pkg-manager     → Install Yay (AUR helper)       │
│  4. optional-yay.sh        → Optional AUR packages          │
│  5. warchy-pkg-manager     → Install VHDM                   │
│  6. warchy-pkg-manager     → Install Docker                 │
│  7. warchy-pkg-manager     → Install GCloud SDK             │
│                                                              │
│  Installs from:                                              │
│    - warchy-optional.packages                                │
│    - warchy-yay.packages                                     │
│    - config/warchy/install/*.conf                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STAGE 5: SETUP                                  │
│              (setup/)                                        │
│                                                              │
│  1. ssh-agent.sh       → Configure SSH agent service        │
│  2. nvim.sh            → Install LazyVim for Neovim         │
│  3. allow-reboot.sh    → Grant reboot/shutdown permissions  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│         STAGE 6: FIRST-RUN MARKER                            │
│                                                              │
│  Creates: ~/.local/state/warchy/first-run-pending            │
│  Purpose: Triggers post-install cleanup on first login       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 INSTALLATION COMPLETE                        │
│                                                              │
│  First Login Trigger:                                        │
│    → post-install/first-run.sh                               │
│       - Clean package caches                                 │
│       - Remove orphaned packages                             │
│       - Clean up temporary files                             │
│       - Display completion message                           │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
install/
├── install.sh                    # Main installation orchestrator
├── warchy-base.packages          # Base system package list
├── warchy-optional.packages      # Optional pacman packages
├── warchy-yay.packages           # Optional AUR packages
│
├── helpers/                      # Helper modules
│   └── logging.sh               # Logging functions (log_step, run_logged)
│
├── pre-install/                 # Pre-installation validation
│   ├── guard.sh                 # System compatibility checks
│   ├── show-env.sh              # Display environment variables
│   ├── user.sh                  # Validate user is not root
│   ├── pacman.sh                # Configure pacman settings
│   └── first-run-mode.sh        # Detect fresh vs re-install
│
├── config/                      # System configuration scripts
│   ├── config.sh                # Main config orchestrator
│   ├── scripts.sh               # Deploy bin/ scripts to ~/.local/bin
│   ├── systemd.sh               # Configure systemd services
│   ├── ssh-flakiness.sh         # Fix SSH stability issues
│   ├── fast-shutdown.sh         # Optimize shutdown time
│   ├── usb-autosuspend.sh       # Configure USB power management
│   └── increase-sudo-tries.sh   # Increase sudo attempt limits
│
├── packaging/                   # Package installation modules
│   ├── base.sh                  # Install base packages
│   ├── localdb.sh               # Configure plocate database
│   ├── optional-pacman.sh       # Install optional pacman packages
│   ├── optional-yay.sh          # Install optional AUR packages
│   ├── rust.sh                  # (Legacy) Rust installer
│   ├── vhdm.sh                  # (Legacy) VHDM installer
│   └── yay.sh                   # (Legacy) Yay installer
│
├── setup/                       # System setup scripts
│   ├── ssh-agent.sh             # Configure SSH agent service
│   ├── nvim.sh                  # Install LazyVim for Neovim
│   └── allow-reboot.sh          # Grant reboot/shutdown permissions
│
└── post-install/                # Post-installation tasks
    └── first-run.sh             # First login cleanup and finalization
```

## Installation Stages

### Stage 1: Pre-Installation

**Purpose**: Validate system compatibility and readiness before making any changes.

#### guard.sh - System Compatibility Checks

**What it checks**:
- ✓ Vanilla Arch Linux (not derivatives like Manjaro, Garuda, EndeavourOS, CachyOS)
- ✓ Not running as root (must be regular user with sudo)
- ✓ x86_64 architecture
- ✓ No desktop environment pre-installed (no Gnome/KDE)

**Behavior**: Each failed check offers the option to proceed anyway with a confirmation prompt.

#### show-env.sh - Environment Display

Displays all relevant environment variables:
- `WARCHY_PATH` - Installation directory
- `WARCHY_INSTALL` - Install scripts directory
- `XDG_*` - XDG base directories
- Installation flags (`WARCHY_INSTALL_BASE`, `WARCHY_INSTALL_OPTIONAL`)

#### user.sh - User Validation

Verifies the current user:
- Not root
- Has sudo privileges
- Home directory exists

#### pacman.sh - Pacman Configuration

Configures the Arch package manager:
- Copies custom `pacman.conf` with optimizations
- Sets up parallel downloads
- Configures color output
- Deploys custom mirrorlist
- Adds pacman hooks for man pages

#### first-run-mode.sh - Installation Mode Detection

Determines if this is:
- Fresh installation (first time)
- Re-installation (already configured)

Creates marker files to track installation state.

---

### Stage 2: System Configuration

**Purpose**: Configure system files, deploy user configurations, and set up services.

#### config.sh - Main Configuration Orchestrator

**Primary operations**:

1. **Create XDG directories**:
   ```bash
   ~/.config      # XDG_CONFIG_HOME
   ~/.cache       # XDG_CACHE_HOME
   ~/.local/share # XDG_DATA_HOME
   ~/.local/state # XDG_STATE_HOME
   ~/.local/bin   # User executables
   ```

2. **Deploy Warchy configurations**:
   - Copies `config/*` → `~/.config/`
   - Includes bash, dunst, foot, git, starship, tmux, vim, yazi configs

3. **Set up bashrc**:
   - Replaces `~/.bashrc` with Warchy's modular bash configuration
   - Sources configs from `~/.config/bash/`

4. **Configure WSL integration**:
   - Copies WSL-specific configs to system directories
   - Sets up tmpfiles.d and profile.d entries
   - Configures binfmt for Windows interop

5. **Deploy desktop applications**:
   - Copies `.desktop` files to `~/.local/share/applications/`
   - Creates x-terminal-emulator symlink

#### scripts.sh - Script Deployment

Deploys utility scripts from `bin/` to `~/.local/bin/`:

**Process**:
1. Creates `~/.local/bin/` directory
2. Copies all scripts from `$WARCHY_PATH/bin/` recursively
3. Preserves directory structure (apps/, install/, utils/)
4. Sets executable permissions
5. Updates PATH in current session

**Result**: All `warchy-*` commands become globally accessible.

#### systemd.sh - Systemd Service Configuration

Configures systemd services and settings:

1. **Journal configuration**:
   - Sets log size limits
   - Configures retention policies
   - Deploys to `/etc/systemd/journald.conf.d/`

2. **SSH agent service**:
   - Configures user-level SSH agent
   - Deploys to `~/.config/systemd/user/ssh-agent.service.d/`

3. **Man database service**:
   - Optimizes man page indexing
   - Deploys to `/etc/systemd/system/man-db.service.d/`

4. **Dunst notification service**:
   - Copies notification daemon service
   - Enables user-level systemd service

5. **WSL-specific services**:
   - WSL remount rshared service for Docker
   - Enables and starts WSL-specific units

#### ssh-flakiness.sh - SSH Stability Fix

Addresses common SSH connection issues in WSL:

**Changes made**:
- Modifies `/etc/ssh/sshd_config`:
  - `UseDNS no` - Disables DNS lookups
  - `GSSAPIAuthentication no` - Disables GSSAPI auth
- Improves connection speed and reliability

#### fast-shutdown.sh - Shutdown Optimization

Reduces shutdown/reboot time:

**Configuration**:
- Sets `DefaultTimeoutStopSec=5s` in systemd
- Prevents long waits for service shutdown
- Deploys to `/etc/systemd/system.conf.d/`

#### usb-autosuspend.sh - USB Power Management

Disables USB autosuspend to prevent device disconnections:

**Configuration**:
- Sets kernel parameter: `usbcore.autosuspend=-1`
- Deploys to `/etc/modprobe.d/`
- Prevents USB devices from going to sleep

#### increase-sudo-tries.sh - Sudo Attempts

Increases sudo password retry attempts:

**Configuration**:
- Sets `passwd_tries=10` in sudoers
- Reduces frustration with sudo authentication
- Deploys to `/etc/sudoers.d/`

---

### Stage 3: Base Packages

**Purpose**: Install essential system packages for a functional development environment.

#### base.sh - Base Package Installation

**Process**:
1. Reads package list from `warchy-base.packages`
2. Filters out comments and empty lines
3. Passes to `warchy-pkg` for installation
4. Uses `pacman` with `--needed` flag (skip already installed)

**Package categories**:
- **Core System**: base-devel, sudo, bash-completion
- **Editors**: vim, neovim
- **Network Tools**: curl, wget, openssh, bind, net-tools
- **CLI Tools**: bat, eza, fzf, fd, gum, htop, fastfetch
- **File Tools**: plocate, unzip, less, tree
- **Development**: git, jq, hexedit, pinentry
- **System**: tmux, libnotify, librsvg, usbutils

#### localdb.sh - File Location Database

Configures and initializes the `plocate` file database:

**Operations**:
1. Enables and starts `plocate-updatedb.timer`
2. Runs initial database update
3. Creates index of all system files

**Usage after install**: `locate filename` for fast file searches

---

### Stage 4: Optional Packages

**Purpose**: Install additional tools and development environments based on user preference.

#### optional-pacman.sh - Optional Pacman Packages

Installs enhanced CLI tools from official repos:

**Package list** (`warchy-optional.packages`):
- **Enhanced Tools**: btop, dust, dua, duf, glow, lazygit, starship
- **Development**: github-cli, gdb, cloc, lsof, python-pip, uv
- **System**: pacman-contrib, qemu-img, sox
- **Desktop**: adwaita-icon-theme, fonts, feh
- **Terminal**: xterm, foot, wl-clipboard
- **Yazi deps**: 7zip, ffmpeg, imagemagick, poppler
- **LazyVim deps**: ast-grep, luarocks

#### Configuration-Based Package Installation

Uses the new package management system for complex installations:

**Packages installed** (via `warchy-pkg-manager`):

1. **Go** (`config/warchy/install/go.conf`)
   - Installs Go language from AUR
   - Configures GOPATH, GOBIN, GOCACHE
   - Exports environment variables

2. **Yay** (`config/warchy/install/yay.conf`)
   - Builds from git source
   - AUR helper for installing AUR packages
   - Required before installing other AUR packages

3. **VHDM** (`config/warchy/install/vhdm.conf`)
   - VHD management tool for WSL
   - Builds from git source
   - Used for mounting VHD files with SSH keys

4. **Docker** (`config/warchy/install/docker.conf`)
   - Docker engine, Compose, and Buildx
   - Configures daemon with BuildKit
   - Sets up log rotation
   - Enables and starts service
   - Adds user to docker group

5. **GCloud SDK** (`config/warchy/install/gcloud.conf`)
   - Google Cloud Platform tools
   - Installs from AUR

#### optional-yay.sh - Optional AUR Packages

Installs AUR packages using yay:

**Package list** (`warchy-yay.packages`):
- **Enhanced Terminal**: xdg-terminal-exec
- **Development**: code-server (opencode)
- **Tools**: posting, snitch, python-pipx
- **Fonts**: Nerd fonts for terminals

---

### Stage 5: Setup

**Purpose**: Final system configuration and user-specific setup.

#### ssh-agent.sh - SSH Agent Service

Configures systemd user service for SSH agent:

**Operations**:
1. Copies SSH agent service configuration
2. Enables user-level systemd service
3. Starts SSH agent automatically on login
4. Exports `SSH_AUTH_SOCK` environment variable

**Result**: SSH keys automatically loaded on login

#### nvim.sh - Neovim Configuration

Installs LazyVim distribution for Neovim:

**Process**:
1. Backs up existing `~/.config/nvim` if present
2. Clones LazyVim starter configuration
3. Sets Catppuccin colorscheme as default
4. Configures lazy.nvim plugin manager

**Result**: Fully-configured Neovim IDE with LSP, treesitter, and plugins

#### allow-reboot.sh - Reboot Permissions

Grants non-root users permission to reboot/shutdown:

**Configuration**:
- Creates polkit rule allowing wheel group members to:
  - Reboot system
  - Power off system
  - Suspend system
  - Hibernate system
- No password required for these operations

**File**: `/etc/polkit-1/rules.d/50-warchy-wheel-reboot.rules`

---

### Stage 6: First-Run Marker

**Purpose**: Signal that post-installation cleanup should run on first login.

**Process**:
1. Creates directory: `~/.local/state/warchy/`
2. Creates marker file: `first-run-pending`
3. Bash init checks for this marker on login
4. If present, sources `post-install/first-run.sh`

---

### Post-Installation (First Login)

#### first-run.sh - Cleanup and Finalization

Automatically runs on first shell login after installation.

**Operations**:

1. **Clean temporary sudoers files**:
   - Removes `/etc/sudoers.d/99-warchy-installer`
   - Removes `/etc/sudoers.d/99-wslarchy-installer-reboot`

2. **Package cache cleanup**:
   - Uses `paccache -rq -k 1` (keep 1 recent version)
   - Falls back to `pacman -Sc` if paccache unavailable
   - Cleans yay cache and build directories
   - Removes `~/.cache/yay/*`

3. **Remove orphaned packages**:
   - Finds packages no longer needed as dependencies
   - Removes them with `pacman -Rns`

4. **Self-cleanup**:
   - Removes detection block from `~/.config/bash/init`
   - Deletes marker file: `first-run-pending`
   - Ensures first-run only executes once

5. **Display completion**:
   - Shows success message
   - Recommends running `warchy-user-setup`

**Result**: Clean system ready for use, one-time execution

---

## Environment Variables

The installation process respects several environment variables:

### Required Variables

Set automatically by the bootstrap installer:

| Variable | Description | Default |
|----------|-------------|---------|
| `WARCHY_PATH` | Repository root directory | `~/.local/share/warchy` |
| `WARCHY_INSTALL` | Installation scripts directory | `$WARCHY_PATH/install` |
| `WARCHY_LOGO` | Path to ASCII logo | `$WARCHY_PATH/logo.txt` |

### XDG Base Directories

Follow XDG Base Directory specification:

| Variable | Description | Default |
|----------|-------------|---------|
| `XDG_CONFIG_HOME` | User configuration files | `~/.config` |
| `XDG_CACHE_HOME` | User cache files | `~/.cache` |
| `XDG_DATA_HOME` | User data files | `~/.local/share` |
| `XDG_STATE_HOME` | User state files | `~/.local/state` |

### Installation Control Flags

Control what gets installed:

| Variable | Description | Default |
|----------|-------------|---------|
| `WARCHY_INSTALL_BASE` | Install base packages | `1` (yes) |
| `WARCHY_INSTALL_OPTIONAL` | Install optional packages | `1` (yes) |
| `WARCHY_LOCAL_TEST` | Test mode (skip git clone) | unset |

### Usage Examples

**Skip optional packages**:
```bash
WARCHY_INSTALL_OPTIONAL=0 bash install/install.sh
```

**Base packages only**:
```bash
WARCHY_INSTALL_BASE=1 WARCHY_INSTALL_OPTIONAL=0 bash install/install.sh
```

**Test mode** (for development):
```bash
WARCHY_LOCAL_TEST=1 bash install.warchy.sh
```

---

## Package Lists

### warchy-base.packages

**Format**: Plain text, one package per line

**Features**:
- Comments start with `#`
- Empty lines ignored
- No version pinning
- Only essential packages

**Example**:
```plaintext
# Core system
base-devel
sudo
git

# CLI tools
bat
eza
fzf
```

### warchy-optional.packages

**Format**: Same as base packages

**Contents**: Nice-to-have packages for enhanced experience

### warchy-yay.packages

**Format**: Same as base packages

**Contents**: AUR packages (requires yay)

**Note**: This list is processed after yay is installed

---

## Logging System

### Overview

All installation operations use the `run_logged` function from `helpers/logging.sh`.

### Log Functions

#### `log_step(message)`
Display informational step message (cyan color)

#### `log_success(message)`
Display success message (green color with checkmark)

#### `log_info(message)`
Display additional info (gray color with arrow)

#### `run_logged(script [args...])`

**Purpose**: Execute a script with automatic logging and error handling

**Features**:
- Timestamps each operation
- Displays separator lines for clarity
- Shows script name being executed
- Captures exit codes
- Sources scripts (not executes) to preserve environment
- Sets `CURRENT_SCRIPT` variable

**Output format**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[2026-01-18 14:30:45] RUNNING: guard.sh
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✔  Guards: All checks passed
[2026-01-18 14:30:46] SUCCESS: guard.sh completed
```

### Stage Separators

Visual separators group related operations:

```bash
gum style --foreground 214 --border double --border-foreground 214 \
  --padding "0 1" --width 80 --align center "STAGE NAME"
```

**Example output**:
```
╔══════════════════════════════════════════════════════════════════════════════╗
║                          PRE-INSTALLATION                                    ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## Error Handling

### Strict Mode

All scripts use bash strict mode:

```bash
set -eEuo pipefail
```

**Effects**:
- `-e` - Exit on command failure
- `-E` - Inherit ERR trap by subshells
- `-u` - Treat unset variables as errors
- `-o pipefail` - Propagate errors through pipes

### Guard Checks with User Override

The `guard.sh` script uses an `abort()` function that:

1. Displays the failed requirement
2. Offers to proceed anyway with confirmation
3. Exits if user declines

**Example**:
```bash
abort() {
  echo -e "\e[31mWarchy install requires: $1\e[0m"
  echo
  gum confirm "Proceed anyway on your own accord?" || exit 1
}
```

### Script Exit Codes

The `run_logged` function checks exit codes:

```bash
if [ $exit_code -eq 0 ]; then
    echo "[$(date)] SUCCESS: $script_name completed"
else
    echo "[$(date)] ERROR: $script_name failed (exit code: $exit_code)"
    return $exit_code
fi
```

**Behavior**: Non-zero exit codes halt the installation process

---

## Customizing Installation

### Adding a New Pre-Install Check

1. Create script in `pre-install/`:
```bash
#!/bin/bash
set -eEuo pipefail

# Your check logic here
if [[ condition ]]; then
  gum style --foreground 82 "✔  Check passed"
else
  gum style --foreground 196 "✗ Check failed"
  exit 1
fi
```

2. Add to `install.sh`:
```bash
run_logged "$WARCHY_INSTALL/pre-install/your-check.sh"
```

### Adding a Configuration Step

1. Create script in `config/`:
```bash
#!/bin/bash
set -eEuo pipefail

gum style --foreground 39 "⚡ Configuring feature..."

# Your configuration logic
cp "$WARCHY_PATH/default/config" ~/.config/

gum style --foreground 82 "✔  Configuration complete"
```

2. Add to `install.sh` in the config stage:
```bash
run_logged "$WARCHY_INSTALL/config/your-config.sh"
```

### Adding Packages

**Base packages**:
```bash
echo "package-name" >> install/warchy-base.packages
```

**Optional packages**:
```bash
echo "package-name" >> install/warchy-optional.packages
```

**AUR packages**:
```bash
echo "aur-package" >> install/warchy-yay.packages
```

### Creating Package Configurations

For complex package installations, create a configuration file:

1. Create `~/.config/warchy/install/mypackage.conf`
2. Define package behavior (see [../bin/install/README.md](../bin/install/README.md))
3. Add to `install.sh`:
```bash
run_logged "$WARCHY_PATH/bin/install/warchy-pkg-manager" install mypackage
```

---

## Testing

### Test Mode

Enable test mode for development:

```bash
WARCHY_LOCAL_TEST=1 bash install.warchy.sh
```

**Behavior**:
- Skips git clone
- Uses local directory copy
- Displays logo in red (visual indicator)
- All other operations proceed normally

### Dry Run Approach

To test individual stages:

```bash
# Test pre-install checks only
bash install/pre-install/guard.sh

# Test config deployment
bash install/config/config.sh

# Test package installation
bash install/packaging/base.sh
```

### Debugging

Enable bash debug mode:

```bash
bash -x install/install.sh
```

**Output**: Shows every command as it executes

### Re-running Installation

The installation is designed to be re-runnable:

- Configuration files are overwritten (idempotent)
- Packages use `--needed` flag (skip if installed)
- Scripts check for existing state before modifying

**Safe to re-run**: Won't cause duplicate installations or conflicts

---

## Related Documentation

- [bin/install/README.md](../bin/install/README.md) - Package management system
- [bin/README.md](../bin/README.md) - Utility scripts documentation
- [../README.md](../README.md) - Main project overview
- [../AGENT.md](../AGENT.md) - AI development guidelines
- [../CHANGELOG.md](../CHANGELOG.md) - Historical changes and decisions

---

## Troubleshooting

### Common Issues

**Installation fails at guard checks**:
- Solution: Review requirements (vanilla Arch, not root, no DE)
- Override: Use confirmation prompt to proceed anyway

**Package installation fails**:
- Check: Internet connection
- Check: Pacman keyring is updated
- Solution: `sudo pacman-key --refresh-keys`

**Scripts not found after installation**:
- Check: `~/.local/bin` is in PATH
- Solution: Re-source bashrc: `source ~/.bashrc`

**Systemd services not starting**:
- Check: Service files were copied correctly
- Solution: `systemctl --user daemon-reload`
- Debug: `systemctl --user status service-name`

**First-run tasks not executing**:
- Check: Marker file exists: `~/.local/state/warchy/first-run-pending`
- Check: Detection block in `~/.config/bash/init`
- Solution: Source first-run manually: `source install/post-install/first-run.sh`

### Getting Help

For installation issues:
1. Check the installation log output (timestamps and script names)
2. Review the specific script that failed
3. Check environment variables: `env | grep WARCHY`
4. Verify system requirements with guard checks
5. Open an issue on GitHub with log output

---

## Architecture Decisions

### Why Modular Scripts?

**Benefits**:
- Easy to understand individual operations
- Simple to test in isolation
- Clear dependency chain
- Maintainable and extensible
- Reusable components

### Why Sequential Stages?

**Rationale**:
- Clear ordering of operations
- Predictable behavior
- Easy to debug (know exactly what ran)
- Natural checkpoint boundaries
- Allows partial installation

### Why Logging Everything?

**Purpose**:
- Troubleshooting failed installations
- Understanding what was changed
- Verification of completed steps
- Audit trail for system changes
- Development and testing feedback

---

**Last Updated**: January 18, 2026
