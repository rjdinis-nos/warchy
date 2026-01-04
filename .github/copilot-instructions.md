# GitHub Copilot Instructions for Warchy

## Project Overview

Warchy is an automated Arch Linux installation and configuration framework with an interactive CLI interface. The project emphasizes reliability, user experience, and modularity.

## Architecture

### Directory Structure
- `install.warchy.sh` - Bootstrap installer for web-based installation (pipe-to-shell)
- `install/install.sh` - Main installation entry point orchestrating the setup
- `bin/` - Utility scripts organized by purpose:
  - Main launchers: `warchy-launcher`, `warchy-run`, `warchy-notify`
  - `apps/` - Application wrappers (about, btop, geminicli, htop)
  - `install/` - Installation utilities (docker, gcloud, go, npm, pnpm, posting, vhdm)
  - `utils/` - System utilities (version, branch, drive-info, env inspection, package wrappers, fzf)
- `config/` - User configuration templates:
  - `bash/` - Modular bash configuration (aliases, envs, functions, init, keybindings, etc.)
  - Application configs (dunst, fastfetch, foot, git, gnupg, npm, starship, systemd, tmux, vim, yazi)
- `default/` - Default system configuration files:
  - `bashrc` - Default bashrc that sources config/bash/rc
  - `applications/` - Desktop application shortcuts
  - `nvim/` - Neovim color scheme defaults
  - `pacman/` - Pacman configuration and mirrorlist
  - `systemd/` - Systemd service defaults
  - `wsl/` - WSL-specific configurations
- `install/helpers/` - Shared helper module (logging)
- `install/pre-install/` - Pre-flight checks and system preparation
- `install/config/` - System configuration scripts:
  - `config.sh` - Main configuration orchestrator
  - `fast-shutdown.sh` - Faster shutdown configuration
  - `increase-sudo-tries.sh` - Sudo attempt limits  
  - `scripts.sh` - Script deployment to ~/.local/bin
  - `ssh-flakiness.sh` - SSH stability fixes
  - `systemd.sh` - Systemd service configuration
  - `usb-autosuspend.sh` - USB power management
- `install/packaging/` - Package installation modules:
  - `base.sh` - Base system packages
  - `optional.sh` - Optional packages
  - `yay.sh` - Yay AUR helper installation
  - `optional-yay.sh` - Optional AUR packages
  - `go.sh`, `rust.sh` - Language toolchains
  - `gcp.sh` - Google Cloud Platform tools
  - `posting.sh`, `vhdm.sh` - Specialized tools
  - `localdb.sh` - File location database (plocate)
- `install/post-install/` - Post-installation and completion scripts:
  - `allow-reboot.sh` - Configure reboot permissions
  - `nvim.sh` - Neovim setup
  - `finished.sh` - Completion screen

### Key Design Principles
1. **Modular Design**: Each script has a single responsibility
2. **Robust Error Handling**: All scripts use `set -eEo pipefail` and comprehensive error trapping
3. **Beautiful UX**: Leverages `gum` for interactive, colorful CLI experiences
4. **Real-time Feedback**: Live log tailing during installation
5. **Safety First**: Guard checks prevent installation on incompatible systems
6. **DRY Principles**: Functions defined once, no duplicate code
7. **Variable-Driven**: Use `$WARCHY_PATH` and environment variables, not hardcoded paths

### Recent Code Quality Improvements (December 2025)

- **Removed Unused Code**: Eliminated unused helper modules (display.sh, errors.sh, utils.sh) that were never integrated into the installation flow
- **Simplified Architecture**: Streamlined to single logging helper with focused responsibilities
- **Consistent Naming**: Systematically renamed all `wslarchy` references to `warchy`:
  - Updated paths in config.sh to use `$WARCHY_PATH`
  - Renamed sudoers files: `wslarchy-tzupdate` → `warchy-tzupdate`
  - Renamed state directory: `~/.local/state/wslarchy` → `~/.local/state/warchy`
  - Updated variables: `WSLARCHY_*` → `WARCHY_*`
- **Fixed Typos**: Corrected filename mismatch in allow-reboot.sh
- **Better Maintainability**: All paths now use variables for easy refactoring

## Coding Standards

### Bash Script Requirements

**Strict Mode**:
```bash
#!/bin/bash
set -eEo pipefail
```
Every script must exit on errors and propagate failures through pipes.

