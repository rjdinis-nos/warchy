# Warchy Bin Scripts

This directory contains the main utility scripts for Warchy, providing interactive tools and system integrations.

## Scripts Overview

### [`warchy-launcher`](warchy-launcher)

**Interactive Application Launcher**

A beautiful TUI application launcher that displays and executes desktop applications (`.desktop` files).

**Features**:
- 📦 Scans `$XDG_DATA_HOME/applications` for desktop entries
- ✅ Hides entries whose app is not installed (see below)
- 🎨 Icon-based categorization (Utility, Development, Network, System, etc.)
- 📝 Displays application names and descriptions
- 🕐 Tracks recently used applications in cache
- ⌨️ Fuzzy search with `gum` integration
- 🚀 Executes selected applications via their desktop file commands

**Usage**:
```bash
warchy-launcher
```

**Keyboard Shortcut**: `Alt+A` (Application launcher)

**Installed-app filtering**

Warchy ships desktop entries for optional tools, so an entry existing does not mean its app is present. The launcher skips entries it can prove are unusable, using the freedesktop [`TryExec`](https://specifications.freedesktop.org/desktop-entry-spec/latest/recognized-keys.html) key:

| Entry declares | Launcher checks |
|---|---|
| `TryExec=btop` | `btop` resolves on `$PATH` (or is an executable absolute path) |
| no `TryExec` | falls back to the first token of `Exec=` |
| neither key | entry is kept — an entry that cannot be evaluated is not evidence of absence |

`TryExec` is required rather than optional because most warchy entries wrap the real binary in a terminal:

```ini
Exec=xdg-terminal-exec -- -T "BTOP" -w 1600x800 btop
TryExec=btop
```

The first `Exec` token is `xdg-terminal-exec`, which is always installed — so `Exec` alone can never tell you whether `btop` is there. **Any new entry added to `default/applications/` should declare `TryExec` naming the binary that actually has to exist**, which is not always the package name (e.g. `spotify-player` ships `spotify_player`, `vhdm` ships `vhdm-tui`).

When entries are hidden, the fzf header notes the count, so a missing app is explainable rather than a mystery:

```
Source: /home/user/.local/share/applications/*desktop  (1 hidden: app not installed)
```

---

### [`warchy-notify`](warchy-notify)

**WSL-Windows Notification Bridge**

Sends Windows 11 toast notifications from WSL using PowerShell scripts.

**Features**:
- 💬 Cross-platform notification system (WSL → Windows)
- 🔔 Support for multiple severity levels (info, warn, error, critical)
- ⏱️ Configurable expiration times
- 🎨 Custom icon support
- 📁 Automatic icon mirroring to Windows temp directory
- 🖼️ Reads distribution icon from `/etc/wsl-distribution.conf`

**Usage**:
```bash
warchy-notify -t "Title" -m "Message" [options]
```

**Options**:
- `-t, --title` - Notification title (required)
- `-m, --message` - Notification body (required)
- `-l, --level` - Severity level: info, warn, error, critical (default: info)
- `-e, --expire` - Expiration time in minutes (default: 5)

**Example**:
```bash
warchy-notify -t "Build Complete" -m "Project built successfully" -l info -e 5
```

---

### [`warchy-packages`](warchy-packages)

**Interactive Package Manager**

A TUI browser for managing Warchy's configuration-based package system.

**Features**:
- 📦 Displays all available package configurations
- ✓ Shows installation status (Installed / Not Installed)
- 🔍 Lists package details (name, installer, type)
- ⚙️ Interactive install/remove operations
- 🎨 Color-coded status indicators
- 📋 Supports pacman, yay (AUR), and git-based packages

**Usage**:
```bash
warchy-packages
```

**Keyboard Shortcut**: `Alt+P` (Packages)

**What it does**:
1. Scans `~/.config/warchy/install/*.conf` for package configurations
2. Checks installation status for each package
3. Displays interactive list with `gum choose`
4. Sources `warchy-pkg-manager` to install/remove selected packages
5. Exports environment variables to current shell session

---

### [`warchy-scripts`](warchy-scripts)

**Script Selector & Runner**

A simple wrapper that launches the interactive script runner in the `bin/` directory.

**Features**:
- 🗂️ Browse all scripts in `$WARCHY_PATH/bin/`
- 🚀 Execute selected scripts
- 🔍 Uses `warchy-run` utility for script selection

**Usage**:
```bash
warchy-scripts
```

**What it does**:
```bash
bash -c "$WARCHY_PATH/bin/utils/warchy-run $WARCHY_PATH/bin/"
```

This provides a convenient way to explore and run any script in the bin directory without navigating the filesystem.

---

### [`warchy-shortcuts`](warchy-shortcuts)

**Keyboard Shortcuts Display**

Displays all configured keyboard shortcuts from your bash keybindings file in a beautiful, categorized format.

**Features**:
- ⌨️ Reads keybindings from `$XDG_CONFIG_HOME/bash/keybindings`
- 🎨 Color-coded display using Catppuccin Mocha theme
- 📋 Organized by categories (e.g., Navigation, Completion, History)
- 🔄 Standardizes shortcut notation (Ctrl+, Alt+)
- 📖 Shows descriptions and command actions
- 🖼️ Formatted table output with `gum` styling

**Usage**:
```bash
warchy-shortcuts
```

**Keyboard Shortcut**: `Alt+K` (Keybindings)

**Display Format**:
```
Category: Navigation
┌─────────────┬───────────────────────────────────────┬──────────────────┐
│ Shortcut    │ Description                           │ Command          │
├─────────────┼───────────────────────────────────────┼──────────────────┤
│ Ctrl+Space  │ Open application launcher             │ warchy-launcher  │
│ Alt+A       │ Open application launcher             │ warchy-launcher  │
└─────────────┴───────────────────────────────────────┴──────────────────┘
```

---

### [`warchy-snippets`](warchy-snippets)

**Command Snippets Browser**

Displays a searchable, categorized list of useful command snippets and examples.

**Features**:
- 📝 Reads commands from `$XDG_CONFIG_HOME/warchy/commands`
- 🗂️ Organizes snippets by category (Docker, Git, System, Network, etc.)
- 🔍 Fuzzy search with `gum` filter
- 📋 Copies selected command to clipboard (via `wl-copy`)
- 🎨 Color-coded display using Catppuccin Mocha theme
- 💡 Shows command description and category

**Usage**:
```bash
warchy-snippets
```

**Keyboard Shortcut**: `Alt+S` (Snippets)

**Command File Format** (`~/.config/warchy/commands`):
```
command#Category#Description
docker ps -a#Docker#List all containers (running and stopped)
git log --oneline --graph#Git#Show commit history as graph
```

**Display Format**:
- Category badge (color-coded)
- Command text (highlighted)
- Description (subtle color)

When you select a snippet, it's automatically copied to your clipboard and displayed for confirmation.

---

## Subdirectories

### [`apps/`](apps/)
Application wrappers and launchers (e.g., `warchy-gemini` for Gemini CLI)

### [`install/`](install/)
Package management system - see [install/README.md](install/README.md) for details

### [`utils/`](utils/)
System utility scripts (version, branch, drive-info, environment inspection, etc.)

#### [`utils/warchy-color-scheme`](utils/warchy-color-scheme)

**System Light/Dark Color Scheme Reporter**

Shows the color scheme that portal-aware GUI apps follow, and where that value comes from. Useful for diagnosing why an app (e.g. `omawrite`) is not following the system theme under WSLg.

**Features**:
- 🎨 Reports the *effective* scheme: `dark`, `light`, or `no-preference`
- 🔌 Reads `org.freedesktop.appearance color-scheme` from `xdg-desktop-portal` over D-Bus (authoritative)
- ⚙️ Falls back to GSettings `org.gnome.desktop.interface color-scheme` (what the GTK backend exposes)
- 🧩 Reports which `org.freedesktop.impl.portal.Settings` backend is installed — without one the portal answers but can never express a preference
- 🤖 `-q` prints a single word for scripting

**Usage**:
```bash
warchy-color-scheme          # full report
warchy-color-scheme -q       # dark | light | no-preference
```

**Options**:
- `-q, --quiet` - Print only the effective scheme, for scripting
- `-h, --help` - Show help

**Exit Status**:
- `0` - a scheme was determined
- `1` - the portal is unreachable **and** no GSettings preference could be read

**Example Output**:
```
System color scheme

  Effective             no-preference

  xdg-desktop-portal    no-preference  (org.freedesktop.appearance color-scheme)
  GSettings             no-preference  (org.gnome.desktop.interface color-scheme)
  Settings backend      xdg-desktop-portal-gtk

  No preference set — apps fall back to their own default.
  Set one with: gsettings set org.gnome.desktop.interface color-scheme prefer-dark
```

#### [`utils/warchy-list-keyring`](utils/warchy-list-keyring)

**GNOME Keyring Item Lister**

Lists what is stored in the Secret Service (gnome-keyring), grouped by collection. `secret-tool` can only look up attributes it is already given, so enumeration goes over the Secret Service D-Bus API instead.

**Features**:
- 🔑 Groups items by collection, showing each collection's lock state
- 🏷️ Prints every item's label and attributes
- 🔒 Never reads secret *values* — only labels and attributes
- 🤖 `-q` prints bare labels, one per line, for scripting
- Aliased as the `keyring-list` shell function

**Usage**:
```bash
warchy-list-keyring          # full report
warchy-list-keyring -q       # item labels only
warchy-list-keyring --raw    # TSV: collection, label, attributes
keyring-list                 # shell function alias
```

**Options**:
- `-q, --quiet` - Print only item labels, one per line
- `--raw` - Tab-separated collection, label and attributes (consumed by `warchy-keyring`)
- `-h, --help` - Show help

**Exit Status**:
- `0` - the keyring was queried successfully
- `1` - `gdbus` is missing, or the Secret Service is unreachable

**Example Output**:
```
=== Default keyring (locked=false) ===
  copilot-cli/https://github.com:rjdinis-nos
      'account': 'https://github.com:rjdinis-nos', 'service': 'copilot-cli', 'xdg:schema': 'org.freedesktop.Secret.Generic'

=== Login (locked=true) ===
  (empty)
```

> Locked collections report as empty until they are unlocked.

#### [`utils/warchy-keyring`](utils/warchy-keyring)

**Interactive Keyring Manager**

A `gum` TUI for managing secrets in gnome-keyring. Enumeration is delegated to `warchy-list-keyring --raw`, so the D-Bus walk lives in one place.

**Features**:
- 📋 List all items
- ➕ Add a secret, prompting for a label, arbitrary attribute pairs, and the value (masked input)
- 👁 Reveal a secret, behind a confirmation prompt
- 📎 Copy a secret to the clipboard via `wl-copy`
- 🗑 Delete a secret, behind a confirmation prompt

**Usage**:
```bash
warchy-keyring
```

Also available from the application launcher (`Alt+A`) as **Keyring Manager**.

**Options**:
- `-h, --help` - Show help

**Exit Status**:
- `0` - exited normally
- `1` - a required tool is missing, or the Secret Service is unreachable

> An item is identified by its **attribute set**, not its label — two items may share a label. Every lookup and delete replays the item's full attribute set, parsed back out of the listing.

**How the layers relate**: the portal value wins; GSettings is the fallback reading and, with the GTK backend installed, is also what *feeds* the portal — so changing it propagates to the portal API and out to running apps via the `SettingChanged` signal. `no-preference` (portal value `0`) is not "light": it means nothing has expressed a preference, so each app applies its own default.

---

## Common Usage Patterns

### Keyboard Shortcuts

All main scripts are accessible via keyboard shortcuts defined in `~/.config/bash/keybindings`:

| Shortcut | Script | Description |
|----------|--------|-------------|
| `Alt+A` | `warchy-launcher` | Launch applications |
| `Alt+P` | `warchy-packages` | Manage packages |
| `Alt+K` | `warchy-shortcuts` | View keybindings |
| `Alt+S` | `warchy-snippets` | Browse command snippets |

### Styling & Colors

All scripts use the **Catppuccin Mocha** color scheme for consistent, beautiful output:

- **Pink** (`#f5c2e7`) - Highlights and selections
- **Mauve** (`#cba6f7`) - Commands and actions
- **Blue** (`#89b4fa`) - Links and references
- **Yellow** (`#f9e2af`) - Warnings and notices
- **Text** (`#cdd6f4`) - Primary text
- **Surface** (`#45475a`) - Borders and separators

### Integration with `gum`

All interactive scripts leverage [gum](https://github.com/charmbracelet/gum) for:
- `gum choose` - Selection menus
- `gum filter` - Fuzzy search
- `gum style` - Colored output
- `gum confirm` - Yes/No prompts

---

## Development

### Adding a New Script

1. Create the script in `bin/` directory
2. Use the standard shebang: `#!/usr/bin/env bash`
3. Set strict mode: `set -euo pipefail`
4. Make it executable: `chmod +x bin/warchy-newscript`
5. Add keybinding in `config/bash/keybindings`
6. Update this README

### Script Conventions

- **Error Handling**: Use `set -euo pipefail` for strict error handling
- **Styling**: Use Catppuccin Mocha colors for consistency
- **XDG Compliance**: Respect `XDG_*` environment variables
- **Dependencies**: Check for required tools (gum, wl-clipboard, etc.)
- **Help Text**: Provide usage instructions with `--help` or error messages

---

## Related Documentation

- [install/README.md](install/README.md) - Package management system documentation
- [../README.md](../README.md) - Main project documentation
- [../DEVELOPMENT.md](../DEVELOPMENT.md) - Developer guidelines
- [../CHANGELOG.md](../CHANGELOG.md) - Historical changes and decisions
