#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Start Warchy script files Configuration..."

# Copy Warchy binaries to local bin
gum style --foreground 245 "  → Copy scripts to $HOME/.local/bin/"
cp $WARCHY_PATH/bin/* $HOME/.local/bin

gum style --foreground 245 "  → Assure scripts are executable"
find $HOME/.local/bin -type f -exec chmod 755 {} +

gum style --foreground 245 "  → Add $HOME/.local/bin/ to PATH"
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then PATH="$HOME/.local/bin:$PATH"; fi

gum style --foreground 82 "✔  Configuration files copied"
echo
