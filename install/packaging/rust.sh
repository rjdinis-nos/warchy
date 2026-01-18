#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Starting rust installation..."

# Install google-cloud-cli from AUR using yay
$WARCHY_PATH/bin/install/warchy-install-pacman-pkgs rustup
rustup default stable

gum style --foreground 82 "✔  Rust installation complete"