#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Configuring SSH agent..."

# Configure ssh-agent socket (requires openssh to be installed)
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/systemd/ssh-agent.service.d/override.conf to ~/.config/systemd/user/ssh-agent.service.d"
mkdir -p ~/.config/systemd/user/ssh-agent.service.d/
cp -f "$WARCHY_PATH/default/systemd/ssh-agent.service.d/override.conf" ~/.config/systemd/user/ssh-agent.service.d/

gum style --foreground 245 "  → Enable ssh-agent.socket"
systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.socket
systemctl --user status ssh-agent.socket --no-pager --lines=0 | grep "Active:" | gum style --foreground 245 --padding "0 0 0 4"

gum style --foreground 82 "✔  SSH agent configured"
echo
