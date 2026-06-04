# PACKAGING.md — Warchy Package Management

Three distinct methods exist for adding packages. Choose based on where the package lives:

| Method | When to use | File to edit |
|--------|-------------|--------------|
| Package list | Simple pacman/yay install, no config needed | `install/warchy-*.packages` |
| `.conf` file | Needs env vars, hooks, or complex setup | `config/warchy/install/<name>.conf` |
| Git build | Must be compiled from source | `config/warchy/install/<name>.conf` with `[git]` |

---

## Method 1 — Package lists

Plain text, one package per line, `#` for comments.

```
install/warchy-base.packages      # essential, always installed
install/warchy-optional.packages  # optional, skipped with WARCHY_INSTALL_OPTIONAL=0
install/warchy-yay.packages       # AUR packages (require yay to be installed first)
```

Packages are installed via `sudo pacman -S --noconfirm --needed` (always idempotent).

---

## Method 2 — Regular package `.conf`

For packages that need environment variables, pre/post hooks, or multi-package installs.

Config file location: `config/warchy/install/<name>.conf`  
Deployed to: `~/.config/warchy/install/<name>.conf`

```ini
[package]
PACKAGE_NAME=docker docker-compose docker-buildx   # space-separated, all installed together
PACKAGE_INSTALLER=pacman                           # pacman or yay

[env]                                              # optional — exports to shell + saves to ~/.config/bash/envs
GOPATH="$XDG_DATA_HOME/go"
GOBIN="$GOPATH/bin"
PATH="$GOBIN"                                      # PATH entries are prepended: export PATH="<value>:$PATH"

[pre-install]                                      # optional — runs before package install
mkdir -p "$HOME/.local/myapp"

[post-install]                                     # optional — runs only if install succeeded
sudo systemctl enable --now docker.service
sudo usermod -aG docker "$USER"

[post-remove]                                      # optional — cleanup after removal
sudo rm -f /etc/docker/daemon.json
```

### Usage

```bash
# Must be sourced — exports env vars to current shell
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install docker
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" remove docker

# warchy-pkg is executed (not sourced) — no env export, direct pacman/yay only
warchy-pkg install pacman package1 package2
warchy-pkg remove yay aur-package
```

---

## Method 3 — Git build `.conf`

For packages built from source. Detected by the presence of a `[git]` section.

```ini
[git]
GIT_REPO=https://aur.archlinux.org/yay.git       # cloned with --depth 1

[dependencies]
BUILD_DEPS=base-devel cmake                        # kept permanently
TEMP_BUILD_DEPS=go pkgconf                         # removed after build (only if not pre-installed)

[version]                                          # omit to always rebuild
yay --version 2>&1 | grep -oP 'v\K[\d.]+' | head -1
# For commit-hash versioning:
# mytool version 2>&1 | grep -oP 'version \K[a-f0-9]+' | head -1

[build]                                            # runs inside the cloned repo dir
makepkg -si --noconfirm

[env]                                              # same as regular packages
PATH="$HOME/.local/bin"

[uninstall]                                        # equivalent of post-remove for git packages
sudo rm -f /usr/local/bin/mytool
```

### Version checking logic

1. Runs the `[version]` command to get the installed version.
2. Fetches the repo version from: git tags → PKGBUILD `pkgver=` → latest commit hash.
3. Skips rebuild if installed version equals or exceeds repo version.
4. Omitting `[version]` causes unconditional rebuild on every run.

### `TEMP_BUILD_DEPS` safety rule

Pre-existing packages are **never removed**, even if listed in `TEMP_BUILD_DEPS`. Only packages that were absent before the build started get cleaned up afterwards.

---

## Environment variable persistence

`[env]` variables are:
- Exported to the **current shell session** immediately (requires `source`)
- Written to `~/.config/bash/envs` for persistence across sessions
- Removed from both on `remove`

XDG variables in config files are auto-expanded with fallbacks:

| In `.conf` | Expands to |
|---|---|
| `$XDG_DATA_HOME` | `${XDG_DATA_HOME:-$HOME/.local/share}` |
| `$XDG_CONFIG_HOME` | `${XDG_CONFIG_HOME:-$HOME/.config}` |
| `$XDG_CACHE_HOME` | `${XDG_CACHE_HOME:-$HOME/.cache}` |
| `$XDG_STATE_HOME` | `${XDG_STATE_HOME:-$HOME/.local/state}` |

---

## Interactive browser

```bash
warchy-packages   # or Alt+P — TUI for browsing and managing all configured packages
```

New `.conf` files appear in the browser automatically.

---

## Helper function reference

Located in `bin/install/helpers/`, loaded via `bin/install/warchy-install-helpers.sh`.

| Function | File | Purpose |
|---|---|---|
| `check_if_script_is_sourced` | `validation.sh` | Enforce sourcing |
| `check_if_script_is_executed` | `validation.sh` | Enforce execution |
| `get_operation` | `validation.sh` | Validate `install`/`remove` arg |
| `get_package_manager` | `validation.sh` | Validate `pacman`/`yay` arg |
| `is_installed(pkg, type)` | `package.sh` | Check installation status |
| `get_package_type(config)` | `package.sh` | Returns `git` or `package` |
| `check_git_package_version(pkg, repo, cmd)` | `package.sh` | Returns 0 if should install, 1 if up-to-date |
| `load_package_config(config)` | `package.sh` | Parse `[package]` conf |
| `load_git_package_config(config)` | `package.sh` | Parse `[git]` conf |
| `run_install_commands(type, pkg, cmds)` | `package.sh` | Execute pre/post hooks |
| `install_env_config(file, config)` | `env.sh` | Export + persist env vars |
| `remove_env_config(file, config)` | `env.sh` | Unset + remove env vars |

---

## Adding a new package — checklist

1. **Choose method**: list (simple) vs `.conf` (complex/env) vs git (build from source)
2. **Create or edit** the appropriate file under `config/warchy/install/` or `install/*.packages`
3. **Test** install and remove:
   ```bash
   source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install mypackage
   source "$WARCHY_PATH/bin/install/warchy-pkg-manager" remove mypackage
   ```
4. **Verify** env vars are set/unset correctly in the current shell
5. **Update CHANGELOG.md** if the package is user-facing

---

## Related documentation

- [`config/warchy/install/README.md`](config/warchy/install/README.md) — full section reference with all examples
- [`bin/install/README.md`](bin/install/README.md) — architecture and component overview
