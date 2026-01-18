# Package Configuration Files

This directory contains configuration files for the Warchy package management system. Each `.conf` file defines how a package should be installed, configured, and removed.

## Overview

Package configurations use an INI-style format with different sections for regular packages (from repos/AUR) and git-based packages (built from source). The package manager (`warchy-pkg-manager`) reads these files to automate installation, dependency management, environment setup, and cleanup.

## Configuration File Types

### Regular Package Configuration

For packages available in official Arch repos or AUR:

```ini
[package]
PACKAGE_NAME=package1 package2 package3
PACKAGE_INSTALLER=pacman  # or yay

[env]
MY_VAR="value"
ANOTHER_VAR="$HOME/.local/myapp"
PATH="$HOME/.local/myapp/bin"

[pre-install]
# Optional: Commands to run before package installation
echo "Preparing for installation..."
mkdir -p "$HOME/.local/myapp"

[post-install]
# Optional: Commands to run after package installation
sudo systemctl enable --now myservice.service
echo "Installation complete!"

[post-remove]
# Optional: Cleanup commands after package removal
sudo rm -rf /etc/myapp
rm -rf "$HOME/.local/myapp"
```

### Git-Based Package Configuration

For packages built from source with optional version checking and dependency management:

```ini
# [dependencies] section:
#   - TEMP_BUILD_DEPS: Packages needed only for building (removed after build)
#   - BUILD_DEPS: Packages needed permanently (kept after build)
#   - Only installs if not already present
#   - Preserves pre-existing packages (won't remove if already installed)
#
# [version] section:
#   - Command to get installed version (one line output)
#   - For commit-based versions: Extract 7+ character hex hash (e.g., 'ed06abf')
#   - For semantic versions: Extract version number (e.g., '1.2.3')
#   - Without this section, package will always reinstall
#
# Examples:
#   Commit hash: mytool version 2>&1 | grep -oP 'version \K[a-f0-9]+' | head -1
#   Semantic:    mytool --version 2>&1 | grep -oP 'v\K[\d.]+' | head -1

[git]
GIT_REPO=https://github.com/user/repo.git

[dependencies]
BUILD_DEPS=base-devel cmake gcc
TEMP_BUILD_DEPS=pkgconf autoconf

[version]
mytool --version 2>&1 | grep -oP 'v\K[\d.]+' | head -1

[build]
# Commands to build and install
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build build
sudo cmake --install build

[env]
PATH="$HOME/.local/bin"
MY_APP_HOME="$HOME/.local/myapp"

[uninstall]
# Commands to uninstall
sudo cmake --build build --target uninstall
rm -rf "$HOME/.local/myapp"
```

## Configuration Sections Reference

### `[package]` Section

**Required for**: Regular packages  
**Purpose**: Define which packages to install and which package manager to use

**Fields**:
- `PACKAGE_NAME` - Space-separated list of package names
- `PACKAGE_INSTALLER` - Either `pacman` or `yay`

**Example**:
```ini
[package]
PACKAGE_NAME=docker docker-compose docker-buildx lazydocker
PACKAGE_INSTALLER=pacman
```

---

### `[git]` Section

**Required for**: Git-based packages  
**Purpose**: Define the source repository

**Fields**:
- `GIT_REPO` - Full URL to git repository (GitHub, GitLab, AUR, etc.)

**Example**:
```ini
[git]
GIT_REPO=https://github.com/user/project.git
```

**Note**: The repository will be cloned with `--depth 1` for efficiency.

---

### `[dependencies]` Section

**Required for**: Git-based packages with build dependencies  
**Purpose**: Manage build-time dependencies

**Fields**:
- `BUILD_DEPS` - Permanent dependencies (kept after installation)
- `TEMP_BUILD_DEPS` - Temporary dependencies (removed after build completes)

**Example**:
```ini
[dependencies]
BUILD_DEPS=base-devel cmake
TEMP_BUILD_DEPS=go autoconf pkgconf
```

