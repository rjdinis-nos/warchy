<div align="center">

# Warchy

```diff
+ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
+ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
+ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
+ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓███████▓▒░░▒▓█▓▒░      ░▒▓████████▓▒░░▒▓██████▓▒░ 
+ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░    
+ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░    
+  ░▒▓█████████████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░    
```

</div>

## Why Warchy?

**Built for Linux users stranded on Windows company laptops.**

If you're a Linux enthusiast forced to use Windows for work, Warchy is your escape hatch. It's a one-line installer that delivers a fully-configured, opinionated Arch Linux environment right inside WSL—no dual boot, no VM overhead, just pure Linux integrated seamlessly with Windows.

Warchy gives you:
- 🚀 **One-liner installation** - From zero to configured Arch in minutes
- 🎨 **Terminal-first experience** - Rich collection of modern TUIs and CLI tools
- 🔧 **Opinionated setup** - Carefully curated packages and configs so you can focus on work
- 🪟 **Native WSL integration** - Seamless interop with Windows tools and filesystem
- ⚡ **Development-ready** - Docker, dev tools, and language runtimes included

Stop compromising. Get the Linux environment you deserve, even on corporate hardware.

---

## Overview

Warchy is a comprehensive installer framework designed to set up a fresh Arch Linux system with curated packages, configurations, and utilities. It features:

- **Interactive Installation**: Beautiful CLI interface with real-time logging
- **Modular Architecture**: Organized helper scripts and pre-install checks
- **Robust Error Handling**: Comprehensive error catching with recovery options
- **Package Management**: Base and optional package lists for flexibility
- **WSL Support**: WSL interop configuration utilities
- **Docker Integration**: Automated Docker setup and configuration
- **Development Tools**: Modern CLI utilities (bat, fzf, gum, eza, btop, etc.)

## Requirements

### System Requirements
- **OS**: Vanilla Arch Linux (no derivatives like Manjaro, Garuda, EndeavourOS, CachyOS)
- **Architecture**: x86_64
- **State**: Fresh installation (no Gnome/KDE pre-installed)
- **Permissions**: Must NOT run as root (runs as regular user with sudo)

### Prerequisites
The installer checks for these requirements automatically via guard scripts before proceeding.

## Installation

### One-Line Installation (Recommended)

The easiest way to install Warchy is using the bootstrap installer:

```bash
curl -LsSf https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/main/install.warchy.sh | sh
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/main/install.warchy.sh | sh
```

#### Custom Installation Options

You can customize the installation with environment variables:

```bash
# Install from a specific branch
WARCHY_BRANCH=develop curl -LsSf https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/main/install.warchy.sh | sh

# Use custom installation directory (XDG_DATA_HOME)
XDG_DATA_HOME="$HOME/custom" curl -LsSf https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/main/install.warchy.sh | sh

# Test mode - use local files instead of cloning from GitHub
WARCHY_LOCAL_TEST=1 bash install.warchy.sh
```

