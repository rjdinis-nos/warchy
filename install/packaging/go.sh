#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Starting Golang installation..."

source $WARCHY_PATH/bin/install/warchy-install-go

gum style --foreground 82 "✔  Golang installation complete"
