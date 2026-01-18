#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Configuring systemd services..."

# Confirgure journal systemd service
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/systemd/journald.conf.d/100-wsl-limits.conf to /etc/systemd/journald.conf.d"
sudo mkdir -p /etc/systemd/journald.conf.d/
sudo cp -f "$WARCHY_PATH/default/systemd/journald.conf.d/100-wsl-limits.conf" /etc/systemd/journald.conf.d/
journal_config=$(systemd-analyze --no-pager cat-config systemd/journald.conf | grep -E '^SystemMaxUse|^RuntimeMaxUse' || true)
if [ -n "$journal_config" ]; then
  echo "$journal_config" | gum style --foreground 245 --padding "0 0 0 4"
fi

# Configure man-db systemd service
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/systemd/man-db.service.d/override.conf to /etc/systemd/system/man-db.service.d"
sudo mkdir -p /etc/systemd/system/man-db.service.d/
sudo cp -f "$WARCHY_PATH/default/systemd/man-db.service.d/override.conf" /etc/systemd/system/man-db.service.d/
mandb_config=$(systemd-analyze --no-pager cat-config systemd/man-db.service | grep -E '^ConditionACPower' || true)
if [ -n "$mandb_config" ]; then
  echo "$mandb_config" | gum style --foreground 245 --padding "0 0 0 4"
fi

# Configure dunst systemd service
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/systemd/dunst.service to ~/.config/systemd/user"
mkdir -p ~/.config/systemd/user
cp -f "$WARCHY_PATH/default/systemd/dunst.service" ~/.config/systemd/user/

gum style --foreground 245 "  → Enable dunst.service"
sudo mv /usr/share/dbus-1/services/org.knopwob.dunst.service /usr/share/dbus-1/services/org.freedesktop.Notifications.service 2>/dev/null || true
systemctl --user daemon-reload
systemctl --user disable dunst.service
systemctl --user stop dunst.service

gum style --foreground 82 "✔  Systemd services configured"
echo
