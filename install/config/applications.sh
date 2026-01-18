#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Setting up desktop applications..."

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"


# Create applications directory
mkdir -p "$XDG_DATA_HOME"/applications
cp "$WARCHY_PATH"/default/applications/* "$XDG_DATA_HOME"/applications/
gum style --foreground 245 "  → Copy $WARCHY_PATH/applications/* to $XDG_DATA_HOME/applications/"

sudo ln -sf /usr/bin/xdg-terminal-exec /usr/bin/x-terminal-emulator
gum style --foreground 245 "  → Created symlink for x-terminal-emulator"


gum style --foreground 82 "✔  Desktop applications setup completed"
echo
