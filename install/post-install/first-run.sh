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

# Clean up package caches and orphaned packages
gum style --foreground 245 "  → Cleaning package caches..."
if command -v paccache &>/dev/null; then
  sudo paccache -rq -k 1 2>/dev/null || true
else
  sudo pacman -Sc --noconfirm 2>/dev/null || true
fi

if command -v yay &>/dev/null; then
  yay -Sc --noconfirm 2>/dev/null || true
  rm -rf ~/.cache/yay/* 2>/dev/null || true
fi

# Remove orphaned packages
orphans=$(pacman -Qtdq 2>/dev/null || true)
if [[ -n "$orphans" ]]; then
  echo "$orphans" | sudo pacman -Rns --noconfirm - 2>/dev/null || true
fi

gum style --foreground 245 "  → Package cleanup complete"

# Remove the first-run block from init file (no longer needed)
sed -i '/# Check for first-run post-install tasks/,/^fi$/d' "$XDG_CONFIG_HOME/bash/init"

# Remove marker file (only reached on successful completion)
rm -f "$XDG_STATE_HOME/warchy/first-run-pending"

echo
gum style --foreground 82 "✔  Post-installation complete!"
echo
gum style --border rounded --border-foreground 33 --padding "0 1" --foreground 33 "💡 Run 'warchy-user-setup' to configure VHD, Git, SSH, and GitHub"
gum style --foreground 245 "   Or run 'warchy-scripts' to see all available commands"
echo

return 1
