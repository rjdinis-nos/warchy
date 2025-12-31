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



## Requirements

### System Requirements
- **OS**: Vanilla Arch Linux (no derivatives like Manjaro, Garuda, EndeavourOS, CachyOS)
- **Architecture**: x86_64
- **State**: Fresh installation (no Gnome/KDE pre-installed)
- **Permissions**: Must NOT run as root (runs as regular user with sudo)

### Prerequisites
The installer checks for these requirements automatically via guard scripts before proceeding.

## Installation

### PowerShell WSL Installation (Recommended for Windows)

The easiest way to install Warchy on Windows is using the automated PowerShell script that creates a complete WSL distribution:

**One-Line Download and Execution:**

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rjdinis-nos/warchy/main/New-ArchWSL.ps1" -OutFile ".\New-ArchWSL.ps1"; .\New-ArchWSL.ps1 -DistroName "linuxbox" -Username "rjdinis" -OsType "warchy" -WslBasePath "C:\WSL\VMs"
```

**Step-by-Step:**

1. Download the script:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rjdinis-nos/warchy/main/New-ArchWSL.ps1" -OutFile ".\New-ArchWSL.ps1"
```

2. Run the script with your desired configuration:
```powershell
.\New-ArchWSL.ps1 -DistroName "linuxbox" -Username "joe" -OsType "warchy" -WslBasePath "C:\WSL\VMs"
```

#### Mandatory Parameters

- **`-Username`** (Required)  
  The Linux username to create in the WSL distro. This user will have sudo privileges.  
  Example: `-Username "joe"`

- **`-WslBasePath`** (Required)  
  The base directory where WSL virtual machines will be stored. A subdirectory with the distro name will be created here.  
  Example: `-WslBasePath "C:\WSL\VMs"` or `-WslBasePath "D:\Development\WSL"`

#### Optional Parameters

- **`-DistroName`** (Default: `"warchy"`)  
  The name of the WSL distribution. This will also be used as the hostname.  
  Example: `-DistroName "linuxbox"`

- **`-OsType`** (Default: `"base"`)  
  The type of installation to perform:
  - `lite` - Lightweight installation without systemd
  - `base` - Standard installation with systemd enabled
  - `warchy` - Full installation with systemd and Warchy configuration
  
  Example: `-OsType "warchy"`

- **`-VHDSizeGB`** (Default: `10`)  
  The size of the virtual hard disk in gigabytes.  
  Example: `-VHDSizeGB 20`

- **`-UserPassword`** (Default: `"changeme"`)  
  The password for the created user.  
  Example: `-UserPassword "MySecurePass123"`

- **`-WarchyBranch`** (Default: `"main"`)  
  The git branch to use when cloning the Warchy repository.  
  Example: `-WarchyBranch "develop"`

- **`-WarchyPath`**  
  Path to a local Warchy directory for testing (Windows format). Useful for development.  
  Example: `-WarchyPath "C:\Projects\warchy"`

#### Usage Examples

**Create a basic WSL Arch Linux distribution:**
```powershell
.\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL"
```

**Create a full Warchy distribution:**
```powershell
.\New-ArchWSL.ps1 -DistroName "devbox" -Username "developer" -OsType "warchy" -WslBasePath "D:\WSL" -VHDSizeGB 20
```

**Create using a specific Warchy branch:**
```powershell
.\New-ArchWSL.ps1 -Username "tester" -OsType "warchy" -WarchyBranch "develop" -WslBasePath "C:\WSL"
```

**Create for local development/testing:**
```powershell
.\New-ArchWSL.ps1 -Username "dev" -OsType "warchy" -WarchyPath "C:\Projects\warchy" -WslBasePath "C:\WSL"
```

**What the PowerShell script does:**
- Creates a new WSL2 Arch Linux distribution from scratch
- Configures the virtual hard disk with specified size
- Sets up systemd (for base and warchy types)
- Creates a user with sudo privileges
- Configures SSH access
- Installs and configures Warchy (for warchy type)
- Displays connection information upon completion

### Linux Bootstrap Installation

If you already have an Arch Linux WSL distribution or native installation, use the install-warchy.sh bootstrap installer to configure Warchy:

```bash
curl -LsSf https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/main/install.warchy.sh | sh
```

#### Custom Installation Options

You can customize the installation with environment variables:

```bash
# Install from a specific branch
WARCHY_BRANCH=develop curl -LsSf https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/main/install.warchy.sh | sh

# Use custom installation directory (XDG_DATA_HOME)
XDG_DATA_HOME="$HOME/custom" curl -LsSf https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/main/install.warchy.sh | sh
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
bash install/install.sh
```

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
- `npm/` - Node.js package manager

**System Services**:
- `systemd/user/` - User systemd services
- `dunst.service` - Notification daemon
- `ssh-agent.service.d/` - SSH agent overrides

**Desktop Integration**:
- `dunst/` - Notification daemon configuration
- `fastfetch/` - System information display
- `yazi/` - File manager with Catppuccin theme

All tools respect XDG directories for clean home directory.


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