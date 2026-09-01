# Changelog

All notable changes to Warchy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **`warchy-git-release` now writes the release body from CHANGELOG.md**: The script passed `--generate-notes` to `gh release create`, which builds "What's Changed" from merged pull requests only. Warchy commits straight to `main`, so GitHub found no PRs and published a body containing nothing but the compare link (as happened for v0.7.0). The new `changelog_notes` helper extracts the `## [VERSION]` section from `CHANGELOG.md`, prepends a `**Full Changelog**` compare link, and hands it to `gh` via `--notes-file`. When the changelog has no section for the version being released, it falls back to `--generate-notes` and says so. `--dry-run` now previews the changelog-derived body instead of only the git log.

## [0.7.0] - 2026-09-01

### Added
- **Cliamp package**: New `cliamp.conf` installs [cliamp](https://github.com/bjarneo/cliamp) — a retro terminal music player inspired by Winamp 2.x — from the AUR (`cliamp-bin`, the prebuilt binary, rather than the source-built `cliamp` which pulls in the Go toolchain). The config also installs `pulseaudio-alsa`, which is not optional under WSL: cliamp writes straight to ALSA, but WSL exposes no PCM device (`/dev/snd` contains only `timer`), so without the ALSA→PulseAudio bridge the player runs and reports progress while producing no sound. `pulseaudio-alsa` pulls in `alsa-plugins` and drops `50-pulseaudio.conf`/`99-pulseaudio-default.conf` into `/etc/alsa/conf.d`, routing ALSA output to WSLg's PulseAudio server at `unix:/mnt/wslg/PulseServer`. No local PulseAudio daemon is needed. The post-install hook checks both the bridge and the server socket and warns if either is missing. `pulseaudio-alsa` is deliberately left behind on removal, since other audio apps depend on the same bridge. New `default/applications/cliamp.desktop` surfaces it in `warchy-launcher` (`Ctrl+Space`) — the package ships its own entry to `/usr/share/applications`, where the launcher never looks. Not part of the default install; opt in with `source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install cliamp` or via `warchy-packages` (Alt+P)
- **`warchy-keyring`**: `gum` TUI for managing gnome-keyring secrets — list, add (label + arbitrary attribute pairs + masked secret input), reveal, copy to clipboard via `wl-copy`, and delete, with confirmation prompts on the destructive and secret-revealing actions. Enumeration is delegated to `warchy-list-keyring --raw` so the Secret Service D-Bus walk is defined once. Items are addressed by their full attribute set rather than their label, since labels are not unique. Available from the application launcher (`Alt+A`) as "Keyring Manager" via `default/applications/keyring.desktop`
- **`warchy-list-keyring`**: Lists every gnome-keyring item by collection, label and attributes, without ever reading a secret value. `secret-tool` can only look up attributes it is already given, so there is no way to enumerate the store with it; the script walks the Secret Service D-Bus API with `gdbus` instead (`Collections` → `Items` → `Label`/`Attributes`). Useful for auditing which applications have stored credentials — e.g. `copilot-cli`, and the `org.gnupg.Passphrase` entries cached by `pinentry-gnome3`. `-q` prints bare labels and `--raw` prints TSV for scripting; locked collections report as empty until unlocked. Available in the shell as the `keyring-list` function
- **Credential home (`WARCHY_CREDENTIAL_HOME`)**: A single anchor for every persistent secret, defaulting to `~/.ssh`. `GNUPGHOME`, `KEYCHAIN_DIR` and `PASSWORD_STORE_DIR` are now derived from it in `config/bash/envs` (and in `gnupg.conf`, `keychain.conf`, `pass.conf`) instead of hardcoding `$HOME/.ssh`. This makes the same layout work in both supported scenarios without any per-user branching: leave `~/.ssh` as a plain directory and the credentials stay on the distro's own WSL disk, or mount a VHD there and the identical set of credentials travels between WSL distros. New `install/setup/credentials.sh` (run in the install SETUP stage, and again by `warchy-user-setup` after a VHD is mounted) creates the credential home with mode `0700` and reports whether it resolves to a separate volume or the local disk
- **Secret Service keyrings follow the credential home**: `gnome-keyring-daemon` stores secrets in `$XDG_DATA_HOME/keyrings`, which previously lived on the distro disk even when every other credential was on a mounted VHD — so anything saved with `secret-tool`, `git-credential-libsecret` or `pinentry-gnome3` did not travel with the rest. `gnome-keyring` has no path setting of its own, so `credentials.sh` links `$XDG_DATA_HOME/keyrings` → `$WARCHY_CREDENTIAL_HOME/keyrings`, migrating any existing keyrings and preserving the originals as `keyrings.pre-warchy.<timestamp>`. Relocating via `XDG_DATA_HOME` was rejected because it would move unrelated application data too
- **Credential storage check**: `warchy-system-checker` (`keycheck`) gained a "Credential storage" section reporting the resolved credential home, whether it is a separate volume or local to the distro, which of `gnupg`/`.keychain`/`password-store`/`keyrings` exist, and whether the keyrings link is healthy or dangling
- **`warchy-color-scheme`**: New `bin/utils/warchy-color-scheme` reports the system light/dark color scheme, walking the same chain a portal-aware app does — `org.freedesktop.appearance color-scheme` over D-Bus, then GSettings `org.gnome.desktop.interface color-scheme` — and shows which `org.freedesktop.impl.portal.Settings` backend is installed. `-q` prints just `dark`/`light`/`no-preference` for scripting; exits 1 when neither source can be read. Useful for diagnosing why a GUI app (e.g. `omawrite`) is not following the theme under WSLg
- **`warchy-launcher` hides uninstalled apps**: The launcher now skips desktop entries whose app is not present, instead of listing every entry warchy ships and failing on launch. Uses the freedesktop `TryExec` key, added to all 26 entries in `default/applications/`; entries without it fall back to the first `Exec` token, and entries with neither key are kept. `TryExec` is necessary because most entries wrap the real binary in `xdg-terminal-exec` (`Exec=xdg-terminal-exec -- -T "BTOP" … btop`), so the first `Exec` token is the always-present wrapper and proves nothing. The fzf header reports how many entries were hidden. Note the target binary is not always the package name — `spotify-player` → `spotify_player`, `vhdm` → `vhdm-tui`, `about` → `fastfetch`. New entries in `default/applications/` should declare `TryExec`
- **Omawrite WSLg rendering fix**: The entry launches via `env QT_QPA_PLATFORM=xcb` because Qt's Wayland plugin cannot render under WSLg — weston does not expose GBM/DRM to Wayland clients, so Mesa reports `libEGL warning: failed to get driver name for fd -1` and Qt Quick never gets a GL context. The window is still mapped, so a Windows taskbar icon appears while the window itself never paints. Forcing XWayland uses GLX instead, which is hardware accelerated through Mesa's D3D12 driver. Note this affects any Qt Quick app under WSLg, not just Omawrite; running `omawrite` straight from a shell still hits the Wayland path
- **Omawrite desktop entry**: New `default/applications/omawrite.desktop` makes Omawrite appear in `warchy-launcher` (`Alt+A`), which only scans `$XDG_DATA_HOME/applications` — the upstream package installs its entry to `/usr/share/applications`, where the launcher never looks. `MimeType=` is left empty on purpose so the entry does not outrank the system one and steal the `text/markdown`/`text/plain` handler from `vscode`; the system-level associations from the package still apply
- **Omawrite package**: New `omawrite.conf` builds [omawrite](https://github.com/omacom-io/omawrite) — a dead-simple Qt Quick Markdown writing app — from source via its bundled PKGBUILD (`makepkg -fsi`), since it is only published through the Omarchy package repository. Also installs `xdg-desktop-portal-gtk`, which omawrite needs for its open/save pickers and dark/light mode detection. Not part of the default install; opt in with `source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install omawrite` or via `warchy-packages` (Alt+P). Update detection uses the built commit recorded in `$XDG_STATE_HOME/warchy/omawrite.version`, because upstream leaves `pkgver=0.1.0` pinned in the PKGBUILD while tagging v0.x releases
- **`warchy-obsidian paste` command**: New `warchy-obsidian paste [name]` creates a note/file in a vault directly from the clipboard — writes a `.md` note for text, or an image file (`.png`/`.jpg`/`.gif`/`.bmp`/`.webp`) if the clipboard holds an image (detected via `wl-paste --list-types`). Supports `-v vault`, `-f folder`, `--open`, `-y`, same as `copy`. Wired into `warchy-obsidian-tui` as "Create note from clipboard". New `obsclip()` bash function (alongside the existing `obs()`) added to `config/bash/functions` for quick clipboard-to-vault sharing
- **Foot `Ctrl+V` paste binding**: `clipboard-paste` now also bound to `Ctrl+V` (in addition to the default `Ctrl+Shift+V`/`XF86Paste`) for Windows-style pasting. Trade-off: `Ctrl+V` is intercepted at the terminal level, so it no longer reaches apps that use the raw `Ctrl+V` byte (e.g. bash readline's quoted-insert, vim visual-block mode). Only newly-opened foot windows pick up the change, since foot does not hot-reload `[key-bindings]`
- **Bun package**: New `bun.conf` installs Bun (`bun` from the `extra` repo) via pacman, with `BUN_INSTALL` redirected to `$XDG_DATA_HOME/bun` for XDG compliance
- **Claude Code package**: New `claude-code.conf` installs Anthropic's Claude Code CLI (`@anthropic-ai/claude-code`) via npm with version checking and XDG config migration support
- **WSLg `/mnt/shared_memory` mount**: New `mnt-shared_memory.mount` systemd unit (installed and enabled by `wsl-config.sh`) works around [microsoft/wslg#1456](https://github.com/microsoft/wslg/issues/1456). On WSL 2.7.3+, `/mnt/shared_memory` is not mounted, so WSLg falls back to `[WARN:COPY MODE]` and GUI windows show only a taskbar icon without rendering. Mounting tmpfs there before `local-fs.target` lets WSLg initialize its shared framebuffer normally.
- **SSH-centric security configuration**: GnuPG and keychain directories moved to `~/.ssh` (GNUPGHOME and KEYCHAIN_DIR environment variables)
- **XDG-compliant Docker configuration**: `DOCKER_CONFIG` merged into `docker.conf` (was a separate `docker-config.conf`); `DOCKER_CONFIG` also set in `config/bash/envs` baseline; `[post-install]` migrates `~/.docker` → `$XDG_CONFIG_HOME/docker` automatically
- **XDG-compliant .NET configuration**: `dotnet-config.conf` fixed (`DOTNET_HOME` → `DOTNET_CLI_HOME`) and added to `install.sh`; `DOTNET_CLI_HOME` added to `config/bash/envs` baseline
- **Meta-package support**: `warchy-pkg-manager` now accepts confs with no `[package]` section — runs `[env]` and `[post-install]`/`[post-remove]` hooks without installing any package
- **XDG-compliant .NET configuration**: .NET cache moved to `$XDG_CONFIG_HOME/dotnet` via DOTNET_HOME environment variable
- **mcpc**: Universal MCP CLI client added as optional package with XDG-compliant data directory (`MCPC_HOME_DIR`), discoverable in `warchy-packages` and application launcher
- **GitHub Copilot CLI**: Optional installation via `warchy-packages`, discoverable in application launcher
- **GnuPG and Keychain package configs**: Separate optional configurations for XDG-style management (`gnupg.conf`, `keychain.conf`)
- **Docker configuration package**: XDG-compliant Docker config moved to `~/.config/docker` (`docker-config.conf`)
- **.NET configuration package**: XDG-compliant .NET cache moved to `~/.config/dotnet` (`dotnet-config.conf`)

### Fixed
- **`warchy-shortcuts` and `warchy-snippets` showed an empty list under gum 2.0.0**: gum 2.0.0 (the Bubble Tea v2 / Lip Gloss v2 rewrite) regressed interactive `gum table` — it renders the column headers and the item count but no data rows and no border, regardless of `--widths`, `--height`, `--file` or piped stdin (`gum table --print` is unaffected, as are `gum choose` and `gum filter`). Both pickers now build their own space-padded columns and use `gum choose --label-delimiter`, which displays the padded row as the label and returns the raw command as the value. This also removes the CSV layer entirely: commands are no longer quoted, escaped, or re-parsed, so quotes and commas pass through untouched
- **`warchy-snippets` mangled commands containing quotes or commas**: The command was CSV-escaped before being handed to `gum table` (`"` → `""`), but the escaping was never reversed after selection — `sed 's/^"//; s/"$//'` only stripped the field's outer quotes. A snippet like `curl … -H "Authorization: Bearer …"` was therefore executed as `-H ""Authorization: …""`, which bash collapses to an empty argument. The same line used `cut -d',' -f2`, so any command containing a comma was truncated at it. Superseded by the `gum choose --label-delimiter` rewrite above, which passes the command through verbatim and needs no escaping at all
- **Login no longer hangs on the SSH passphrase prompt**: Two separate unbounded prompts sat between `wsl -d warchy` and a usable shell. First, keychain 3's multi-terminal gate (`[ 🔑 Press Enter to initialize keys 🔑 ]`) blocks in `select()` on `/dev/tty` forever — `config/bash/init` now passes `--immediate`, which contends for the activation lock straight away instead of gating on Enter. Second, `config/bash/init` points `SSH_ASKPASS` at the new `bin/utils/warchy-ssh-askpass` and sets `SSH_ASKPASS_REQUIRE=force` for the `keychain` call, so `ssh-add` collects the passphrase through the helper instead of its own unbounded terminal prompt. The helper prompts on `/dev/tty` with `read -t $WARCHY_SSH_ASKPASS_TIMEOUT` (default 20s, exported in `config/bash/envs`); on timeout — or on an empty answer, so `Enter` skips — it exits non-zero, `ssh-add` gives up, and the shell finishes starting with the agent running but the key unloaded (`keychain` prints `Unable to add keys`; load it later with `ssh-add ~/.ssh/id_*` or `keycheck`). `REQUIRE=force` is what makes `ssh-add` use an askpass even when a tty is present; without a tty at all (GUI launcher, systemd unit) the helper hands off to `$WARCHY_SSH_ASKPASS_GUI` (`lxqt-openssh-askpass`). Note a wrong passphrase still costs up to 3 × the timeout, since `ssh-add` re-invokes the askpass on each retry
- **`warchy-obsidian-tui` file picker**: Replaced `gum file` with an `fzf`-based flat file picker (`pick_file` helper) in "Copy file to vault" and the daily-note "append a file" prompt. `gum file` 0.17.0 has a rendering bug that silently drops the first entry of the directory listing (confirmed independent of window/terminal size), making some files appear "missing" or the list look clipped at the top. `gum choose` is unaffected and still used elsewhere
- **`obsidian-cli.desktop`**: Added `-T "Warchy Obsidian"` so the terminal window title reflects the app instead of the generic `foot` default; window height increased `1600x800` → `1600x1000`
- **wslg.sh**: Missing `/` path separator in `$XDG_RUNTIME_DIR/$(basename "$i")` symlink creation caused `Permission denied` errors on every login shell start (was trying to create files in root-owned `/run/user/` instead of the user's `/run/user/1000/`)
- **Copilot CLI startup hang**: Git credential helper in `~/.config/git/config` pointed to a hardcoded `gh` path (`/usr/local/bin/gh`) that no longer exists after pacman installs `gh` to `/usr/sbin/gh`. This caused copilot to prompt `Username for 'https://github.com':` at startup and freeze. Fixed by using `!gh` (PATH-relative). `warchy-user-setup` now auto-repairs stale hardcoded credential helper paths.

## [0.6.1] - 2026-01-25

### Added
- Animated screenshot gallery in `README.md`, backed by a new `assets/` folder — `warchy-demo.gif` plus stills for the launcher, package manager, shortcuts, snippets, about, btop, dua, opencode and yazi
- Screenshot regeneration instructions in `AGENT.md`, documenting how the `assets/` captures are produced and refreshed

### Fixed
- Desktop entries for `about`, `dua` and `foot`

## [0.6.0] - 2026-01-25

### Added
- **Passwordless sudo configuration**: New `install/pre-install/sudoers.sh` writes a `sudoers.d` drop-in for the commands warchy needs during installation, so the install no longer stops for a password mid-run
- `warchy-git-release -l` lists all existing tags
- WSL version check in `New-ArchWSL.ps1`, warning when the local WSL release is behind the latest available
- `rsync` added to the base package list

### Changed
- **Desktop entry metadata overhaul**: `Categories`, `Keywords` and `MimeType` reviewed and made consistent across all `.desktop` files; new entries added for `lazydocker`, `lazygit` and `vhdm`
- Keybindings now go through the `launch` wrapper for consistent terminal handling

### Fixed
- `warchy-launcher` no longer lists desktop entries marked `NoDisplay=true`

## [0.5.0] - 2026-01-24

### Added
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
  - Added inline documentation comments to git package .conf files
  - Examples for semantic versions and commit hash version checking
  - Best practices and troubleshooting guide
- **XDG-compliant Rust configuration**: rustup and cargo now redirect to `$XDG_DATA_HOME/rustup` and `$XDG_DATA_HOME/cargo` with automatic migration from old `~/.rustup` and `~/.cargo` locations
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
- `warchy-pacman` - Query Arch Linux packages with user-friendly output
- `open-image` function and `feh.desktop` entry for image viewing
- `cd` alias for `$WARCHY_PATH`
- Distro startup test after the Arch Linux installation completes
- Guard check in `New-ArchWSL.ps1` before starting the distro installation
- Alt+O keybinding for Opencode

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
- `warchy-shortcuts` now runs the selected shortcut on Enter
- Install transcript written to a temp directory and copied into the WSL distro at the end
- Warchy bin directories added to `PATH` by the installation script
- Executable-file migration now uses `find` instead of a fixed file list
- `.gitignore` extended to cover additional sensitive files and directories

### Fixed
- `--vhd-size` is no longer passed to `wsl --install` when unset; the flag only exists in WSL newer than 2.5.4
- Helper script sourcing used a path that broke depending on the caller's working directory
- Executable permissions corrected across the codebase
- Duplicate output removed from the installation transcript
- Log copy into the WSL distro

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

[Unreleased]: https://github.com/rjdinis-nos/warchy/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/rjdinis-nos/warchy/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/rjdinis-nos/warchy/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/rjdinis-nos/warchy/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/rjdinis-nos/warchy/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/rjdinis-nos/warchy/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/rjdinis-nos/warchy/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/rjdinis-nos/warchy/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/rjdinis-nos/warchy/releases/tag/v0.1.0
