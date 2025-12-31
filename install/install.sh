#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# ANSI color codes
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
BOLD="\033[1m"
RESET="\033[0m"

# Define Warchy locations
export WARCHY_LOGO="$WARCHY_PATH/logo.txt"
export WARCHY_INSTALL="$WARCHY_PATH/install"
export WARCHY_INSTALL_LOG_FILE="/var/log/warchy-install.log"

WARCHY_INSTALL_BASE=1
WARCHY_INSTALL_OPTIONAL=1

export XDG_STATE_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

echo
echo
echo -e "${YELLOW}Installing...${RESET}"
echo

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  if [[ -n "$WARCHY_LOCAL_TEST" ]]; then
    echo -e "${RED}$(<"$WARCHY_LOGO")${RESET}"
  else
    echo -e "${GREEN}$(<"$WARCHY_LOGO")${RESET}"
  fi
fi

# Display environment
echo -e "${BOLD}${CYAN}=== Environment Variables ===${RESET}"
echo -e "${YELLOW}→ WARCHY_PATH:${RESET} ${GREEN}${WARCHY_PATH}${RESET}"
echo -e "${YELLOW}→ WARCHY_LOGO:${RESET} ${GREEN}${WARCHY_LOGO}${RESET}"
echo -e "${YELLOW}→ WARCHY_INSTALL:${RESET} ${GREEN}${WARCHY_INSTALL}${RESET}"
echo -e "${YELLOW}→ WARCHY_INSTALL_LOG_FILE:${RESET} ${GREEN}${WARCHY_INSTALL_LOG_FILE}${RESET}"
echo

# Install required packages
sudo pacman -Syu --noconfirm --needed gum base-devel &>/dev/null || true

# Load helper functions
source "$WARCHY_INSTALL/helpers/logging.sh"

# === Pre-Installation Checks ===
gum style --foreground 214 --border double --border-foreground 214 --padding "0 1" --width 80 --align center \ "PRE-INSTALLATION "
run_logged "$WARCHY_INSTALL/pre-install/guard.sh"
run_logged "$WARCHY_INSTALL/pre-install/show-env.sh"
run_logged "$WARCHY_INSTALL/pre-install/user.sh"
run_logged "$WARCHY_INSTALL/pre-install/pacman.sh"
run_logged "$WARCHY_INSTALL/pre-install/first-run-mode.sh"

#=== System Configuration ===
gum style --foreground 214 --border double --border-foreground 214 --padding "0 1" --width 80 --align center "SYSTEM CONFIGURATION "
run_logged "$WARCHY_INSTALL/config/config.sh"
run_logged "$WARCHY_INSTALL/config/scripts.sh"
run_logged "$WARCHY_INSTALL/config/systemd.sh"
run_logged "$WARCHY_INSTALL/config/ssh-flakiness.sh"
run_logged "$WARCHY_INSTALL/config/fast-shutdown.sh"
run_logged "$WARCHY_INSTALL/config/usb-autosuspend.sh"
run_logged "$WARCHY_INSTALL/config/increase-sudo-tries.sh"

#=== Base Packages Configuration ===
if [ "${WARCHY_INSTALL_BASE:-0}" -ne 0 ]; then
  gum style --foreground 214 --border double --border-foreground 214 --padding "0 1" --width 80 --align center "BASE PACKAGES CONFIGURATION"
  run_logged "$WARCHY_INSTALL/packaging/base.sh"
  run_logged "$WARCHY_INSTALL/packaging/localdb.sh"
fi

#=== Optional Packages Configuration ===
if [ "${WARCHY_INSTALL_OPTIONAL:-0}" -ne 0 ]; then
  gum style --foreground 214 --border double --border-foreground 214 --padding "0 1" --width 80 --align center "OPTIONAL PACKAGES CONFIGURATION"
  run_logged "$WARCHY_INSTALL/packaging/optional.sh"
  run_logged "$WARCHY_INSTALL/packaging/go.sh"
  run_logged "$WARCHY_INSTALL/packaging/yay.sh"
  run_logged "$WARCHY_INSTALL/packaging/optional-yay.sh"
  run_logged "$WARCHY_INSTALL/packaging/vhdm.sh"
  #run_logged "$WARCHY_INSTALL/packaging/posting.sh"
  #run_logged "$WARCHY_INSTALL/packaging/rust.sh"
  #run_logged "$WARCHY_INSTALL/packaging/gcp.sh"
fi

#=== Optional Packages Configuration ===
gum style --foreground 214 --border double --border-foreground 214 --padding "0 1" --width 80 --align center "POST-INSTALLATION"
run_logged "$WARCHY_INSTALL/post-install/nvim.sh"


. ~/.bash_profile
