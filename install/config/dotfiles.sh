#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Configuring dotfiles and user configuration..."

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"


# Copy over Warchy configs
mkdir -p ~/.config
shopt -s dotglob

# Preserve existing git config if not a fresh install
if [ -f "$XDG_CONFIG_HOME/git/config" ] && [ ! -f "$XDG_STATE_HOME/warchy/first-run.mode" ]; then
  # Temporarily move git config to preserve it
  mv "$XDG_CONFIG_HOME/git/config" "$XDG_CONFIG_HOME/git/config.preserve"
fi

cp -rf "$WARCHY_PATH/config/"* ~/.config/

# Restore preserved git config
if [ -f "$XDG_CONFIG_HOME/git/config.preserve" ]; then
  mv "$XDG_CONFIG_HOME/git/config.preserve" "$XDG_CONFIG_HOME/git/config"
  gum style --foreground 245 "  → Preserved existing git config (not a fresh install)"
fi

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
