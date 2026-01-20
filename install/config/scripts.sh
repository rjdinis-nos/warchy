#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Start Warchy script files Configuration..."

# Migrate Warchy bin executables to XDG bin/warchy
gum style --foreground 245 "  → Migrate executable files from $WARCHY_PATH/bin to $HOME/.local/bin/warchy"
mkdir -p "$HOME/.local/bin/warchy"
if [ -d "$WARCHY_PATH/bin" ]; then
  cp -rf "$WARCHY_PATH/bin/"* "$HOME/.local/bin/warchy/"
fi

gum style --foreground 245 "  → Assure warchy scripts are executable"
find "$HOME/.local/bin/warchy" -type f -exec chmod 755 {} +

gum style --foreground 82 "✔  Configuration files copied"
echo
