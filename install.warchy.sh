#!/usr/bin/env bash
# -------------------------------------------------------------------------------------------------------------
# install.warchy.sh - Pipe-to-shell installer blueprint with XDG support
# -------------------------------------------------------------------------------------------------------------
# Inspired by: https://omarchy.org/
# -----------------------------------------------------------------------------
# Usage:
#   curl -LsSf https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/main/install.warchy.sh | bash
#   or
#   WARCHY_LOCAL_TEST=/path/to/warchy ./install.warchy.sh
# -------------------------------------------------------------------------------------------------------------

set -e # Exit on any error

# ANSI color codes
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
BOLD="\033[1m"
RESET="\033[0m"

ansi_art='░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓███████▓▒░░▒▓█▓▒░      ░▒▓████████▓▒░░▒▓██████▓▒░
░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░
 ░▒▓█████████████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░
                                                                                                     '

# Print warchy red logo in TEST mode, green logo in production
if [[ -n "$WARCHY_LOCAL_TEST" ]]; then
  echo -e "${RED}$ansi_art${RESET}"
else
  echo -e "${GREEN}$ansi_art${RESET}"
fi

# Configuration
WARCHY_REPO="${WARCHY_REPO:-rjdinis-nos/warchy}"
WARCHY_BRANCH="${WARCHY_BRANCH:-main}"

# Determine install directory using XDG or fallback
if [ -n "$XDG_DATA_HOME" ]; then
  WARCHY_PATH="${XDG_DATA_HOME}/warchy"
else
  WARCHY_PATH="${HOME}/.local/share/warchy"
fi

# Export WARCHY_PATH for use by install.sh
export WARCHY_PATH

# Display environment
echo -e "${BOLD}${CYAN}=== Environment Variables ===${RESET}"
echo -e "${YELLOW}→ WARCHY_PATH:${RESET} ${GREEN}${WARCHY_PATH}${RESET}"
echo -e "${YELLOW}→ WARCHY_REPO:${RESET} ${GREEN}${WARCHY_REPO}${RESET}"
echo -e "${YELLOW}→ WARCHY_BRANCH:${RESET} ${GREEN}${WARCHY_BRANCH}${RESET}"
echo -e "${YELLOW}→ WARCHY_LOCAL_TEST:${RESET} ${GREEN}${WARCHY_LOCAL_TEST:-<not set>}${RESET}"
echo

# Helper functions
error() {
  echo -e "${RED}Error: $*${RESET}" >&2
  exit 1
}

info() {
  echo -e "${CYAN}ℹ  $*${RESET}"
}

success() {
  echo -e "${GREEN}✅ $*${RESET}"
  echo
}

check_command() {
  command -v "$1" >/dev/null 2>&1
}

clean_previous_installation() {
  if [ -d "$WARCHY_PATH" ]; then
    info "Removing previous installation at $WARCHY_PATH..."
    rm -rf "$WARCHY_PATH" || error "Failed to remove previous installation"
    success "Previous installation removed"
  fi
}

verify_installation_complete() {
  # Verify installation path exists
  if [ ! -d "$WARCHY_PATH" ]; then
    . ${WARCHY_PATH}/bin/warchy-notify -t "Warchy" -m "Installation failed - $WARCHY_PATH does not exist!" -l "critical"
    error "Installation failed - $WARCHY_PATH does not exist"
  fi

  # Verify install.sh exists
  if [ ! -f "${WARCHY_PATH}/install/install.sh" ]; then
    . ${WARCHY_PATH}/bin/warchy-notify -t "Warchy" -m "Installation failed - install.sh not found in "${WARCHY_PATH}"/install!" -l "critical"
    error "Installation failed - install.sh not found in "${WARCHY_PATH}"/install"
  fi
}