**Behavior**:
- Dependencies only installed if not already present
- Pre-existing packages are preserved (never removed, even if listed in `TEMP_BUILD_DEPS`)
- Temporary dependencies removed only if installed by this build process
- Uses same package manager logic as regular packages

**Leave empty** if no dependencies needed:
```ini
[dependencies]
BUILD_DEPS=
TEMP_BUILD_DEPS=
```

---

### `[version]` Section

**Required for**: Git packages that should skip reinstallation when up-to-date  
**Optional for**: Git packages that should always rebuild  
**Purpose**: Check if installed version matches repository version

**Format**: A shell command that outputs the installed version (one line, no extra text)

#### Semantic Version Example

For packages with version tags like `v1.2.3`:

```ini
[version]
mytool --version 2>&1 | grep -oP 'v\K[\d.]+' | head -1
```

**Output example**: `1.2.3`

**Comparison logic**:
- Fetches latest version from git tags (e.g., `v1.2.0`)
- Falls back to PKGBUILD `pkgver=` line if no tags
- Compares using version sort (`sort -V`)
- Skips installation if installed version equals or exceeds repo version

#### Commit Hash Example

For packages versioned by git commits:

```ini
[version]
mytool version 2>&1 | grep -oP 'version \K[a-f0-9]+' | head -1
```

**Output example**: `ed06abf`

**Comparison logic**:
- Detects commit hashes (7+ character hex strings)
- Fetches latest commit from repository `HEAD`
- Direct string comparison
- Skips installation if hashes match

#### Version Check Flow

1. Execute version command to get installed version
2. Try to determine repository version from:
   - Git tags (e.g., `refs/tags/v1.2.0`)
   - PKGBUILD `pkgver=` field
   - Latest commit hash from `HEAD`
3. Compare versions:
   - **Semantic versions**: Use version sorting
   - **Commit hashes**: Direct string match
   - **Unknown**: Proceed with installation

**If omitted**: Package will always reinstall (no version checking).

---

### `[build]` Section

**Required for**: Git-based packages  
**Purpose**: Define build and installation commands

**Format**: Multi-line shell commands executed sequentially

**Example**:
```ini
[build]
./autogen.sh
./configure --prefix=/usr/local
make -j$(nproc)
sudo make install
```

**Execution**:
- Commands run inside the cloned repository directory
- Each command must succeed (non-zero exit stops build)
- Runs after all dependencies are installed
- Current directory is the temporary build directory

**Common patterns**:
```ini
# Makefile-based
make
sudo make install

# CMake-based
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build build
sudo cmake --install build

# Go-based
go build -o mybinary ./cmd/main
sudo install -m 755 mybinary /usr/local/bin/

# AUR package
makepkg -si --noconfirm

# Python
python -m pip install --user .
```

---

### `[env]` Section

**Optional for**: Both regular and git packages  
**Purpose**: Define environment variables to export

**Format**: `VARIABLE="value"` or `PATH="directory"`

**Example**:
```ini
[env]
GOPATH="$HOME/go"
GOBIN="$GOPATH/bin"
GOCACHE="$XDG_CACHE_HOME/go-build"
PATH="$HOME/go/bin"
```

**Behavior**:
- Variables exported to current shell session (requires sourcing `warchy-pkg-manager`)
- Variables saved to `~/.config/bash/envs` for persistence
- `PATH` entries are prepended (not replaced): `export PATH="/new/path:$PATH"`
- Other variables exported as-is: `export GOPATH="/home/user/go"`

**XDG Variable Expansion**:
The following variables are automatically expanded:
- `$XDG_DATA_HOME` → `${XDG_DATA_HOME:-$HOME/.local/share}`
- `$XDG_CONFIG_HOME` → `${XDG_CONFIG_HOME:-$HOME/.config}`
- `$XDG_CACHE_HOME` → `${XDG_CACHE_HOME:-$HOME/.cache}`
- `$XDG_STATE_HOME` → `${XDG_STATE_HOME:-$HOME/.local/state}`

**On removal**:
- Variables unset from current shell
- Entries removed from `~/.config/bash/envs`

---

### `[pre-install]` Section

**Optional for**: Regular packages  
**Purpose**: Execute commands before package installation

