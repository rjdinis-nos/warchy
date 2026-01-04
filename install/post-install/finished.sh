#!/bin/bash

set -eEo pipefail

stop_install_log

echo_in_style() {
  echo "$1" | tte --canvas-width 0 --anchor-text c --frame-rate 640 print
}

clear
echo
tte -i ~/.local/share/warchy/logo.txt --canvas-width 0 --anchor-text c --frame-rate 920 laseretch
echo

# Display completion message
echo_in_style \"Finished installing\"

if sudo test -f /etc/sudoers.d/99-warchy-installer; then
  sudo rm -f /etc/sudoers.d/99-warchy-installer &>/dev/null
fi

# Exit gracefully if user chooses not to reboot
if gum confirm --padding "0 0 0 $((PADDING_LEFT + 32))" --show-help=false --default --affirmative "Reboot Now" --negative "" ""; then
  # Clear screen to hide any shutdown messages
  clear

  if [[ -n "${WARCHY_CHROOT_INSTALL:-}" ]]; then
    touch /var/tmp/warchy-install-completed
    exit 0
  else
    sudo reboot 2>/dev/null
  fi
fi
