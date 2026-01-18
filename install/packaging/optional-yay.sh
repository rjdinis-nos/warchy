#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Installing yay packages..."

PKGS_TO_INSTALL="$WARCHY_PATH/install/warchy-yay.packages"

mapfile -t packages < <(grep -v '^#' $PKGS_TO_INSTALL | grep -v '^$')
$WARCHY_PATH/bin/install/warchy-pkg install yay "${packages[@]}"

gum style --foreground 82 "✔  Yay packages installed"
