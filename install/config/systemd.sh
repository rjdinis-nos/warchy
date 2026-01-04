#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Configuring systemd services..."

# Confirgure journal systemd service
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/systemd/journald.conf.d/100-wsl-limits.conf to /etc/systemd/journald.conf.d"
sudo mkdir -p /etc/systemd/journald.conf.d/
sudo cp -f "$WARCHY_PATH/default/systemd/journald.conf.d/100-wsl-limits.conf" /etc/systemd/journald.conf.d/
systemd-analyze --no-pager cat-config systemd/journald.conf | grep -E '^SystemMaxUse|^RuntimeMaxUse' | gum style --foreground 245 --padding "0 0 0 4"

gum style --foreground 245 "  → Copy $WARCHY_PATH/default/systemd/man-db.service.d/override.conf to /etc/systemd/system/man-db.service.d"
sudo mkdir -p /etc/systemd/man-db.service.d/
sudo cp -f "$WARCHY_PATH/default/systemd/man-db.service.d/override.conf" /etc/systemd/man-db.service.d/
systemd-analyze --no-pager cat-config systemd/man-db.service | grep -E '^ConditionACPower' | gum style --foreground 245 --padding "0 0 0 4"

# Configure dunst systemd service
if [[ -f "/path/to/file" ]]; then
    gum style --foreground 245 "  → Enable dunst.service"
    sudo mv /usr/share/dbus-1/services/org.knopwob.dunst.service /usr/share/dbus-1/services/org.freedesktop.Notifications.service #Fix file name to match the D-Bus name
    #systemctl --user enable dunst.service
fi

# Configure ssh-agent socket
gum style --foreground 245 "  → Copy $WARCHY_PATH/default/systemd/ssh-agent.service.d/override.conf to ~/.config/systemd/user/ssh-agent.service.d"
mkdir -p ~/.config/systemd/user/ssh-agent.service.d/
cp -f "$WARCHY_PATH/default/systemd/ssh-agent.service.d/override.conf" ~/.config/systemd/user/ssh-agent.service.d/

gum style --foreground 245 "  → Enable ssh-agent.socket"
systemctl --user daemon-reload
systemctl --user enable ssh-agent.socket

gum style --foreground 82 "✔  Systemd services configured"
echo
