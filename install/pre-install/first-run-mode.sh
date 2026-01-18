#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Setting up first-run mode..."

# Set first-run mode marker so we can install stuff post-installation
mkdir -p ~/.local/state/warchy
touch ~/.local/state/warchy/first-run.mode
gum style --foreground 245 "  → First-run marker created"

# Setup sudo-less access for first-run
gum style --foreground 245 "  → Configuring passwordless sudo for post-install tasks"
sudo tee /etc/sudoers.d/first-run >/dev/null <<EOF
Cmnd_Alias FIRST_RUN_CLEANUP = /bin/rm -f /etc/sudoers.d/first-run
Cmnd_Alias SYMLINK_RESOLVED = /usr/bin/ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl
$USER ALL=(ALL) NOPASSWD: /usr/bin/ufw
$USER ALL=(ALL) NOPASSWD: /usr/bin/ufw-docker
$USER ALL=(ALL) NOPASSWD: /usr/bin/gtk-update-icon-cache
$USER ALL=(ALL) NOPASSWD: SYMLINK_RESOLVED
$USER ALL=(ALL) NOPASSWD: FIRST_RUN_CLEANUP
EOF
sudo chmod 440 /etc/sudoers.d/first-run

gum style --foreground 82 "✔  First-run mode configured"
echo
