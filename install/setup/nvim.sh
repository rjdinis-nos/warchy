#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Configuring nvim user settings..."

gum style --foreground 245 "  → Copy colorscheme.lua to ~/.config/nvim/lua/plugins/"
mkdir -p ~/.config/nvim/lua/plugins
cp "$WARCHY_PATH/default/nvim/colorscheme.lua" ~/.config/nvim/lua/plugins/

gum style --foreground 82 "✔  Neovim configured"
