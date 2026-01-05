#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Installing paru packages..."

PKGS_TO_INSTALL="$WARCHY_PATH/install/warchy-paru.packages"

mapfile -t packages < <(grep -v '^#' $PKGS_TO_INSTALL | grep -v '^$')
$WARCHY_PATH/bin/install/warchy-install-paru-pkgs ${packages[@]}

gum style --foreground 82 "✔  Paru packages installed"