**Error Handling**:
- Use trap for error catching in main scripts
- Provide recovery options to users
- Log all errors to `WARCHY_INSTALL_LOG_FILE`
- Use basic error handling with `set -eEo pipefail`

**Sourcing Pattern**:
```bash
source "$WARCHY_INSTALL/helpers/logging.sh"
```
The logging helper provides functions for running scripts with proper logging.

### Naming Conventions

**Variables**:
- `WARCHY_*` - Global project variables (always uppercase, always exported)
- `LOCAL_VAR` - Local script variables (uppercase, not exported)
- `function_local` - Function-local variables (lowercase)

**Functions**:
- `snake_case` for all function names
- Descriptive names: `start_install_log`, not `start_log`
- Action verbs: `show_`, `run_`, `install_`, `configure_`

**Files**:
- `kebab-case.sh` for scripts
- `.packages` suffix for package lists
- `.conf` for configuration files

### Display & UI Guidelines

**Using gum**:
```bash
# Styled output
gum style --foreground 2 "Success message"
gum style --foreground 1 "Error message"
gum style --foreground 3 "Warning message"

# User interaction
gum confirm "Proceed?" || exit 1
choice=$(gum choose "Option 1" "Option 2" "Option 3")

# Logging
log_step "Starting operation..."
log_success "Operation completed"
log_info "Additional information"
```

**Logo Display**:
Display logo using inline ANSI colors:
```bash
echo -e "\e[32m$(<"$WARCHY_LOGO")\e[0m"
gum style --foreground 3 --padding "1 0 0 0" "Section Name..."
```

### Logging Standards

**Installation Logging**:
```bash
# Use run_logged to execute installation scripts
run_logged "$WARCHY_INSTALL/config/config.sh"
```

**Log Functions**:
- `run_logged <script>` - Execute script with automatic logging and error handling
- `log_step <message>` - Display informational step message
- `log_success <message>` - Display success message
- `log_info <message>` - Display additional info message

**Direct Logging**:
- Use gum commands directly for styled terminal output
- Scripts output to stdout/stderr is captured automatically by `run_logged`

## Environment Variables

### Required Variables
- `WARCHY_PATH` - Repository root directory
- `WARCHY_INSTALL` - Installation scripts directory (`$WARCHY_PATH/install`)
- `WARCHY_INSTALL_LOG_FILE` - Log file path (`/var/log/warchy-install.log`)
- `WARCHY_LOGO` - Path to logo.txt file
- `CURRENT_SCRIPT` - Currently executing script (set by run_logged)

## Bootstrap Installer

### Overview

The `install.warchy.sh` file is a pipe-to-shell bootstrap installer designed to be hosted on a web server and executed directly:

```bash
curl -LsSf https://website.com/install.warchy.sh | sh
# or
wget -qO- https://website.com/install.warchy.sh | sh
```

### Key Features

1. **XDG Compliance**: Respects `XDG_DATA_HOME`, falls back to `~/.local/share/warchy`
2. **Environment Variables**:
   - `WARCHY_REPO` - GitHub repository (default: `rjdinis-nos/warchy`)
   - `WARCHY_BRANCH` - Git branch to checkout (default: `master`)
   - `XDG_DATA_HOME` - Custom installation directory
   - `WARCHY_LOCAL_TEST` - Enable test mode (copies from local directory instead of cloning)
3. **Minimal Dependencies**: Only requires `git` and standard shell tools
4. **Automatic Cleanup**: Removes previous installations before cloning
5. **Branch Selection**: Supports installing from custom branches
6. **Test Mode**: Single file supports both production and local testing

### Bootstrap Script Requirements

**Shell Compatibility**:
```bash
#!/bin/sh
set -e  # Use /bin/sh for maximum compatibility
```

**POSIX Compliance**:
- Use `/bin/sh` not `/bin/bash` for wider compatibility
- Avoid bash-specific features (arrays, `[[`, etc.)
- Use `command -v` instead of `which`
- Use POSIX-compliant parameter expansion

**Error Handling**:
```bash
error() {
    echo "Error: $*" >&2
    exit 1
}

check_command() {
    command -v "$1" >/dev/null 2>&1 || error "$1 is required but not installed."
}
```

**Installation Flow**:
1. Display logo and environment variables
2. Install git via pacman if needed
3. Clean previous installation directory
4. Clone repository from GitHub
5. Checkout custom branch if specified
6. Source the main `install.sh` script

### Modifying the Bootstrap Installer

When updating `install.warchy.sh`:

