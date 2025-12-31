#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Installing yay packages..."

PKGS_TO_INSTALL="$WARCHY_PATH/install/warchy-yay.packages"

mapfile -t packages < <(grep -v '^#' $PKGS_TO_INSTALL | grep -v '^$')
$WARCHY_PATH/bin/utils/warchy-yay-install ${packages[@]}

gum style --foreground 82 "✔  Yay packages installed"
