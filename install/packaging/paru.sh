#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Starting paru installation..."

# Check if paru is already installed
if command -v paru &> /dev/null; then
    gum style --foreground 245 "  → paru is already installed, skipping..."
else
    # Install paru from AUR
    gum style --foreground 245 "  → Cloning paru from AUR..."

    # Create temporary directory for building
    BUILD_DIR=$(mktemp -d)
    cd "$BUILD_DIR"

    # Clone paru repository
    git clone --quiet https://aur.archlinux.org/paru.git

    # Build and install paru
    cd paru
    gum style --foreground 245 "  → Building and installing paru..."
    makepkg -si --noconfirm

    # Clean up
    gum style --foreground 245 "  → Clean up paru temp folder..."
    cd ~
    rm -rf "$BUILD_DIR"
fi

gum style --foreground 82 "✔  Paru installation complete"
