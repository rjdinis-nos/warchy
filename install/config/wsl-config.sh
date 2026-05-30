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

# Workaround for WSLg issue #1456: /mnt/shared_memory is not mounted on
# WSL 2.7.3+, causing GUI windows to fall back to "[WARN:COPY MODE]" and
# never render. Mount it via a systemd .mount unit so windows render normally.
sudo cp -f "$WARCHY_PATH/default/wsl/mnt-shared_memory.mount" /etc/systemd/system/
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/wsl/mnt-shared_memory.mount to /etc/systemd/system"
sudo systemctl daemon-reload
sudo systemctl enable mnt-shared_memory.mount
gum style --foreground 245 "  → Enable mnt-shared_memory.mount"


gum style --foreground 82 "✔  WSL configuration completed"
echo
