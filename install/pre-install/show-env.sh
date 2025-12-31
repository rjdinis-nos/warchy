#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Installation Environment:"

$WARCHY_PATH/bin/utils/warchy-list-env-vars USER HOME WARCHY_BRANCH WARCHY_INSTALL WARCHY_INSTALL_LOG_FILE

echo
