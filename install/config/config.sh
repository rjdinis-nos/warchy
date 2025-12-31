#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Start configuration of system and user files..."

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Create XDG user environment directories
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_CACHE_HOME"
mkdir -p "$XDG_DATA_HOME"
mkdir -p "$XDG_STATE_HOME"
mkdir -p $HOME/.local/bin

# Copy over Warchy configs
mkdir -p ~/.config
shopt -s dotglob
cp -rf "$WARCHY_PATH/config/"* ~/.config/
shopt -u dotglob
gum style --foreground 245 "  → Config files copied from $WARCHY_PATH/config to ~/.config"

# Use default bashrc from Warchy
cp -f "$WARCHY_PATH/default/bashrc" ~/.bashrc
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/bashrc to ~/.bashrc"

# Configure wget
mkdir -p "$XDG_CONFIG_HOME"/wget
mkdir -p "$XDG_CACHE_HOME"/wget
echo hsts-file \= "$XDG_CACHE_HOME"/wget/wget-hsts >>"$XDG_CONFIG_HOME/wget/wgetrc"
gum style --foreground 245 "  → Configure wget"

# Configure Neovim
[[ -d "$XDG_CONFIG_HOME/nvim" ]] && rm -rf "$XDG_CONFIG_HOME/nvim"
if git clone --depth 1 https://github.com/LazyVim/starter "$XDG_CONFIG_HOME/nvim" >/dev/null 2>&1; then
  rm -rf "$TARGET_DIR/.git"
  gum style --foreground 245 "  → Git clone LazyVim successful to $XDG_CONFIG_HOME/nvim"
else
  gum log --level error "  ✖  Failed to clone LazyVim. Please check your internet connection or URL."
fi

# Use default wsl from Warchy
sudo cp -f "$WARCHY_PATH/default/wsl/wslg.conf" /etc/tmpfiles.d/
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/wls/wlsg.conf to /etc/tmpfiles.d"

sudo cp -f "$WARCHY_PATH/default/wsl/wslg.sh" /etc/profile.d/
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/wls/wlsg.sh to /etc/profile.d"

sudo cp $WARCHY_PATH/default/wsl/WSLInterop.conf /usr/lib/binfmt.d/
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/wls/WSLInterop.conf to /usr/lib/binfmt.d"

# Setup XDG-compliant directory
XDG_BASH_COMPLETION_DIR="$XDG_DATA_HOME/bash-completion/completions"
mkdir -p "$XDG_BASH_COMPLETION_DIR"

# Copy Warchy executables to user's bin
mkdir -p $HOME/.local/bin
cp "$WARCHY_PATH"/bin/* $HOME/.local/bin
chmod 775 $HOME/.local/bin
gum style --foreground 245 "  → Copy $WARCHY_PATH/bin/* to $HOME/.local/bin/"

# Create applications directory
mkdir -p "$XDG_DATA_HOME"/applications
cp "$WARCHY_PATH"/default/applications/* "$XDG_DATA_HOME"/applications/
gum style --foreground 245 "  → Copy $WARCHY_PATH/applications/* to $XDG_DATA_HOME/applications/"

# Create .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

gum style --foreground 82 "✔  Configuration files copied"

echo
