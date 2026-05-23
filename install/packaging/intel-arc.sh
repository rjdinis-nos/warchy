#!/bin/bash

set -eEuo pipefail

if ! clinfo 2>/dev/null | grep -q "Device Vendor.*Intel\|Platform Vendor.*Intel"; then
  gum style --foreground 3 "⚠  No Intel Arc GPU detected, skipping Intel GPU packages"
  return 0
fi

gum style --foreground 39 "⚡ Intel Arc GPU detected, installing Intel GPU packages..."

PKGS_TO_INSTALL="$WARCHY_PATH/install/warchy-intel-yay.packages"

mapfile -t packages < <(grep -v '^#' "$PKGS_TO_INSTALL" | grep -v '^$')
$WARCHY_PATH/bin/install/warchy-pkg install yay "${packages[@]}"

gum style --foreground 82 "✔  Intel GPU packages installed"
