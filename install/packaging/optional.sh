#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Installing Optional packages..."


PKGS_TO_INSTALL="$WARCHY_PATH/install/warchy-optional.packages"

mapfile -t packages < <(grep -v '^#' $PKGS_TO_INSTALL | grep -v '^$')
$WARCHY_PATH/bin/utils/warchy-pacman-install ${packages[@]}

gum style --foreground 82 "✔  Optional packages installed"
