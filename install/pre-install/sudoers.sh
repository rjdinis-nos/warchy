#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Setting up sudoers.d..."

# Setup sudo-less access for user
gum style --foreground 245 "  → Configuring passwordless sudo for some user commands"
sudo tee /etc/sudoers.d/warchy-user >/dev/null <<EOF
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl
$USER ALL=(ALL) NOPASSWD: /usr/bin/journalctl
EOF
sudo chmod 440 /etc/sudoers.d/warchy-user

gum style --foreground 82 "✔  Sudoers.d configured"
echo
