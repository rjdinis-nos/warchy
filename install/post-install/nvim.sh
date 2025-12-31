#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Configuring nvim user settings..."

gum style --foreground 245 "  → Copy colorsheme.lua to $XDG_CONFIG_HOME/nvim/lua/plugins/"
mv $WARCHY_PATH/default/nvim/colorscheme.lua .config/nvim/lua/plugins/

gum style --foreground 82 "✔  Base packages installed"
