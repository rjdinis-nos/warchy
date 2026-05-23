#!/bin/bash

set -eEuo pipefail

# Detect Intel GPU via WSL2 driver directory (works before drivers are installed)
# iigd*.inf files are Intel Graphics Driver infs pushed from the Windows host
_intel_detected=false
if ls /usr/lib/wsl/drivers/ 2>/dev/null | grep -qi "^iigd"; then
  _intel_detected=true
elif clinfo 2>/dev/null | grep -q "Device Vendor.*Intel\|Platform Vendor.*Intel"; then
  _intel_detected=true
fi

if ! $_intel_detected; then
  gum style --foreground 3 "⚠  No Intel Arc GPU detected, skipping Intel GPU packages"
  return 0
fi

gum style --foreground 39 "⚡ Intel Arc GPU detected, installing Intel GPU packages..."

PKGS_TO_INSTALL="$WARCHY_PATH/install/warchy-intel-yay.packages"

mapfile -t packages < <(grep -v '^#' "$PKGS_TO_INSTALL" | grep -v '^$')
$WARCHY_PATH/bin/install/warchy-pkg install yay "${packages[@]}"

gum style --foreground 82 "✔  Intel GPU packages installed"
