#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Starting Posting installation..."

# Install google-cloud-cli from AUR using yay
$WARCHY_PATH/bin/install/warchy-install-yay-pkgs posting

gum style --foreground 82 "✔  Posting installation complete"
