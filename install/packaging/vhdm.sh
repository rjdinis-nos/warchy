#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Installing Vhdm..."

source $WARCHY_PATH/bin/install/warchy-install-vhdm

gum style --foreground 82 "✔  Vhdm installed"
