#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Setting up XDG directories and Warchy binaries..."

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
gum style --foreground 245 "  → Created XDG directories"


# Migrate Warchy bin executables to XDG bin/warchy
mkdir -p "$HOME/.local/bin/warchy"
if [ -d "$WARCHY_PATH/bin" ]; then
  cp -rf "$WARCHY_PATH/bin/"* "$HOME/.local/bin/warchy/"
  find "$HOME/.local/bin/warchy" -type f -exec chmod +x {} \;
  gum style --foreground 245 "  → Migrated executable files from $WARCHY_PATH/bin to $HOME/.local/bin/warchy"
fi


# Setup XDG-compliant bash-completion directory
XDG_BASH_COMPLETION_DIR="$XDG_DATA_HOME/bash-completion/completions"
mkdir -p "$XDG_BASH_COMPLETION_DIR"
gum style --foreground 245 "  → Created XDG-compliant bash-completion directory at $XDG_BASH_COMPLETION_DIR"


gum style --foreground 82 "✔  XDG setup completed"
echo
