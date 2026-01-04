#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Starting google-cloud-cli installation..."

# Install google-cloud-cli from AUR using yay
$WARCHY_PATH/bin/utils/warchy-install-yay-pkgs google-cloud-cli

gum style --foreground 82 "✔  google-cloud-cli installation complete"
