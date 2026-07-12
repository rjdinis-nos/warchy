# Changelog

All notable changes to Warchy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **`warchy-obsidian paste` command**: New `warchy-obsidian paste [name]` creates a note/file in a vault directly from the clipboard — writes a `.md` note for text, or an image file (`.png`/`.jpg`/`.gif`/`.bmp`/`.webp`) if the clipboard holds an image (detected via `wl-paste --list-types`). Supports `-v vault`, `-f folder`, `--open`, `-y`, same as `copy`. Wired into `warchy-obsidian-tui` as "Create note from clipboard". New `obsclip()` bash function (alongside the existing `obs()`) added to `config/bash/functions` for quick clipboard-to-vault sharing
- **Foot `Ctrl+V` paste binding**: `clipboard-paste` now also bound to `Ctrl+V` (in addition to the default `Ctrl+Shift+V`/`XF86Paste`) for Windows-style pasting. Trade-off: `Ctrl+V` is intercepted at the terminal level, so it no longer reaches apps that use the raw `Ctrl+V` byte (e.g. bash readline's quoted-insert, vim visual-block mode). Only newly-opened foot windows pick up the change, since foot does not hot-reload `[key-bindings]`
- **Bun package**: New `bun.conf` installs Bun (`bun` from the `extra` repo) via pacman, with `BUN_INSTALL` redirected to `$XDG_DATA_HOME/bun` for XDG compliance
- **Claude Code package**: New `claude-code.conf` installs Anthropic's Claude Code CLI (`@anthropic-ai/claude-code`) via npm with version checking and XDG config migration support
- **WSLg `/mnt/shared_memory` mount**: New `mnt-shared_memory.mount` systemd unit (installed and enabled by `wsl-config.sh`) works around [microsoft/wslg#1456](https://github.com/microsoft/wslg/issues/1456). On WSL 2.7.3+, `/mnt/shared_memory` is not mounted, so WSLg falls back to `[WARN:COPY MODE]` and GUI windows show only a taskbar icon without rendering. Mounting tmpfs there before `local-fs.target` lets WSLg initialize its shared framebuffer normally.

### Fixed
- **`warchy-obsidian-tui` file picker**: Replaced `gum file` with an `fzf`-based flat file picker (`pick_file` helper) in "Copy file to vault" and the daily-note "append a file" prompt. `gum file` 0.17.0 has a rendering bug that silently drops the first entry of the directory listing (confirmed independent of window/terminal size), making some files appear "missing" or the list look clipped at the top. `gum choose` is unaffected and still used elsewhere
- **`obsidian-cli.desktop`**: Added `-T "Warchy Obsidian"` so the terminal window title reflects the app instead of the generic `foot` default; window height increased `1600x800` → `1600x1000`
- **wslg.sh**: Missing `/` path separator in `$XDG_RUNTIME_DIR/$(basename "$i")` symlink creation caused `Permission denied` errors on every login shell start (was trying to create files in root-owned `/run/user/` instead of the user's `/run/user/1000/`)
- **Copilot CLI startup hang**: Git credential helper in `~/.config/git/config` pointed to a hardcoded `gh` path (`/usr/local/bin/gh`) that no longer exists after pacman installs `gh` to `/usr/sbin/gh`. This caused copilot to prompt `Username for 'https://github.com':` at startup and freeze. Fixed by using `!gh` (PATH-relative). `warchy-user-setup` now auto-repairs stale hardcoded credential helper paths.

### Added
- **XDG-compliant Rust configuration**: rustup and cargo now redirect to `$XDG_DATA_HOME/rustup` and `$XDG_DATA_HOME/cargo` with automatic migration from old `~/.rustup` and `~/.cargo` locations
- **SSH-centric security configuration**: GnuPG and keychain directories moved to `~/.ssh` (GNUPGHOME and KEYCHAIN_DIR environment variables)
- **XDG-compliant Docker configuration**: `DOCKER_CONFIG` merged into `docker.conf` (was a separate `docker-config.conf`); `DOCKER_CONFIG` also set in `config/bash/envs` baseline; `[post-install]` migrates `~/.docker` → `$XDG_CONFIG_HOME/docker` automatically
- **XDG-compliant .NET configuration**: `dotnet-config.conf` fixed (`DOTNET_HOME` → `DOTNET_CLI_HOME`) and added to `install.sh`; `DOTNET_CLI_HOME` added to `config/bash/envs` baseline
- **Meta-package support**: `warchy-pkg-manager` now accepts confs with no `[package]` section — runs `[env]` and `[post-install]`/`[post-remove]` hooks without installing any package
- **XDG-compliant .NET configuration**: .NET cache moved to `$XDG_CONFIG_HOME/dotnet` via DOTNET_HOME environment variable
- **Configuration-based package management system**
  - `warchy-pkg` - Direct package installer/remover for pacman and yay
  - `warchy-pkg-manager` - Configuration file processor for complex installations
  - `warchy-install-helpers.sh` - Shared helper functions library (refactored into modular files)
  - `warchy-packages` - Interactive TUI package browser with keyboard shortcut (Alt+P)
- **Modular helper functions**: Split helper functions into focused files by responsibility
  - `helpers/validation.sh` - Input validation and script execution mode checks
  - `helpers/package.sh` - Package management, version checking, config parsing
  - `helpers/env.sh` - Environment variable management
- **Version checking for git packages**: Skip reinstallation if already up-to-date
  - Check installed version vs repository version
  - Support for tag-based and PKGBUILD-based version detection
  - Support for commit hash-based versioning with automatic detection
  - Configurable via `[version]` section in `.conf` files
- **Comprehensive package configuration documentation**
  - Created detailed README.md in config/warchy/install/ with complete configuration reference
- **mcpc**: Universal MCP CLI client added as optional package with XDG-compliant data directory (`MCPC_HOME_DIR`), discoverable in `warchy-packages` and application launcher
- **GitHub Copilot CLI**: Optional installation via `warchy-packages`, discoverable in application launcher
- **GnuPG and Keychain package configs**: Separate optional configurations for XDG-style management (`gnupg.conf`, `keychain.conf`)
- **Docker configuration package**: XDG-compliant Docker config moved to `~/.config/docker` (`docker-config.conf`)
  - **.NET configuration package**: XDG-compliant .NET cache moved to `~/.config/dotnet` (`dotnet-config.conf`)
  - Added inline documentation comments to git package .conf files
  - Examples for semantic versions and commit hash version checking
  - Best practices and troubleshooting guide
- **Git config preservation**: Preserve user's git configuration during reinstallation (non-fresh installs)
- **Development workflow documentation**: Added testing guidelines for deployed files in AGENT.md
- Package configuration files for: docker, gcloud, go, npm, opencode, pnpm, posting, rust, vhdm, yay
- Optional GitHub Copilot CLI installation in Stage 4 (`config/warchy/install/copilot.conf`)
- `warchy-snippets` - Code snippets browser with category support
- Snitch (HTTP listener) and python-pipx packages
- DUA (Disk Usage Analyzer) application launcher
- Opencode package
- Comprehensive documentation structure with specialized README.md files
- AI agent development guidelines in AGENT.md
- Changelog file for tracking releases

### Changed
- **Refactored package management**: Replaced 20+ individual install/remove scripts with unified configuration system
- **Refactored helper functions**: Split monolithic helper file into modular, focused files
- **Improved source check**: Replaced helper-based check with inline validation in warchy-pkg-manager
- **Optimized git cloning**: Use `--depth 1` for faster git-based package installations
- **Smart temporary dependency handling**: Track and preserve already-installed build dependencies
  - Fix: Correctly preserve pre-existing packages listed in TEMP_BUILD_DEPS
  - Fix: Prevent removal of dependencies that were installed before package build
- **Enhanced version checking**: Improved version comparison logic
  - Fix: Support commit hash versioning (7+ character hex strings)
  - Fix: Compare commit hashes directly with repository HEAD
  - Fix: Fallback to commit hash when semantic versions unavailable
- **Improved recursive package installation**:
  - Fix: Preserve correct package name in build messages during dependency installation
  - Fix: Prevent environment variable pollution across recursive installations
  - Fix: Save and restore package-specific ENV_CONFIG during dependency processing
- **Fixed dependency section parsing**: Corrected regex to prevent TEMP_BUILD_DEPS matching BUILD_DEPS
- Package configurations now use declarative INI-style format
- Environment variables automatically exported to shell session
- Improved Go environment variable configuration during install/remove
- Enhanced pacman and yay package installer scripts
- Added category column to warchy-snippets
- Moved AI instructions from `.github/copilot-instructions.md` to `AGENT.md`
- Documentation now follows hierarchical structure with clear cross-references
- Reorganized documentation: bin/install/README.md focuses on tools, config/warchy/install/README.md details configuration

### Removed
- Individual package install/remove scripts (replaced by configuration system)
- Duplicate code across package management scripts
- Unused applications folder

## [0.4.0] - 2026-01-05

### Added
- `warchy-user-setup` - Interactive post-installation configuration tool
  - VHD mounting for SSH keys with Windows/WSL path support
  - Git configuration (user, email, GPG signing)
  - SSH agent setup and key management
  - GitHub CLI authentication integration
  - Automatic HTTPS to SSH remote conversion
- Post-install help message guiding users to `warchy-user-setup`
- Automated post-installation cleanup (pacman/yay cache, orphaned packages)
- Dunst systemd service configuration
- System packages: adwaita-icon-theme, ttf-dejavu, ttf-nerd-fonts-symbols-mono

### Changed

### Fixed
- SSH agent systemd service configuration and socket enablement
- Dunst systemd service configuration
- Man-db service configuration override during installation
- First-run post-installation cleanup now triggers correctly from PowerShell
- PowerShell integration changed from `bash -ilc` to `bash -lc` to prevent hanging
- First-run script properly sources instead of executes for clean exit
- VHDM build process (removed duplicate build step)
- Multiple installation errors related to systemd configurations

## [0.3.0] - 2026-01-04

### Added
- `warchy-launcher` - Desktop application launcher for terminal apps
- `warchy-keybindings` - Display key shortcuts (prints after logo)
- `warchy-fzf` - Fuzzy finder wrapper (renamed from warchy-menu)
- Automated first-run post-installation cleanup system
  - Package cache cleanup using paccache
  - Yay cache and build directory cleanup
  - Orphaned package removal
- Self-cleaning first-run marker mechanism
- Man-db service configuration override to disable AC power check
- Bash launch function for applications with x-terminal-emulator on WSL
- Optional packages: lazyjournal, tailspin

### Changed
- Renamed project from `wslarchy` to `warchy` throughout codebase
- Updated all paths to use `$WARCHY_PATH` variable
- Renamed state directory: `~/.local/state/wslarchy` → `~/.local/state/warchy`
- Updated environment variables: `WSLARCHY_*` → `WARCHY_*`
- Sudoers files renamed: `wslarchy-tzupdate` → `warchy-tzupdate`
- Default branch changed from `master` to `main`
- `warchy-commands` renamed to `warchy-snippets`
- `warchy-menu` renamed to `warchy-fzf` and moved to bin/utils
- `warchy-shortcuts` converted from Python to Bash
- Install scripts renamed: `warchy-{pacman,yay}-install` → `warchy-install-{pacman,yay}-pkgs`
- Keybinding for snippets changed to Ctrl+Alt+Space
- Removed WARCHY_PATH and WARCHY_BRANCH from .bash_profile

### Fixed
- WarchyBranch parameter passing to install.warchy.sh (now uses environment variable)
- Multiple fixes in warchy-git-release script
- Keybindings description typos
- Corrected filename mismatch in allow-reboot.sh
- Various typos in configuration files

### Removed
- Unused helper modules: display.sh, errors.sh, utils.sh

## [0.2.0] - 2026-01-02

### Added
- `warchy-reboot` - Safe reboot/shutdown script
- `warchy-snippets` - CLI snippet command runner
- Modular installation system with separate stages
- XDG Base Directory compliance for all configuration files
- gum-based interactive CLI with beautiful UI
- Comprehensive package lists (base, optional pacman, optional yay)
- WSL integration with Windows interoperability
- Docker support with IP forwarding configuration
- SSH agent systemd service
- Custom systemd configurations and hooks
- Pacman hook to trigger mandb updates
- Enhanced journald configuration for WSL's fast shutdown behavior
- Optional packages: lsb-release, duf, dust (later replaced by dua), zoxide

### Changed
- Installation process now uses 6 sequential stages
- Logging system with real-time output and timestamps
- Error handling with guard checks and user overrides
- Disk usage app changed from dust to dua
- Updated bash aliases, environment variables, and functions
- Script naming conventions improved for consistency

## [0.1.0] - 2025-12-31

### Added
- Initial release
- Bootstrap installer for pipe-to-shell installation
- PowerShell WSL setup script (New-ArchWSL.ps1)
- Basic Arch Linux configuration
- Essential package installation
- Bash configuration with modular structure

---

## Release Notes

### Understanding Version Numbers

- **Major (X.0.0)**: Breaking changes or major architectural overhauls
- **Minor (0.X.0)**: New features, significant improvements, non-breaking changes
- **Patch (0.0.X)**: Bug fixes, minor improvements, documentation updates

### Contributing

When adding entries to this changelog:
1. Add unreleased changes under `[Unreleased]` section
2. Group changes by type: Added, Changed, Deprecated, Removed, Fixed, Security
3. Use present tense ("Add feature" not "Added feature")
4. Reference issues/PRs when applicable
5. Move unreleased changes to a version section on release

[Unreleased]: https://github.com/rjdinis-nos/warchy/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/rjdinis-nos/warchy/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/rjdinis-nos/warchy/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/rjdinis-nos/warchy/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/rjdinis-nos/warchy/releases/tag/v0.1.0
