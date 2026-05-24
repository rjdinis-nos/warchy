#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Configuring GPG agent..."

# Configure gpg-agent to use GUI pinentry (pinentry-qt) so passphrase prompts
# work in non-TTY contexts (tools, scripts, WSL without a terminal)
GNUPG_DIR="${GNUPGHOME:-$HOME/.gnupg}"

gum style --foreground 245 "  → Copy $WARCHY_PATH/default/gnupg/gpg-agent.conf to $GNUPG_DIR/gpg-agent.conf"
mkdir -p "$GNUPG_DIR"
chmod 700 "$GNUPG_DIR"
cp -f "$WARCHY_PATH/default/gnupg/gpg-agent.conf" "$GNUPG_DIR/gpg-agent.conf"

gum style --foreground 245 "  → Reloading gpg-agent..."
gpg-connect-agent reloadagent /bye &>/dev/null || true

gum style --foreground 82 "✔  GPG agent configured"
echo
