#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Starting Posting installation..."

# Install google-cloud-cli from AUR using paru
$WARCHY_PATH/bin/install/warchy-install-paru-pkgs posting

gum style --foreground 82 "✔  Posting installation complete"