**Example**:
```ini
[pre-install]
echo "Preparing for installation..."
mkdir -p "$HOME/.local/myapp"
sudo systemctl stop myservice 2>/dev/null || true
```

**Use cases**:
- Create required directories
- Stop running services
- Backup existing configurations
- Check prerequisites

**Execution**: Runs before `pacman`/`yay` installation begins.

---

### `[post-install]` Section

**Optional for**: Regular packages  
**Purpose**: Execute commands after successful package installation

**Example**:
```ini
[post-install]
sudo systemctl enable --now docker.service
sudo usermod -aG docker $USER
mkdir -p "$HOME/.docker"
```

**Use cases**:
- Enable and start systemd services
- Add user to groups
- Create configuration files
- Run initialization commands
- Set file permissions

**Execution**: Only runs if package installation succeeded.

---

### `[post-remove]` Section

**Optional for**: Regular packages  
**Purpose**: Cleanup after package removal

**Example**:
```ini
[post-remove]
sudo systemctl stop docker.service
sudo userdel -r dockeruser 2>/dev/null || true
rm -rf "$HOME/.docker"
sudo rm -rf /var/lib/docker
```

**Use cases**:
- Remove configuration files
- Clean up data directories
- Stop and disable services
- Remove users/groups

**Execution**: Runs after package removal completes.

---

### `[uninstall]` Section

**Required for**: Git packages with custom uninstall  
**Purpose**: Remove git-based packages (equivalent to `post-remove` for git packages)

**Example**:
```ini
[uninstall]
sudo rm -f /usr/local/bin/mytool
sudo rm -f /etc/bash_completion.d/mytool
rm -rf "$HOME/.config/mytool"
```

**Use cases**:
- Remove installed binaries
- Delete configuration files
- Clean up completion scripts
- Remove systemd services

**Note**: For Makefile-based projects, you can use:
```ini
[uninstall]
cd /path/to/source && sudo make uninstall
```

---

## Creating a New Package Configuration

### Step 1: Identify Package Type

**Regular package** (in repos/AUR):
- Package available via `pacman` or `yay`
- No building required
- → Use `[package]` section

**Git package** (built from source):
- Clone from git repository
- Requires compilation/installation
- → Use `[git]` section

### Step 2: Create Configuration File

Create `~/.config/warchy/install/mypackage.conf` with appropriate sections.

### Step 3: Test Installation

```bash
# Install
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" install mypackage

# Verify
which mycommand
echo $MY_VARIABLE

# Test removal
source "$WARCHY_PATH/bin/install/warchy-pkg-manager" remove mypackage
```

### Step 4: Add to Package Browser

The configuration will automatically appear in `warchy-packages` interactive UI.

---

## Examples

### Example 1: Simple Regular Package

File: `~/.config/warchy/install/htop.conf`

```ini
[package]
PACKAGE_NAME=htop
PACKAGE_INSTALLER=pacman
```

### Example 2: Package with Environment Variables

File: `~/.config/warchy/install/npm.conf`

```ini
[package]
PACKAGE_NAME=npm
PACKAGE_INSTALLER=pacman

[env]
NPM_CONFIG_PREFIX="$XDG_DATA_HOME/npm"
PATH="$NPM_CONFIG_PREFIX/bin"

[post-install]
mkdir -p "$NPM_CONFIG_PREFIX"
```

### Example 3: Git Package with Dependencies

File: `~/.config/warchy/install/yay.conf`

```ini
[git]
GIT_REPO=https://aur.archlinux.org/yay.git

[dependencies]
BUILD_DEPS=
TEMP_BUILD_DEPS=

[version]
yay --version 2>&1 | grep -oP 'v\K[\d.]+' | head -1

[build]
makepkg -si --noconfirm

[env]
# No environment variables needed

[uninstall]
sudo pacman -Rns --noconfirm yay
```

### Example 4: Git Package with Commit Versioning

File: `~/.config/warchy/install/vhdm.conf`

