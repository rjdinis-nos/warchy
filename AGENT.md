# AI Agent Development Guidelines for Warchy

## Project Overview

Warchy is an automated Arch Linux installation and configuration framework with an interactive CLI interface. The project emphasizes reliability, user experience, and modularity.

**Target Platform**: Arch Linux (vanilla), particularly WSL environments  
**Primary Language**: Bash scripting  
**UI Framework**: [gum](https://github.com/charmbracelet/gum) for interactive CLI

## Key Design Principles

1. **Modular Design**: Each script has a single responsibility
2. **Robust Error Handling**: All scripts use `set -eEuo pipefail`
3. **Beautiful UX**: Leverages `gum` for interactive, colorful CLI experiences
4. **DRY Principles**: Functions defined once, no duplicate code
5. **Variable-Driven**: Use `$WARCHY_PATH` and environment variables, not hardcoded paths
6. **Documentation First**: All code changes require documentation updates

## Project Structure

```
warchy/
├── README.md                    # Project overview with links to detailed docs
├── AGENT.md                     # This file - AI agent guidelines
├── CHANGELOG.md                 # Historical changes and architectural decisions
├── install.warchy.sh            # Bootstrap installer (pipe-to-shell)
├── bin/                         # Utility scripts
│   ├── README.md               # Utility scripts documentation
│   ├── install/                # Package management system
│   │   └── README.md           # Package management documentation
│   ├── apps/                   # Application wrappers
│   └── utils/                  # System utilities
├── config/                      # User configuration templates
│   ├── bash/                   # Modular bash configuration
│   └── warchy/install/         # Package configuration files (*.conf)
├── default/                     # Default system configurations
└── install/                     # Installation orchestration
    └── README.md               # Installation process documentation
```

**Documentation Hierarchy**:
- **README.md** (root) - High-level overview, summaries, links only
- **install/README.md** - Complete installation process and flow
- **bin/README.md** - Utility scripts reference
- **bin/install/README.md** - Package management system
- **AGENT.md** - This file, for AI development assistance
- **CHANGELOG.md** - Historical changes and decisions

## Coding Standards

### Bash Script Requirements

**Strict Mode** (Required for all scripts):
```bash
#!/bin/bash
set -eEuo pipefail
```

**Effects**:
- `-e` - Exit on command failure
- `-E` - Inherit ERR trap by subshells
- `-u` - Treat unset variables as errors
- `-o pipefail` - Propagate errors through pipes

**Bootstrap scripts** use POSIX shell for compatibility:
```bash
#!/bin/sh
set -e
```

### Naming Conventions

**Variables**:
```bash
WARCHY_*            # Global project variables (uppercase, exported)
LOCAL_VAR           # Local script variables (uppercase, not exported)
function_local      # Function-local variables (lowercase)
```

**Functions**:
```bash
snake_case          # All function names
action_verb_noun    # Descriptive: start_install_log, not start_log
```

**Files**:
```bash
kebab-case.sh       # Scripts
*.packages          # Package lists
*.conf              # Configuration files
```

### Display & UI Guidelines

**Using gum for interactive UI**:
```bash
# Styled output
gum style --foreground 2 "Success message"
gum style --foreground 1 "Error message"
gum style --foreground 3 "Warning message"

# User interaction
gum confirm "Proceed?" || exit 1
choice=$(gum choose "Option 1" "Option 2" "Option 3")
selected=$(gum filter < options.txt)
```

**Logging with helper functions**:
```bash
source "$WARCHY_INSTALL/helpers/logging.sh"

run_logged "$WARCHY_INSTALL/config/config.sh"
log_step "Starting operation..."
log_success "Operation completed"
log_info "Additional information"
```

### Environment Variables

**Required Variables**:
```bash
WARCHY_PATH         # Repository root directory
WARCHY_INSTALL      # Installation scripts directory
WARCHY_LOGO         # Path to logo.txt file
```

**XDG Base Directories**:
```bash
XDG_CONFIG_HOME     # ~/.config
XDG_CACHE_HOME      # ~/.cache
XDG_DATA_HOME       # ~/.local/share
XDG_STATE_HOME      # ~/.local/state
```

**Installation Control**:
```bash
WARCHY_INSTALL_BASE      # Install base packages (default: 1)
WARCHY_INSTALL_OPTIONAL  # Install optional packages (default: 1)
WARCHY_LOCAL_TEST        # Test mode - skip git clone
```

## Common Patterns

### Creating a New Installation Module

```bash
#!/bin/bash
set -eEuo pipefail

gum style --foreground 39 "⚡ Starting module..."

# Installation logic
sudo pacman -S --noconfirm --needed package-name

# Use WARCHY_PATH for file references
cp "$WARCHY_PATH/default/config-file" ~/.config/

gum style --foreground 82 "✔  Module completed"
```

Add to `install/install.sh`:
```bash
run_logged "$WARCHY_INSTALL/category/module.sh"
```

### Creating a New Utility Script

```bash
#!/usr/bin/env bash
set -euo pipefail

# Script logic here

# Use gum for user feedback
gum style --foreground 2 "Operation completed"
```

Make executable and deploy:
```bash
chmod +x bin/warchy-newscript
# Deployed automatically to ~/.local/bin by install/config/scripts.sh
```

### Package Management

**Configuration-based packages** (preferred):

Create `config/warchy/install/mypackage.conf`:
```ini
[package]
PACKAGE_NAME=package1 package2
PACKAGE_INSTALLER=pacman

[env]
PATH="$HOME/.local/mypackage/bin"

[post-install]
sudo systemctl enable myservice.service
```

Install:
```bash
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install mypackage
```

**Simple package lists**:

Add to `install/warchy-base.packages` or `install/warchy-optional.packages`:
```bash
# One package per line
package-name
another-package
```

**Direct installation**:
```bash
warchy-pkg install pacman package1 package2
warchy-pkg remove yay aur-package
```

### Error Handling

**Guard checks with user override**:
```bash
abort() {
  echo -e "\e[31mWarchy requires: $1\e[0m"
  gum confirm "Proceed anyway?" || exit 1
}

if [[ condition ]]; then
  abort "Requirement description"
fi
```

**Exit code checking**:
```bash
set +e
command_that_might_fail
exit_code=$?
set -e

if [ $exit_code -ne 0 ]; then
  gum style --foreground 1 "ERROR: Command failed"
  exit $exit_code
fi
```

## Documentation Standards

### Critical Rule

**Documentation must be updated when code changes.**

### When to Update Documentation

✅ **Always update for**:
- Adding new features or scripts
- Modifying existing functionality
- Changing configuration formats
- Refactoring code architecture
- Adding/removing files or directories
- Changing installation flow
- Updating environment variables
- Modifying package lists

### Update Checklist

For any code change:

1. ✅ Update relevant README.md file(s) with new information
2. ✅ Update AGENT.md if adding new patterns or standards
3. ✅ Update root README.md if adding new subsystem (add link)
4. ✅ Add examples for new functionality
5. ✅ Document breaking changes prominently
6. ✅ Add to CHANGELOG.md if architectural change

### Root README.md Rules

**Keep concise**:
- Brief summaries only (1-2 paragraphs)
- Links to detailed documentation
- Quick start commands
- Clear navigation

**Avoid**:
- Long detailed explanations (belong in specialized READMEs)
- Duplicate content across multiple READMEs
- Implementation details (belong in subsystem docs)

**Format for linking**:
```markdown
### Topic Summary

Brief overview with key points.

For comprehensive documentation, see:

**[path/to/README.md](path/to/README.md)** - Detailed Documentation

This includes:
- Subtopic 1
- Subtopic 2
```

### Specialized README.md Files

**Required sections**:
1. Overview/Introduction
2. Architecture or How It Works
3. Usage Examples
4. Reference (functions, configuration)
5. Customization Guide
6. Troubleshooting
7. Related Documentation

**Content standards**:
- Detailed explanations with examples
- Complete reference information
- Troubleshooting guides
- Cross-references to related docs
- Visual diagrams where helpful (ASCII art)

### CHANGELOG.md Maintenance

**Purpose**: Track all user-facing changes in a structured, release-based format following [Keep a Changelog](https://keepachangelog.com/) conventions.

**When to update CHANGELOG.md**:
- ✅ Adding new features or scripts
- ✅ Changing existing functionality
- ✅ Fixing bugs
- ✅ Removing features or deprecating functionality
- ✅ Any change that affects users or installation behavior
- ❌ Internal refactoring that doesn't change behavior (can be mentioned but not required)
- ❌ Documentation-only changes (unless significant)

**How to update CHANGELOG.md**:

1. **Add entries to [Unreleased] section** at the top:
```markdown
## [Unreleased]

### Added
- New feature description

### Changed
- Modified behavior description

### Fixed
- Bug fix description

### Removed
- Deprecated feature description
```

2. **Categorize changes correctly**:
   - **Added**: New features, scripts, packages, functionality
   - **Changed**: Modifications to existing behavior, refactorings that affect usage
   - **Deprecated**: Features marked for future removal (rarely used)
   - **Removed**: Deleted features, scripts, or packages
   - **Fixed**: Bug fixes, error corrections
   - **Security**: Security-related fixes or improvements

3. **Write clear, user-focused entries**:
   - Use present tense: "Add feature" not "Added feature"
   - Be specific: "Add warchy-snippets with category support" not "Add new script"
   - Focus on what changed for users, not implementation details
   - Group related changes under parent bullets when appropriate

4. **On release**:
   - Move [Unreleased] entries to new version section
   - Add release date: `## [X.Y.Z] - YYYY-MM-DD`
   - Update version comparison links at bottom of file
   - Create new empty [Unreleased] section

**Example workflow**:
```markdown
## [Unreleased]

### Added
- `warchy-newfeature` - Interactive tool for managing XYZ
  - Support for ABC functionality
  - Integration with existing tools

### Changed
- Improved error handling in installation scripts
- Updated package list with latest versions

### Fixed
- SSH agent configuration during first boot
- Path resolution in WSL environments
```

**Verification**:
- Before committing changes, verify CHANGELOG.md is updated
- Use `gh release` commands to validate dates match actual releases
- Ensure version links at bottom are updated for new releases

## Anti-Patterns to Avoid

❌ **Don't**:
- Use `sudo` unnecessarily
- Skip error checking or ignore return codes
- Use `set +e` without good reason
- Hard-code paths (use `$WARCHY_PATH` and variables)
- Echo directly in helper functions (use return values)
- Duplicate functions across files (define once, source everywhere)
- Leave unused/dead code in the codebase
- Create temporary files without cleanup
- Use hardcoded project names (use variables)

✅ **Do**:
- Check prerequisites before operations
- Log all significant actions with gum
- Provide clear user feedback
- Clean up on errors
- Use consistent formatting
- Follow existing patterns
- Test error scenarios
- Document non-obvious code

## Testing Guidelines

### Manual Testing Checklist

Test on:
- [ ] Fresh Arch Linux VM or WSL
- [ ] Non-root user with sudo
- [ ] No existing DE (Gnome/KDE)

Verify:
- [ ] Error scenarios handled gracefully
- [ ] Log output is clear and informative
- [ ] Recovery options work correctly
- [ ] Package installation succeeds
- [ ] Configurations applied correctly

### Test Mode

Enable for development:
```bash
WARCHY_LOCAL_TEST=1 bash install.warchy.sh
```

**Behavior**:
- Skips git clone (uses local directory)
- Visual indicator (red logo)
- All other operations proceed normally

### Re-running Installation

Installation is designed to be re-runnable:
- Configuration files overwritten (idempotent)
- Packages use `--needed` flag (skip if installed)
- Scripts check existing state before modifying

## Common Tasks

### Adding a Package Configuration

1. Create `config/warchy/install/mypackage.conf`
2. Define package behavior (see bin/install/README.md)
3. Add to `install/install.sh` if part of standard install
4. Test install and remove operations
5. Document in README.md if significant

### Adding a Utility Script

1. Create in `bin/` directory with proper shebang
2. Use `set -euo pipefail`
3. Make executable: `chmod +x bin/warchy-newscript`
4. Add keybinding in `config/bash/keybindings` if needed
5. Document in bin/README.md
6. Test functionality

### Adding an Installation Stage

1. Create module in appropriate `install/` subdirectory
2. Source in `install/install.sh` at appropriate stage
3. Use `run_logged` for execution
4. Follow logging conventions (log_step, log_success)
5. Test error handling
6. Update install/README.md with stage documentation

### Modifying Package Lists

1. Edit appropriate `.packages` file:
   - `warchy-base.packages` - Essential system packages
   - `warchy-optional.packages` - Optional pacman packages
   - `warchy-yay.packages` - AUR packages (via yay)
2. One package per line, comments with `#`
3. Test clean installation
4. Update documentation if significant

## Package Management System

**Architecture**:
- **warchy-pkg** - Direct package installer/remover (pacman/yay)
- **warchy-pkg-manager** - Configuration-based package manager
- **warchy-install-helpers.sh** - Loader for modular helper functions
  - `helpers/validation.sh` - Input validation and script checks
  - `helpers/package.sh` - Package operations and version checking
  - `helpers/env.sh` - Environment variable management
- **warchy-packages** - Interactive TUI for browsing/managing

**Key helper functions**:
```bash
# Validation (helpers/validation.sh)
check_if_script_is_sourced()              # Validate sourcing
check_if_script_is_executed()             # Validate execution

# Package Management (helpers/package.sh)
is_installed(pkg, type)                   # Check installation status
get_package_type(config_file)             # Get "git" or "package"
check_git_package_version(pkg, repo, cmd) # Version comparison (returns 0 if should install)
load_package_config(config_file)          # Parse configuration
load_git_package_config(config_file)      # Parse git package config
run_install_commands(type, pkg, commands) # Execute hooks

# Environment Management (helpers/env.sh)
install_env_config(env_file, env_config)  # Install environment vars
remove_env_config(env_file, env_config)   # Remove environment vars
```

**Configuration format**: See bin/install/README.md for complete reference.

## Installation Flow

**6 Sequential Stages**:

1. **Pre-Installation** - Guard checks, user validation, pacman setup
2. **System Configuration** - Deploy configs, scripts, systemd services
3. **Base Packages** - Install essential system packages
4. **Optional Packages** - Install enhanced tools and dev environments
5. **Setup** - SSH agent, Neovim, reboot permissions
6. **First-Run Marker** - Trigger post-install cleanup on first login

**Logging**: All stages use `run_logged` for consistent output with timestamps.

**Details**: See install/README.md for comprehensive flow diagrams and stage documentation.

## WSL-Specific Considerations

- WSL interop requires `/etc/wsl.conf` configuration
- Windows paths available when interop enabled
- Docker requires IP forwarding setup in systemd
- Use `bash -lc` (not `-ilc`) in PowerShell integration to avoid hanging
- System restart via `wsl --shutdown` from Windows PowerShell

## Security Considerations

- **No hardcoded credentials**: Use config files or environment variables
- **Validate user input**: Especially in guard checks
- **Minimal sudo usage**: Only when necessary
- **File permissions**: Respect umask, use appropriate permissions
- **Package verification**: Rely on pacman signature checking
- **NOPASSWD sudo**: For wheel group (development environment, not production)

## Resources

**External References**:
- [Arch Wiki](https://wiki.archlinux.org/) - Comprehensive Arch Linux documentation
- [gum Documentation](https://github.com/charmbracelet/gum) - Interactive CLI framework
- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide) - Shell scripting guide
- [ShellCheck](https://www.shellcheck.net/) - Shell script linting tool

**Internal Documentation**:
- [README.md](README.md) - Project overview
- [install/README.md](install/README.md) - Installation system details
- [bin/README.md](bin/README.md) - Utility scripts reference
- [bin/install/README.md](bin/install/README.md) - Package management guide
- [CHANGELOG.md](CHANGELOG.md) - Historical changes and decisions

## Development Workflow

### Testing Changes to Deployed Files

**Important**: During installation, files from the source tree are copied to the user environment:

```
Source Location                    → Deployed Location
────────────────────────────────────────────────────────────────
$WARCHY_PATH/bin/*                 → ~/.local/bin/warchy/
$WARCHY_PATH/config/*              → ~/.config/
$WARCHY_PATH/default/bashrc        → ~/.bashrc
```

**When making changes to source files that are deployed during installation:**

1. **Edit source files** in `$WARCHY_PATH` (e.g., `~/.local/share/warchy/`)
2. **Test changes** by copying to the deployed location
3. **Always ask for permission** before overwriting user files

**Example workflow**:
```bash
# You made changes to bin/install/warchy-pkg-manager
# Before testing, confirm with user:
echo "About to override ~/.local/bin/warchy/install/warchy-pkg-manager"
read -p "Continue? (y/N): " confirm
if [[ "$confirm" == "y" ]]; then
  cp $WARCHY_PATH/bin/install/warchy-pkg-manager ~/.local/bin/warchy/install/warchy-pkg-manager
  echo "File updated. Test your changes."
fi
```

**Critical files that require user confirmation before overwriting**:
- `~/.config/git/config` - User's git configuration
- `~/.bashrc` - User's bash configuration
- `~/.config/bash/*` - Bash configuration files
- Any files in `~/.local/bin/warchy/` - Executable scripts

**Automated copy command** (for development convenience):
```bash
# Copy all bin files to deployed location (after user confirmation)
cp -rf $WARCHY_PATH/bin/* ~/.local/bin/warchy/
```

**Re-running installation safely**:
- Fresh install uses `first-run.mode` marker to detect clean state
- Re-running without marker preserves user configurations (e.g., git config)
- Test both scenarios: fresh install and update/re-install

## Questions or Clarifications

For architecture decisions or unclear patterns:
1. Check existing code in the repository
2. Review this AGENT.md file
3. Consult relevant README.md documentation
4. Review CHANGELOG.md for historical context

**Development Philosophy**: When in doubt, favor clarity over cleverness, consistency over novelty, and documentation over assumptions.