- Keep it minimal and focused on repository cloning
- Use only POSIX shell features for compatibility
- Validate all environment variables before use
- Provide clear output for each step
- Handle errors gracefully with informative messages
- Filter pacman output to reduce noise: `2>&1 | grep -v "skipping"`
- Always use quiet cloning: `git clone --quiet`
- Support both production (GitHub clone) and test (local copy) modes
- Use `WARCHY_LOCAL_TEST` to switch between modes

### Hosting the Bootstrap Installer

The bootstrap installer should be:
- Hosted on a reliable web server
- Served with HTTPS for security
- Made executable: `chmod +x install.warchy.sh`
- Versioned or dated for tracking

Example hosting locations:
- GitHub raw: `https://raw.githubusercontent.com/user/repo/branch/install.warchy.sh`
- Custom domain: `https://warchy.example.com/install.warchy.sh`
- CDN: `https://cdn.example.com/warchy/install.warchy.sh`

### Testing the Bootstrap Installer

The bootstrap installer supports local testing via the `WARCHY_LOCAL_TEST` environment variable:

**Test Mode Logic:**
```bash
if [ -n "$WARCHY_LOCAL_TEST" ]; then
    # Test mode: Copy from local directory
    echo "ℹ  [TEST MODE] Copying from local directory..."
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    cp -R "$SCRIPT_DIR" "$WARCHY_PATH"
else
    # Production mode: Clone from GitHub
    git clone --quiet "https://github.com/${WARCHY_REPO}.git" "$WARCHY_PATH"
fi
```

**Usage:**
```bash
# Production: Download and run from web
curl -LsSf https://website.com/install.warchy.sh | sh

# Test: Run locally with test mode enabled
WARCHY_LOCAL_TEST=1 bash install.warchy.sh
```

**When to use test mode:**
- Developing new installation features
- Testing bootstrap script changes
- Debugging installation flow
- Validating before committing

**When to use production mode:**
- Testing end-to-end installation from GitHub
- Verifying branch selection works correctly
- Testing with clean slate (no local modifications)

## Common Patterns

### Creating a New Install Module

```bash
#!/bin/bash
# install/category/module.sh

echo "Starting module configuration..." >> "$WARCHY_INSTALL_LOG_FILE"

# Installation logic here
sudo pacman -S --noconfirm --needed package-name

# Use WARCHY_PATH for file references
cp "$WARCHY_PATH/default/config-file" ~/.config/

echo "Module configuration complete" >> "$WARCHY_INSTALL_LOG_FILE"
```

Then source it in `install.sh`:
```bash
source "$WARCHY_INSTALL/category/module.sh"
```

### Creating a New Utility Script

```bash
#!/usr/bin/env bash
set -euo pipefail

echo -e "\e[32mStarting utility...\e[0m"

# Utility logic here

echo -e "\e[32mUtility completed.\e[0m"
```

### Adding Package Lists

**Base packages** (`install/warchy-base.packages`):
- One package per line
- No version pinning
- Comments starting with `#`
- Essential packages only

**Optional packages** (`install/warchy-optional.packages`):
- Same format as base
- Nice-to-have packages
- Domain-specific tools

### Guard Checks

Add new guards to `install/pre-install/guard.sh`:
```bash
# Check for required condition
if [[ condition ]]; then
  abort "Requirement description"
fi
```

Use `abort()` function which offers user override option.

## Package Management

### Installing Packages
```bash
# Official repositories
sudo pacman -S --noconfirm --needed package1 package2

# Quiet output (filter repetitive lines)
sudo pacman -Syu --noconfirm --needed package 2>&1 | grep -v "skipping"
```

### Package Categories
- **Core System**: git, sudo, base-devel, bash-completion
- **Editors**: vim, vi, neovim
- **Network**: curl, wget, bind, net-tools, nmap, openssh, whois
- **CLI Tools**: bat, eza, fzf, fd, gum, htop, fastfetch, tree
- **File Tools**: plocate, unzip, less
- **Development**: jq, hexedit, pinentry, go (optional), rust (optional)
- **System**: tmux, libnotify, librsvg, usbutils, freetype2
- **Optional Enhanced**: btop, dust, duf, glow, lazydocker, lazygit, starship
- **Optional Dev**: github-cli, gdb, cloc, lsof, python-pip, uv
- **Optional System**: pacman-contrib, qemu-img, sox
- **Desktop**: adwaita-icon-theme, ttf-dejavu, ttf-nerd-fonts-symbols-mono, feh
- **X11**: xterm, xorg-xrdb, xorg-xmessage, xdg-utils
- **Wayland**: foot, foot-terminfo, wl-clipboard
- **Yazi deps**: 7zip, ffmpeg, imagemagick, poppler, resvg
- **LazyVim deps**: ast-grep, luarocks
- **AUR (via yay)**: xdg-terminal-exec

