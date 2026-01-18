#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Configuring dotfiles and user configuration..."

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"


# Copy over Warchy configs
mkdir -p ~/.config
shopt -s dotglob
cp -rf "$WARCHY_PATH/config/"* ~/.config/
shopt -u dotglob
gum style --foreground 245 "  → Config files copied from $WARCHY_PATH/config to ~/.config"


# Use default bashrc from Warchy
cp -f "$WARCHY_PATH/default/bashrc" ~/.bashrc
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/bashrc to ~/.bashrc"


# Create .ssh directory
mkdir -p ~/.ssh
# Only change permissions if the directory is owned by the current user
if [ "$(stat -c '%U' ~/.ssh)" = "$(whoami)" ]; then
    chmod 700 ~/.ssh
fi
gum style --foreground 245 "  → Created ~/.ssh directory"


gum style --foreground 82 "✔  Dotfiles configuration completed"
echo