**What the bootstrap installer does:**
- Updates pacman and installs git if needed
- Clones the repository to `~/.local/share/warchy` (or `$XDG_DATA_HOME/warchy`)
- Optionally checks out a specific branch via `WARCHY_BRANCH`
- Automatically runs the main `install.sh` script

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/rjdinis-nos/warchy.git ~/.local/share/warchy
cd ~/.local/share/warchy
```

2. Run the installer:
```bash
bash install.sh
```

### Testing the Bootstrap Installer

For development and testing, use the `WARCHY_LOCAL_TEST` environment variable:

```bash
# Test the bootstrap installer locally
WARCHY_LOCAL_TEST=1 bash ~/warchy/install.warchy.sh
```

**Test mode behavior:**
- Copies from local directory instead of cloning from GitHub
- Allows testing changes without committing/pushing
- Useful for development and debugging
- Same file works for both production and testing

The installer will:
- Display the Warchy logo
- Run system compatibility checks
- Show environment information
- Configure pacman with optimized settings
- Install base and optional packages
- Log all activities to `/var/log/warchy-install.log`

## Project Structure

```
warchy/
├── install.sh                    # Main installation script (deprecated, use install.warchy.sh)
├── install.warchy.sh            # Bootstrap web installer (pipe-to-shell)
├── logo.txt                      # ASCII art logo
├── icon.txt                      # ASCII art icon
├── version                       # Version file
├── New-ArchWSL.ps1              # PowerShell script for WSL setup
├── applications/                 # Desktop application files
│   └── foot.desktop             # Foot terminal desktop entry
├── bin/                          # Utility scripts and launchers
│   ├── warchy-launch-tui        # TUI launcher
│   ├── warchy-launcher          # Main launcher script
│   ├── warchy-menu              # Interactive menu system
│   ├── warchy-notify            # WSL-Windows notification bridge
│   ├── warchy-run               # Application runner
│   ├── warchy-shortcuts         # Keyboard shortcuts handler
│   ├── apps/                    # Application wrappers
│   │   ├── about               # About dialog
│   │   ├── btop                # btop wrapper
│   │   ├── geminicli           # Gemini CLI wrapper
│   │   └── htop                # htop wrapper
│   ├── install/                 # Installation utilities
│   │   ├── warchy-install-docker
│   │   ├── warchy-install-gcloud
│   │   ├── warchy-install-go
│   │   ├── warchy-install-npm
│   │   ├── warchy-install-pnpm
│   │   ├── warchy-install-posting
│   │   ├── warchy-install-vhdm
│   │   └── warchy-remove-go
│   └── utils/                   # System utilities
│       ├── warchy-branch        # Show git branch
│       ├── warchy-drive-info    # Drive information
│       ├── warchy-drive-select  # Drive selector
│       ├── warchy-icon          # Icon display
│       ├── warchy-list-env-vars # List environment variables
│       ├── warchy-list-path     # List PATH entries
│       ├── warchy-list-shell-flags
│       ├── warchy-list-shell-functions
│       ├── warchy-list-shell-vars
│       ├── warchy-logo          # Logo display
│       ├── warchy-pacman-install # Pacman wrapper
│       ├── warchy-version       # Version display
│       └── warchy-yay-install   # Yay AUR helper wrapper
├── config/                       # User configuration files
│   ├── bash/                    # Bash configuration
│   │   ├── aliases             # Shell aliases
│   │   ├── envs                # Environment variables
│   │   ├── functions           # Shell functions
│   │   ├── init                # Initialization
│   │   ├── inputrc             # Readline config
│   │   ├── keybindings         # Key bindings
│   │   ├── rc                  # Main bashrc loader
│   │   └── shell               # Shell options
│   ├── dunst/                   # Notification daemon
│   ├── fastfetch/               # System info tool
│   ├── foot/                    # Foot terminal emulator
│   ├── git/                     # Git configuration
│   ├── gnupg/                   # GPG configuration
│   ├── npm/                     # NPM configuration
│   ├── starship/                # Starship prompt
│   ├── systemd/user/            # Systemd user services
│   ├── tmux/                    # Tmux configuration
│   ├── vim/                     # Vim configuration
│   ├── xterm/                   # XTerm configuration
│   └── yazi/                    # Yazi file manager
├── default/                      # Default system configurations
│   ├── bashrc                   # Default bashrc
│   ├── applications/            # Application shortcuts
│   ├── nvim/                    # Neovim defaults
│   ├── pacman/                  # Pacman configuration
│   │   ├── mirrorlist          # Mirror list
│   │   └── pacman.conf         # Pacman config
│   ├── systemd/                 # Systemd defaults
│   │   └── journald.conf.d/    # Journal config
│   └── wsl/                     # WSL-specific configs
│       ├── wsl-remount-rshared.service
│       ├── wslg.conf
│       ├── wslg.sh
│       └── WSLInterop.conf
└── install/                      # Installation modules
    ├── install.sh               # Main installer entry point
    ├── warchy-base.packages     # Core system packages
    ├── warchy-optional.packages # Optional packages
    ├── warchy-yay.packages      # AUR packages via yay
    ├── config/                  # System configuration scripts
    │   ├── config.sh           # Main configuration orchestrator
    │   ├── fast-shutdown.sh    # Faster shutdown configuration
    │   ├── increase-sudo-tries.sh # Sudo attempt limits
    │   ├── scripts.sh          # Script deployment
    │   ├── ssh-flakiness.sh    # SSH stability fixes
    │   ├── systemd.sh          # Systemd configuration
    │   └── usb-autosuspend.sh  # USB power management
    ├── helpers/                 # Helper modules
    │   └── logging.sh          # Logging system
    ├── packaging/               # Package installation modules
    │   ├── base.sh             # Base package installer
    │   ├── gcp.sh              # Google Cloud Platform tools
    │   ├── go.sh               # Golang installer
    │   ├── localdb.sh          # File location database (plocate)
    │   ├── optional-yay.sh     # Optional AUR packages
    │   ├── optional.sh         # Optional package installer
    │   ├── posting.sh          # Posting tool installer
    │   ├── rust.sh             # Rust toolchain
    │   ├── vhdm.sh             # VHDM installer
    │   └── yay.sh              # Yay AUR helper
    ├── post-install/            # Post-installation tasks
    │   ├── allow-reboot.sh     # Reboot permissions
    │   ├── finished.sh         # Completion screen
    │   └── nvim.sh             # Neovim setup
    └── pre-install/             # Pre-installation checks
        ├── first-run-mode.sh   # First-run detection
        ├── guard.sh            # System compatibility checks
        ├── pacman.sh           # Pacman configuration
        ├── show-env.sh         # Environment display
        └── user.sh             # User validation