## Error Handling

### Error Handler Pattern
```bash
#!/bin/bash
set -eEo pipefail

# Script exits automatically on error
# run_logged handles errors and displays them appropriately
```

### Exit Codes
```bash
# Check exit codes in run_logged
if [ $exit_code -eq 0 ]; then
    log_success "Operation completed"
else
    gum style --foreground 1 "ERROR: Operation failed (exit code: $exit_code)"
    return $exit_code
fi
```

## Docker Integration

### Container Patterns
```bash
docker run --rm -it \
    -v "$(pwd)":/app \
    -v config-volume:/root/.config \
    -w /app \
    -e ENV_VAR="value" \
    image:tag \
    command
```

### Docker Checks
```bash
# Verify Docker is installed
if ! command -v docker &> /dev/null; then
    error_exit "Docker not installed"
fi

# Verify Docker is running
if ! docker info &> /dev/null; then
    sudo systemctl start docker || error_exit "Cannot start Docker"
fi
```

## Testing Considerations

### Manual Testing Checklist
- [ ] Fresh Arch Linux VM
- [ ] Non-root user with sudo
- [ ] No existing DE (Gnome/KDE)
- [ ] Test error scenarios
- [ ] Verify log output
- [ ] Check recovery options
- [ ] Validate package installation
- [ ] Confirm configurations applied

### Error Simulation
Test error handling by:
- Invalid package names
- Network disconnection
- Permission issues
- Disk space constraints

## Common Tasks

### Adding a New Package
1. Add to appropriate `.packages` file
2. Update README.md if significant
3. Test clean installation

### Adding a Utility Script
1. Create in `bin/` directory
2. Use `#!/usr/bin/env bash` shebang
3. Set executable: `chmod +x bin/script.sh`
4. Document in README.md

### Adding Installation Step
1. Create module in `install/` subdirectory
2. Source in `install.sh` at appropriate location
3. Follow logging conventions
4. Test error handling

### Modifying Pacman Config
1. Update `default/pacman/pacman.conf` or `mirrorlist`
2. Test with `pacman -Syu`
3. Verify parallel downloads work
4. Check repository access

## Anti-Patterns to Avoid

❌ **Don't**:
- Use `sudo` unnecessarily
- Install unnecessary packages
- Skip error checking
- Ignore return codes
- Use `set +e` without good reason
- Create temporary files without cleanup
- Hard-code paths (use `$WARCHY_PATH` and environment variables)
- Mix installation logic in helper files
- Echo directly in helpers (use return values or params)
- Duplicate functions across files (define once, source everywhere)
- Leave unused/dead code in the codebase
- Use hardcoded project names (use variables for easy renaming)

✅ **Do**:
- Check prerequisites before operations
- Log all significant actions
- Provide user feedback
- Clean up on errors
- Use consistent formatting
- Follow existing patterns
- Test edge cases
- Document non-obvious code

## Security Considerations

- **No hardcoded credentials**: Use config files
- **Validate user input**: Especially in guard checks
- **Minimal sudo usage**: Only when necessary
- **File permissions**: Respect umask, use appropriate permissions
- **Package verification**: Rely on pacman signature checking

## WSL-Specific Notes

- WSL interop requires `/etc/wsl.conf` configuration
- Windows paths available when interop enabled
- Docker requires special IP forwarding setup
- System restart via `wsl --shutdown` from Windows

## Future Development

When adding features, consider:
- Will this work in WSL and native Arch?
- Does this require user interaction?
- How does this fail gracefully?
- Is logging comprehensive?
- Does it follow project conventions?

## Resources

- [omarchy](https://omarchy.org/) - Original inspiration for architecture patterns
- [Arch Wiki](https://wiki.archlinux.org/)
- [gum Documentation](https://github.com/charmbracelet/gum)
- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide)
- [ShellCheck](https://www.shellcheck.net/) - Use for linting

## Contact

For questions about architecture decisions or unclear patterns, refer to:
- Existing code in the repository
- This instructions file
- Project README.md
