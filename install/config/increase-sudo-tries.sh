#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Increase sudo tries..."

# Give the user 10 instead of 3 tries to fat finger their password before lockout
echo "Defaults passwd_tries=10" | sudo tee /etc/sudoers.d/passwd-tries | gum style --foreground 245 --padding "0 0 0 4"
sudo chmod 440 /etc/sudoers.d/passwd-tries

gum style --foreground 82 "✔  Sudo tries configured"
echo
