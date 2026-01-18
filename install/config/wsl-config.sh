#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Configuring WSL system files..."


# Update wsl configuration files
sudo cp -f "$WARCHY_PATH/default/wsl/wslg.conf" /etc/tmpfiles.d/
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/wsl/wslg.conf to /etc/tmpfiles.d"

sudo cp -f "$WARCHY_PATH/default/wsl/wslg.sh" /etc/profile.d/
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/wsl/wslg.sh to /etc/profile.d"

sudo cp $WARCHY_PATH/default/wsl/WSLInterop.conf /usr/lib/binfmt.d/
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/wsl/WSLInterop.conf to /usr/lib/binfmt.d"


gum style --foreground 82 "✔  WSL configuration completed"
echo
