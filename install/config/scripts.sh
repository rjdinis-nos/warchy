#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Start Warchy script files Configuration..."

# Migrate Warchy bin executables to XDG bin/warchy
gum style --foreground 245 "  → Migrate executable files from $WARCHY_PATH/bin to $HOME/.local/bin/warchy"
mkdir -p "$HOME/.local/bin/warchy"
if [ -d "$WARCHY_PATH/bin" ]; then
  # Copy directories
  find "$WARCHY_PATH/bin" -mindepth 1 -maxdepth 1 -type d -exec cp -rf {} "$HOME/.local/bin/warchy/" \;
  # Copy executable files only, excluding README.md
  find "$WARCHY_PATH/bin" -mindepth 1 -maxdepth 1 -type f -executable ! -name "README.md" -exec cp -f {} "$HOME/.local/bin/warchy/" \;
fi

gum style --foreground 245 "  → Assure warchy scripts are executable"
find "$HOME/.local/bin/warchy" -type f -exec chmod 755 {} +

gum style --foreground 82 "✔  Configuration files copied"
echo
