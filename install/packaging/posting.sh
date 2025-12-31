#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Starting Posting installation..."

# Install google-cloud-cli from AUR using yay
$WARCHY_PATH/bin/utils/warchy-yay-install posting

gum style --foreground 82 "✔  Posting installation complete"