```ini
[git]
GIT_REPO=https://github.com/rjdinis-nos/vhdm.git

[dependencies]
TEMP_BUILD_DEPS=go
BUILD_DEPS=

[version]
vhdm version 2>&1 | grep -oP 'version \K[a-f0-9]+' | head -1

[build]
sudo make install 2>&1 | grep -v "skipping" || true
sudo mkdir -p /etc/bash_completion.d
vhdm completion bash | sudo tee /etc/bash_completion.d/vhdm >/dev/null

[env]
# No environment variables needed for vhdm

[uninstall]
sudo rm -f /etc/bash_completion.d/vhdm
sudo rm -f /usr/local/bin/vhdm
```

---

## Best Practices

### General

1. **Use descriptive comments** at the top of each config file
2. **Test both install and remove** operations thoroughly
3. **Use absolute paths** or well-known variables (`$HOME`, `$XDG_*`)
4. **Check command success** with `|| true` for non-critical commands
5. **Follow XDG Base Directory spec** when possible

### Environment Variables

1. **Namespace variables** with package prefix (e.g., `DOCKER_CONFIG`, `GOPATH`)
2. **Use XDG variables** for portable paths
3. **Avoid hardcoding** user names or home directories
4. **Document side effects** in comments

### Build Commands

1. **Use parallel builds** when safe: `make -j$(nproc)`
2. **Suppress unnecessary output**: `command 2>&1 | grep -v "noise"`
3. **Use proper prefixes**: `/usr/local` for system-wide, `$HOME/.local` for user
4. **Handle sudo carefully**: Only when required, prefer `install -m` over `cp + chmod`

### Dependencies

1. **Minimize TEMP_BUILD_DEPS**: Only include truly temporary tools
2. **Use BUILD_DEPS** for runtime dependencies
3. **List minimal dependencies**: Rely on dependency resolution when possible
4. **Document why** dependencies are needed in comments

### Version Checking

1. **Always include [version] section** for git packages to avoid unnecessary rebuilds
2. **Use robust extraction**: Match specific patterns, not entire lines
3. **Test version command** before committing config
4. **Handle errors**: `2>&1` to capture stderr, `|| true` for non-critical failures

---

## Troubleshooting

### Package Not Installing

1. Check configuration file exists: `ls ~/.config/warchy/install/mypackage.conf`
2. Verify section headers: `[package]` or `[git]`
3. Check required fields are defined
4. Test package manager directly: `pacman -Q package-name`

### Environment Variables Not Set

1. Ensure you **sourced** the command: `source warchy-pkg-manager install pkg`
2. Check variables are in `~/.config/bash/envs`
3. Verify syntax in `[env]` section (use `=` not `:`)
4. Test in new shell to confirm persistence

### Build Failures

1. Check build dependencies are installed
2. Run build commands manually in a temp directory
3. Look for missing prerequisites (compilers, libraries)
4. Check sudo permissions for install commands

### Version Check Not Working

1. Test version command manually: `mytool --version`
2. Verify output format matches expected pattern
3. Check regex pattern extracts correct value
4. Ensure command is in `[version]` section (not `[env]`)

---

## Related Documentation

- [Package Management System Overview](../../bin/install/README.md) - Core tools and architecture
- [AGENT.md](../../../AGENT.md) - Development guidelines
- [CHANGELOG.md](../../../CHANGELOG.md) - System history and decisions

---

## Available Package Configurations

Current packages in this directory:

| Package | Type | Description |
|---------|------|-------------|
| `docker` | pacman | Docker, Docker Compose, Buildx, LazyDocker |
| `gcloud` | yay | Google Cloud SDK |
| `go` | yay | Go programming language |
| `npm` | pacman | Node.js package manager |
| `opencode` | yay | VS Code for the web (code-server) |
| `pnpm` | pacman | Fast, disk space efficient package manager |
| `posting` | yay | Modern HTTP client TUI |
| `rust` | pacman | Rust programming language toolchain |
| `vhdm` | git | VHD management for WSL |
| `yay` | git | AUR helper for Arch Linux |

For adding new packages, follow the examples above and test thoroughly before committing to the repository.