```

## Features

### Base Packages

The installer includes essential development and system tools:

**Core System**:
- `base-devel` - Development tools and compilers
- `git` - Version control
- `sudo` - Privilege elevation
- `bash-completion` - Enhanced bash completion
- `man-db`, `man-pages` - Manual pages

**Editors**:
- `vim`, `vi` - Classic text editors
- `neovim` - Modern vim fork

**Network Tools**:
- `curl`, `wget` - Download utilities
- `bind` - DNS utilities
- `net-tools` - Network utilities
- `nmap` - Network scanner
- `openssh` - SSH client/server
- `whois` - Domain lookup

**Modern CLI Tools**:
- `bat` - Cat clone with syntax highlighting
- `eza` - Modern ls replacement
- `fzf` - Fuzzy finder
- `fd` - Modern find alternative
- `gum` - Glamorous shell scripts
- `htop` - Interactive process viewer
- `fastfetch` - System info display
- `tree` - Directory tree viewer

**File Management**:
- `plocate` - Fast file indexing/search
- `unzip` - Archive extraction
- `less` - File pager

**Development**:
- `jq` - JSON processor
- `hexedit` - Hex editor
- `pinentry` - GPG password entry

**System Utilities**:
- `tmux` - Terminal multiplexer
- `libnotify` - Desktop notifications
- `librsvg` - SVG rendering library
- `usbutils` - USB device utilities
- `freetype2` - Font rendering

### Optional Packages

Additional tools available in the optional package list:

**Enhanced CLI Tools**:
- `btop` - Beautiful resource monitor
- `dust` - Intuitive disk usage
- `duf` - Modern disk usage viewer
- `glow` - Markdown renderer
- `lazydocker` - Docker TUI
- `lazygit` - Git TUI
- `starship` - Cross-shell prompt

**Development Tools**:
- `github-cli` - GitHub command line
- `gdb` - GNU debugger
- `cloc` - Count lines of code
- `lsof` - List open files
- `python-pip` - Python package manager
- `uv` - Fast Python package installer

**System Tools**:
- `pacman-contrib` - Pacman utilities
- `qemu-img` - Disk image utility
- `sox` - Sound processing

**Desktop Environment**:
- `adwaita-icon-theme` - Icon theme
- `ttf-dejavu` - DejaVu fonts
- `ttf-nerd-fonts-symbols-mono` - Nerd Font symbols
- `feh` - Image viewer

**X11 Support**:
- `xterm` - X terminal emulator
- `xorg-xrdb` - X resource database
- `xorg-xmessage` - X message dialog
- `xdg-utils` - Desktop integration

**Wayland Support**:
- `foot` - Fast Wayland terminal
- `foot-terminfo` - Foot terminal info
- `wl-clipboard` - Wayland clipboard

**File Manager (Yazi)**:
- `7zip` - Archive support
- `ffmpeg` - Video thumbnails
- `imagemagick` - Image processing
- `poppler` - PDF support
- `resvg` - SVG support

**LazyVim Dependencies**:
- `ast-grep` - AST-based search
- `luarocks` - Lua package manager

### AUR Packages (via Yay)

Packages from the Arch User Repository:
- `xdg-terminal-exec` - XDG terminal execution

### Installation Logging

Real-time logging with beautiful output:
- Logs stored in `/var/log/warchy-install.log`
- Live log tail display during installation
- Installation time tracking
- Detailed step-by-step progress

### Error Handling

Comprehensive error recovery:
- Automatic error detection
- Log tail on failure
- Recovery options menu
- Safe exit handling
- Cursor management

## Utility Scripts

### System Launcher

Warchy includes a sophisticated launcher and menu system:

**warchy-launcher**
```bash
warchy-launcher
```
Interactive application launcher with menu system.

**warchy-menu**
```bash
warchy-menu
```
Interactive menu for selecting and launching applications.

**warchy-run**
```bash
warchy-run <command>
```
Application runner with environment setup.

**warchy-launch-tui**
Text-based UI launcher for terminal applications.

### Installation Utilities

Dedicated installers for additional tools:

**Docker**:
```bash
warchy-install-docker
```
Installs Docker and Docker Compose with optimal configuration.

**Golang**:
```bash
source warchy-install-go
```
Installs Go with proper GOPATH and environment setup.

**Node.js Tools**:
```bash
warchy-install-npm
warchy-install-pnpm
```
Install npm and pnpm package managers.

**Cloud Tools**:
```bash
warchy-install-gcloud
```
Installs Google Cloud SDK.

**Development Tools**:
```bash
warchy-install-posting  # API testing tool
warchy-install-vhdm     # VHD management
```

### System Information

**warchy-version**
```bash
warchy-version
```
Displays current Warchy version.

**warchy-branch**
```bash
warchy-branch
```
Shows current git branch.

**warchy-logo** / **warchy-icon**
```bash
warchy-logo
warchy-icon
```
Display Warchy branding.

### Environment Inspection

**warchy-list-env-vars**
```bash
warchy-list-env-vars [VAR1] [VAR2] ...
```
List specific environment variables.

**warchy-list-path**
```bash
warchy-list-path
```
Display PATH entries in readable format.

**warchy-list-shell-flags**
```bash
warchy-list-shell-flags
```
Show active shell flags.

**warchy-list-shell-functions**
```bash
warchy-list-shell-functions
```
List all defined shell functions.

**warchy-list-shell-vars**
```bash
warchy-list-shell-vars
```
Display all shell variables.

### Drive Management

**warchy-drive-info**
```bash
warchy-drive-info
```
Display detailed drive/disk information.

**warchy-drive-select**
```bash
warchy-drive-select
```
Interactive drive selector.

### Package Management

**warchy-pacman-install**
```bash
warchy-pacman-install <package>
```
Wrapper for pacman with logging and error handling.

**warchy-yay-install**
```bash
warchy-yay-install <package>
```
Wrapper for yay AUR helper.

### WSL Integration

**warchy-notify**
```bash
warchy-notify -t "Title" -m "Message" [options]
```

Sophisticated WSL-Windows notification bridge:
- Sends Windows 11 toast notifications from WSL
- Supports custom icons and expiration times
- Automatically mirrors icons to Windows temp directory
- Parses `/etc/wsl-distribution.conf` for distribution icons

Options:
- `-t, --title` - Notification title (required)
- `-m, --message` - Notification body (required)
- `-l, --level` - Severity: info, warn, error, critical
- `-e, --expire` - Expiration time in minutes

Example:
```bash
warchy-notify -t "Build Complete" -m "Project built successfully" -l info -e 5
```

### WSL Interop Configuration

Enable Windows interoperability in WSL:

### WSL Interop Configuration

WSL interop is automatically configured during installation via `/etc/wsl.conf`.

**Configuration includes**:
- Windows path appending
- Interop enabled
- Metadata support
- Network hostname generation

For manual configuration, edit `/etc/wsl.conf` and restart WSL:
```bash
# From Windows PowerShell
wsl --shutdown
```

### Docker Installation

Automated Docker setup with the installation system or manually:

```bash
warchy-install-docker
```

Features:
- Installs Docker and Docker Compose
- Configures IP forwarding
- Enables BuildKit
- Sets up daemon.json
- User group configuration

### Gemini CLI Runner

Run Google's Gemini CLI in a Docker container:

```bash
~/warchy/bin/apps/geminicli
```

Features:
- Automated Docker container management
- API key configuration
- Volume mounting for workspace
- Interactive shell access

Requirements:
- Docker installed and running
- API key at `~/.config/gemini/api_key`

## Configuration System

Warchy includes a comprehensive configuration system for a complete development environment.

### Modular Bash Configuration

Located in `config/bash/`, the system provides:

**Core Files**:
- `rc` - Main loader sourced by `~/.bashrc`
- `shell` - Shell options and behavior
- `envs` - Environment variables (GOPATH, XDG dirs, etc.)
- `aliases` - Command aliases (eza, bat, docker shortcuts)
- `functions` - Custom shell functions
- `init` - Initialization scripts (starship, fzf)
- `keybindings` - Custom key bindings
- `inputrc` - Readline configuration

### Application Configurations

**Terminal & Display**:
- `foot/` - Wayland terminal emulator config
- `xterm/` - X11 terminal config
- `starship/` - Cross-shell prompt
- `tmux/` - Terminal multiplexer

**Development Tools**:
- `git/` - Git configuration and aliases
- `vim/` - Vim settings
- `nvim/` - Neovim with LazyVim (auto-installed)
- `gnupg/` - GPG agent configuration
- `npm/` - Node.js package manager

**System Services**:
- `systemd/user/` - User systemd services
  - `dunst.service` - Notification daemon
  - `ssh-agent.service.d/` - SSH agent overrides

**Desktop Integration**:
- `dunst/` - Notification daemon configuration
- `fastfetch/` - System information display
- `yazi/` - File manager with Catppuccin theme

### XDG Base Directory Support

Full XDG compliance:
- `XDG_CONFIG_HOME` - `~/.config` (configurations)
- `XDG_CACHE_HOME` - `~/.cache` (cache files)
- `XDG_DATA_HOME` - `~/.local/share` (data files)
- `XDG_STATE_HOME` - `~/.local/state` (state files)

All tools respect XDG directories for clean home directory.

## Pacman Configuration

## Pacman Configuration

The installer applies optimized pacman settings:

**Features**:
- Colored output with `ILoveCandy` progress bar
- Verbose package lists
- Parallel downloads (5 simultaneous)
- Multilib repository enabled
- Fast mirrors (Fastly and Geo)

**Location**: `default/pacman/`

### Environment Variables

The installer uses these environment variables:

- `WARCHY_PATH` - Installation directory
- `WARCHY_INSTALL` - Install scripts directory
- `WARCHY_INSTALL_LOG_FILE` - Log file location
- `WARCHY_START_TIME` - Installation start timestamp

## Recent Improvements

### Code Quality Optimizations (December 2025)

Recent updates have improved code quality and consistency:

- **Removed unused code**: Eliminated unused helper modules (display.sh, errors.sh, utils.sh) that were never integrated
- **Simplified architecture**: Streamlined to single logging helper with focused responsibilities
- **Consistent naming**: Renamed all legacy `wslarchy` references to `warchy` throughout the codebase
- **Variable usage**: Updated hardcoded paths to use `$WARCHY_PATH` variable for better maintainability
- **Bug fixes**: Fixed typo in sudoers file creation that caused naming inconsistencies

### Code Architecture

- **Focused helper system**: Single logging module with clear responsibilities
- **Simple error handling**: Uses bash strict mode (`set -eEo pipefail`) for automatic error exits
- **Environment-driven configuration**: All paths use environment variables for flexibility
- **Direct gum usage**: Leverages gum commands directly for beautiful CLI output

## Development

### Helper Modules

#### logging.sh
Script execution and logging:
- `run_logged(script)` - Execute installation script with automatic logging
- `log_step(message)` - Display informational step message (cyan)
- `log_success(message)` - Display success message (green)
- `log_info(message)` - Display additional info message (gray)
- Timestamped execution logs
- Exit code tracking
- Error reporting with script name and context

### Guard System

The guard system (`install/pre-install/guard.sh`) ensures:

✓ Vanilla Arch Linux (not derivatives)  
✓ Non-root user execution  
✓ x86_64 architecture  
✓ Fresh system (no DE pre-installed)  
✓ User confirmation for override

## Logging

Installation logs are stored at `/var/log/warchy-install.log` with:

- Timestamped start/end markers
- Real-time command output
- Error messages and exit codes
- Installation duration summary
- Detailed package installation logs

## Troubleshooting

### View Installation Log

```bash
sudo less /var/log/warchy-install.log
```

### Common Issues

**Docker not starting**:
```bash
sudo systemctl start docker
```

**Pacman key issues**:
```bash
sudo pacman-key --init
sudo pacman-key --populate archlinux
```

**WSL interop not working**:
- Run `enable-wsl-interop.sh`
- Execute `wsl --shutdown` from Windows
- Restart WSL

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on a fresh Arch installation
5. Submit a pull request

### Code Style

- Use bash strict mode: `set -eEo pipefail`
- Include descriptive comments
- Follow existing naming conventions
- Test error handling paths

## License

MIT License

Copyright (c) 2025 Ricardo Dinis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

See the [LICENSE](LICENSE) file for full details.

## Acknowledgments

- [omarchy](https://omarchy.org/) - Code inspiration and architectural patterns
- [gum](https://github.com/charmbracelet/gum) - Glamorous shell scripts
- [Arch Linux](https://archlinux.org/) - The base distribution
- All the amazing CLI tools included in the package lists

## Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Check the installation log for detailed error information
- Review the [Arch Wiki](https://wiki.archlinux.org/) for system-specific issues

---

**Note**: This is an opinionated Arch Linux setup. Review the package lists and configurations before installation to ensure they meet your needs.
