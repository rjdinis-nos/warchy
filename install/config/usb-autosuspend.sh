#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Disabling USB autosuspend..."

# Disable USB autosuspend to prevent peripheral disconnection issues
if [[ ! -f /etc/modprobe.d/disable-usb-autosuspend.conf ]]; then
  echo "options usbcore autosuspend=-1" | sudo tee /etc/modprobe.d/disable-usb-autosuspend.conf >/dev/null
  gum style --foreground 245 "  → USB autosuspend disabled"
else
  gum style --foreground 245 "  → USB autosuspend already disabled"
fi

cat /etc/modprobe.d/disable-usb-autosuspend.conf | gum style --foreground 245 --padding "0 0 0 4"
gum style --foreground 82 "✔  USB autosuspend disabled"
echo
