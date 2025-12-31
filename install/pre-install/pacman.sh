#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Configuring pacman..."

sudo cp -f ~/.local/share/warchy/default/pacman/pacman.conf /etc/pacman.conf
sudo cp -f ~/.local/share/warchy/default/pacman/mirrorlist /etc/pacman.d/mirrorlist

gum style --foreground 245 "  → Updating system packages..."
sudo pacman -Syu --noconfirm

gum style --foreground 82 "✔  System packages updated"
echo
