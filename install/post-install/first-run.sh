#!/bin/bash

set -eEo pipefail

echo
  gum style --border rounded --border-foreground 212 --padding "0 2" --foreground 212 "⚙  Post-Installation Tasks"
echo

# Clean up temporary installation sudoers files
if sudo test -f /etc/sudoers.d/99-warchy-installer; then
  sudo rm -f /etc/sudoers.d/99-warchy-installer &>/dev/null
fi

if sudo test -f /etc/sudoers.d/99-wslarchy-installer-reboot; then
  sudo rm -f /etc/sudoers.d/99-wslarchy-installer-reboot &>/dev/null
fi
gum style --foreground 245 "  → Cleaned up temporary installation files"

# Ask if user wants to configure user-specific settings
echo
if gum confirm --show-help=false --affirmative "Yes" --negative "Skip" "Configure user settings (VHD, Git, SSH)?"; then
  echo
  "$WARCHY_PATH/bin/utils/warchy-user-setup"
  echo
fi

# Remove the first-run block from init file (no longer needed)
sed -i '/# Check for first-run post-install tasks/,/^fi$/d' "$WARCHY_PATH/config/bash/init"

# Remove marker file (only reached on successful completion)
rm -f "$XDG_STATE_HOME/warchy/first-run-pending"

echo
gum style --foreground 82 "✔  Post-installation complete!"
echo
