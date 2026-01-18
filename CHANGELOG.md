# Changelog

All notable changes to Warchy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Configuration-based package management system**
  - `warchy-pkg` - Direct package installer/remover for pacman and yay
  - `warchy-pkg-manager` - Configuration file processor for complex installations
  - `warchy-install-helpers.sh` - Shared helper functions library
  - `warchy-packages` - Interactive TUI package browser with keyboard shortcut (Alt+P)
- Package configuration files for: docker, gcloud, go, npm, opencode, pnpm, posting, rust, vhdm, yay
- `warchy-snippets` - Code snippets browser with category support
- Snitch (HTTP listener) and python-pipx packages
- DUA (Disk Usage Analyzer) application launcher
- Opencode package
- Comprehensive documentation structure with specialized README.md files
- AI agent development guidelines in AGENT.md
- Changelog file for tracking releases

### Changed
- **Refactored package management**: Replaced 20+ individual install/remove scripts with unified configuration system
- Package configurations now use declarative INI-style format
- Environment variables automatically exported to shell session
- Improved Go environment variable configuration during install/remove
- Enhanced pacman and yay package installer scripts
- Added category column to warchy-snippets
- Moved AI instructions from `.github/copilot-instructions.md` to `AGENT.md`
- Documentation now follows hierarchical structure with clear cross-references

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
