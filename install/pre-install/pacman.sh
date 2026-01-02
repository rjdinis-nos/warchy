#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Configuring pacman..."

sudo mkdir /etc/pacman.d/hooks
sudo cp -f ~/.local/share/warchy/default/pacman/pacman.conf /etc/pacman.conf
sudo cp -f ~/.local/share/warchy/default/pacman/mirrorlist /etc/pacman.d/mirrorlist
sudo cp -f ~/.local/share/warchy/default/pacman/mandb.hook /etc/pacman.d/hooks/mandb.hook

gum style --foreground 245 "  → Updating system packages..."
sudo pacman -Syu --noconfirm

gum style --foreground 82 "✔  System packages updated"
echo
