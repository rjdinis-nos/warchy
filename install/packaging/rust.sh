#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Starting rust installation..."

# Install rust toolchain from official repositories using pacman
$WARCHY_PATH/bin/install/warchy-install-pacman-pkgs rustup
rustup default stable

gum style --foreground 82 "✔  Rust installation complete"