configure_warchy_path_env() {
  info "Configuring Warchy environment variables in ~/.bash_profile..."

  # Check if WARCHY_PATH export already exists in .bash_profile
  if grep -q "^export WARCHY_PATH=" "$HOME/.bash_profile" 2>/dev/null; then
    sed -i "s|^export WARCHY_PATH=.*|export WARCHY_PATH=\"$WARCHY_PATH\"|" "$HOME/.bash_profile"
  else
    echo "export WARCHY_PATH=\"$WARCHY_PATH\"" >>"$HOME/.bash_profile"
  fi

  success "WARCHY_PATH configured in environment"
}


# ============================================================================
# Clean previous installation first
# ============================================================================
clean_previous_installation


# ============================================================================
# Assure git is installed
# ============================================================================
if ! check_command git; then
  info "Updating pacman and installing git..."
  sudo pacman -Syu --noconfirm --needed git 2>&1 | grep -v "skipping" || true
fi


# ============================================================================
# Clone or copy based on test mode directly to WARCHY_PATH
# ============================================================================
if [ -n "$WARCHY_LOCAL_TEST" ]; then
  # ================== LOCAL TEST =====================
  INSTALL_METHOD="copied"
  
  info "[TEST MODE] Copying from local directory: $WARCHY_LOCAL_TEST"

  # Validate install.warchy.sh exists (this also validates the directory exists)
  if [ ! -f "$WARCHY_LOCAL_TEST/install.warchy.sh" ]; then
    error "install.warchy.sh not found in: $WARCHY_LOCAL_TEST"
  fi

  # Create parent directory
  WARCHY_PARENT="$(dirname "$WARCHY_PATH")"
  mkdir -p "$WARCHY_PARENT" || error "Failed to create directory: $WARCHY_PARENT"

  # Copy files directly to WARCHY_PATH
  cp -r "$WARCHY_LOCAL_TEST" "$WARCHY_PATH" || error "Failed to copy files from $WARCHY_LOCAL_TEST"

  success "Files copied successfully to $WARCHY_PATH"
else
  # ================== CLONE REPO =====================
  INSTALL_METHOD="cloned"
  
  info "Cloning warchy from: https://github.com/${WARCHY_REPO}.git"

  # Verify repository is accessible
  info "Verifying repository accessibility..."
  if ! git ls-remote --exit-code --heads "https://github.com/${WARCHY_REPO}.git" >/dev/null 2>&1; then
    error "Repository not accessible: https://github.com/${WARCHY_REPO}.git"
  fi

  # Verify branch exists
  if ! git ls-remote --exit-code --heads "https://github.com/${WARCHY_REPO}.git" "$WARCHY_BRANCH" >/dev/null 2>&1; then
    error "Branch '$WARCHY_BRANCH' not found in repository: https://github.com/${WARCHY_REPO}.git"
  fi

  success "Repository and branch verified"

  # Clone repository directly to WARCHY_PATH (shallow clone for faster download)
  git clone --quiet --depth 1 --branch "$WARCHY_BRANCH" --single-branch \
    "https://github.com/${WARCHY_REPO}.git" "$WARCHY_PATH" ||
    error "Failed to clone repository"

  success "Repository cloned successfully to $WARCHY_PATH"
fi


# ============================================================================
# Verify installation is complete
# ============================================================================
verify_installation_complete
success "Warchy ${INSTALL_METHOD} to ${WARCHY_PATH}"

# Configure WARCHY_PATH in .bash_profile
configure_warchy_path_env


# ============================================================================
# Run main installation script from final location
# ============================================================================
info "Running main installation script ${WARCHY_PATH}/install/install.sh..."

chmod 755 "${WARCHY_PATH}/install/install.sh"

if [ -f "${WARCHY_PATH}/install/install.sh" ]; then
  . "$WARCHY_PATH/install/install.sh" || error "Main installation script failed"
else
  error "Main installation script not found: ${WARCHY_PATH}/install/install.sh"
  . ${WARCHY_PATH}/bin/warchy-notify -t "Warchy" -m "Main installation script not found: ${WARCHY_PATH}/install/install.sh" -l "critical"
fi

success "Warchy installation completed!"
. ${WARCHY_PATH}/bin/warchy-notify -t "Warchy" -m "Warchy successfully installated" -e 5
