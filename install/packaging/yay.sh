#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Starting yay installation..."

# Check if yay is already installed
if command -v yay &> /dev/null; then
    gum style --foreground 245 "  → yay is already installed, skipping..."
else
    # Install yay from AUR
    gum style --foreground 245 "  → Cloning yay from AUR..."

    # Create temporary directory for building
    BUILD_DIR=$(mktemp -d)
    cd "$BUILD_DIR"

    # Clone yay repository
    git clone --quiet https://aur.archlinux.org/yay.git

    # Build and install yay
    cd yay
    gum style --foreground 245 "  → Building and installing yay..."
    makepkg -si --noconfirm

    # Clean up
    gum style --foreground 245 "  → Clean up yay temp folder..."
    cd ~
    rm -rf "$BUILD_DIR"
fi

gum style --foreground 82 "✔  Yay installation complete"
