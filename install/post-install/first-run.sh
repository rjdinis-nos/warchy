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

# Remove the first-run block from init file (no longer needed)
sed -i '/# Check for first-run post-install tasks/,/^fi$/d' "$WARCHY_PATH/config/bash/init"

# Remove marker file (only reached on successful completion)
rm -f "$XDG_STATE_HOME/warchy/first-run-pending"

echo
gum style --foreground 82 "✔  Post-installation complete!"
echo
gum style --border rounded --border-foreground 33 --padding "0 1" --foreground 33 "💡 Run 'warchy-user-setup' to configure VHD, Git, SSH, and GitHub"
gum style --foreground 245 "   Or run 'warchy-scripts' to see all available commands"
echo
