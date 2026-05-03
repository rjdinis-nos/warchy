# Warchy Bin Scripts

This directory contains the main utility scripts for Warchy, providing interactive tools and system integrations.

## Scripts Overview

### [`warchy-launcher`](warchy-launcher)

**Interactive Application Launcher**

A beautiful TUI application launcher that displays and executes desktop applications (`.desktop` files).

**Features**:
- 📦 Scans `$XDG_DATA_HOME/applications` for desktop entries
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
