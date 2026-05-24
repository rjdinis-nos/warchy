# Warchy Installation System

> For the full reference — flow diagrams, per-script detail, environment variables, troubleshooting, and customization guide — see **[INSTALLATION.md](INSTALLATION.md)**.

## How `install.sh` works

`install.sh` is a sequential orchestrator. It **sources** every sub-script via `run_logged` so all scripts share the same shell environment — variables set in one script carry forward to all subsequent ones.

### 1. Bootstrap

- Enforces `set -eEuo pipefail` — any error aborts immediately.
- Prepends all `bin/` subdirs to `$PATH` so Warchy tools are available during installation.
- Respects three control flags (all default to enabled):
  - `WARCHY_LOCAL_TEST` — shows the logo in red as a visual test-mode indicator.
  - `WARCHY_INSTALL_BASE` — controls whether base packages are installed.
  - `WARCHY_INSTALL_OPTIONAL` — controls optional packages.
- Sets XDG dirs (`~/.config`, `~/.cache`, etc.) if not already set.
- Runs `sudo pacman -Syu --needed gum base-devel` to ensure `gum` and build tools are present before anything else.
- Sources `helpers/logging.sh` which defines `run_logged`.

### `run_logged` — the core runner

Every stage is invoked through `run_logged`. It:
- **`source`s** the script (not `bash …`) so exported env vars propagate.
- Prints a timestamped banner before and after each script.
- Sets `CURRENT_SCRIPT` for error context.

### 2. Pre-Installation

Validates prerequisites before making any changes.

| Script | Purpose |
|---|---|
| `guard.sh` | Checks: vanilla Arch, not root, x86_64, no DE pre-installed |
| `show-env.sh` | Prints current env for visibility |
| `user.sh` | Validates user has sudo, home dir exists |
| `pacman.sh` | Mirrors, keyring, parallel downloads |
| `first-run-mode.sh` | Detects fresh vs re-install |

### 3. System Configuration

Deploys configs and sets up services.

| Script | Purpose |
|---|---|
| `xdg-setup.sh` | Creates XDG dirs, migrates Warchy binaries to `~/.local/bin/warchy/` |
| `dotfiles.sh` | Copies `config/*` → `~/.config/`, deploys `~/.bashrc` |
| `wsl-config.sh` | WSL interop, tmpfiles.d, binfmt |
| `applications.sh` | `.desktop` files, `x-terminal-emulator` symlink |
| `dev-tools.sh` | wget XDG config |
| `scripts.sh` | Sets executable permissions on all scripts |
| `systemd.sh` | Journal limits, SSH agent service, man-db, dunst, WSL remount |
| `ssh-flakiness.sh` | `UseDNS no`, `GSSAPIAuthentication no` in sshd_config |
| `fast-shutdown.sh` | `DefaultTimeoutStopSec=5s` in systemd |
| `usb-autosuspend.sh` | `usbcore.autosuspend=-1` kernel param |
| `increase-sudo-tries.sh` | `passwd_tries=10` in sudoers |

### 4. Base Packages _(guarded by `WARCHY_INSTALL_BASE`)_

Installs packages from `warchy-base.packages` via pacman `--needed`, then initialises the `plocate` file database.

### 5. Optional Packages _(guarded by `WARCHY_INSTALL_OPTIONAL`)_

Installs optional pacman packages, then uses `warchy-pkg-manager` (sourced, not executed) to install config-driven packages: `go`, `yay`, AUR packages, Intel Arc GPU drivers, `vhdm`, `docker`, `gcloud`, `npm`, `pnpm`.

Each config-driven package is defined by a `.conf` file under `config/warchy/install/` (e.g. `docker.conf`, `vhdm.conf`, `gcloud.conf`). These files declare the packages to install, environment variables to export, and pre/post-install hooks.

> `warchy-pkg-manager` must be **sourced** — running it as a subprocess silently drops its exported env vars.

### 6. Setup

| Script | Purpose |
|---|---|
| `ssh-agent.sh` | Enables systemd user SSH agent service |
| `nvim.sh` | Clones LazyVim starter config into `~/.config/nvim` |
| `allow-reboot.sh` | Polkit rule granting wheel group reboot/shutdown without password |

### 7. First-run marker

Creates `~/.local/state/warchy/first-run-pending`. On the first login after install, `~/.config/bash/init` detects this file, sources `post-install/first-run.sh` (cache cleanup, orphan removal, sudoers cleanup), then **removes its own detection block** from `init` — a self-cleaning one-shot mechanism.

---

## Quick reference

```bash
# Test mode — skips git clone, shows red logo
WARCHY_LOCAL_TEST=1 bash install.warchy.sh

# Skip optional packages
WARCHY_INSTALL_OPTIONAL=0 bash install/install.sh

# Run a single stage directly
bash install/pre-install/guard.sh

# Debug trace
bash -x install/install.sh
```

## Directory structure

```
install/
├── install.sh                  # Main orchestrator
├── warchy-base.packages        # Base package list
├── warchy-optional.packages    # Optional pacman packages
├── warchy-yay.packages         # Optional AUR packages
├── helpers/logging.sh          # run_logged + log_* functions
├── pre-install/                # Validation scripts
├── config/                     # System configuration scripts
├── packaging/                  # Package installation scripts
├── setup/                      # Post-package setup scripts
└── post-install/first-run.sh  # First-login cleanup (self-removing)
```

## Full documentation

**[INSTALLATION.md](INSTALLATION.md)** — complete reference including per-script details, environment variables table, error handling, customization guide, and troubleshooting.
