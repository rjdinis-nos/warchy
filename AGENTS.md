# AGENTS.md — Warchy

> Quick-ramp context for AI agents. For complete guidelines see **[DEVELOPMENT.md](DEVELOPMENT.md)**.

## What this repo is

Bash-only automation framework that bootstraps an opinionated Arch Linux environment inside WSL2. No build system, no package.json/Cargo.toml/go.mod — the project *installs* those tools, it does not use them itself.

## Critical gotchas

**`warchy-pkg-manager` must be sourced, not executed.**
It exports env vars to the calling shell; running it with `bash …` silently skips those exports.
```bash
# correct
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install docker
# wrong — env vars will not propagate
bash "$WARCHY_PATH/bin/install/warchy-pkg-manager" install docker
```

**Source tree ≠ deployed files.**
Installation copies files to the user environment:
```
$WARCHY_PATH/bin/*    → ~/.local/bin/warchy/
$WARCHY_PATH/config/* → ~/.config/
$WARCHY_PATH/default/bashrc → ~/.bashrc
```
Edit source files in `$WARCHY_PATH`, then ask the user for permission before overwriting deployed copies. Never silently overwrite `~/.config/git/config`, `~/.bashrc`, `~/.config/bash/*`, or anything in `~/.local/bin/warchy/`.

**`run_logged` sources scripts, it does not execute them** — this is intentional to preserve env context across installation stages.

**`bash -lc` not `-ilc`** when calling bash from PowerShell integration. The `-i` flag hangs.

## Required script header

All bash scripts:
```bash
#!/bin/bash
set -eEuo pipefail
```
Bootstrap/POSIX scripts (`install.warchy.sh`):
```bash
#!/bin/sh
set -e
```

## Developer commands

```bash
# Test mode — skips git clone, shows red logo as visual indicator
WARCHY_LOCAL_TEST=1 bash install.warchy.sh

# Run full install from local clone
bash ~/.local/share/warchy/install/install.sh

# Skip optional packages
WARCHY_INSTALL_OPTIONAL=0 bash install/install.sh

# Run a single stage directly (for targeted testing)
bash install/pre-install/guard.sh
bash install/config/dotfiles.sh

# Debug trace
bash -x install/install.sh

# Lint (manual, not automated)
shellcheck bin/warchy-launcher
```

No automated test suite exists. Manual testing requires a fresh Arch Linux VM or WSL, non-root user with sudo, no DE pre-installed.

## Key environment variables

| Variable | Default | Notes |
|---|---|---|
| `WARCHY_PATH` | `~/.local/share/warchy` | Must be set before running install.sh directly |
| `WARCHY_INSTALL` | `$WARCHY_PATH/install` | |
| `WARCHY_INSTALL_BASE` | `1` | |
| `WARCHY_INSTALL_OPTIONAL` | `1` | Set to `0` to skip optional packages |
| `WARCHY_LOCAL_TEST` | unset | Set to `1` for test mode |
| `WARCHY_BRANCH` | `main` | Bootstrap branch override |

Always use `$WARCHY_PATH` and `$XDG_*` variables — never hardcode paths.

## Conventions

- **gum colors**: `--foreground 2` = success, `--foreground 1` = error, `--foreground 3` = warning
- **Pacman installs always use `--needed`** for idempotency
- **File naming**: `kebab-case.sh` for scripts, `*.packages` for package lists, `*.conf` for package configs
- **Variable naming**: `WARCHY_*` for exported globals; `LOCAL_VAR` for script-local; `snake_case` for function-local
- **Function naming**: `snake_case`, verb-first (e.g. `start_install_log`)
- Define functions once, source everywhere — no duplicate function definitions across files

## Package system

- Simple packages → add to `install/warchy-base.packages` or `install/warchy-optional.packages` (one per line, `#` comments)
- Config-based packages → create `config/warchy/install/mypackage.conf` (sections: `[package]`, `[env]`, `[post-install]`)
- AUR packages → `install/warchy-yay.packages`

See **[PACKAGING.md](docs/PACKAGING.md)** for the full reference including git builds, env var persistence, version checking, and the helper function API.

## Documentation

Update **CHANGELOG.md** (Keep a Changelog format, `[Unreleased]` section) for any user-facing change. Update **DEVELOPMENT.md** when adding new patterns or standards. The root README.md is summaries + links only — put detail in subsystem READMEs.

## First-run self-cleaning mechanism

Installation writes `~/.local/state/warchy/first-run-pending`. On first login, bash `init` detects it, sources `post-install/first-run.sh`, then removes its own detection block from `~/.config/bash/init`. This is intentional — do not break the self-modification logic.
