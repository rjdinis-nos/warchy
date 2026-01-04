#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Installing base packages..."

PKGS_TO_INSTALL="$WARCHY_PATH/install/warchy-base.packages"

mapfile -t packages < <(grep -v '^#' $PKGS_TO_INSTALL | grep -v '^$')
$WARCHY_PATH/bin/install/warchy-install-pacman-pkgs ${packages[@]}

gum style --foreground 82 "✔  Base packages installed"
