#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Start Warchy script files Configuration..."

# Copy Warchy binaries to local bin
#gum style --foreground 245 "  → Copy scripts to $HOME/.local/bin/"
#cp $WARCHY_PATH/bin/* $HOME/.local/bin

gum style --foreground 245 "  → Assure warchy scripts are executable"
find "$WARCHY_PATH/bin" -type f -exec chmod 755 {} +

gum style --foreground 82 "✔  Configuration files copied"
echo
