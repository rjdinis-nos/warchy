#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Configuring faster shutdown..."

sudo mkdir -p /etc/systemd/system.conf.d

gum style --foreground 245 "  → Create /etc/systemd/system.conf.d/10-faster-shutdown.conf"
cat <<EOF | sudo tee /etc/systemd/system.conf.d/10-faster-shutdown.conf >/dev/null
[Manager]
DefaultTimeoutStopSec=5s
EOF
sudo systemctl daemon-reload
systemd-analyze --no-pager cat-config systemd/system.conf | grep -E "^DefaultTimeoutStopSec" | gum style --foreground 245 --padding "0 0 0 4"

gum style --foreground 82 "✔  Shutdown timeout reduced to 5s"
echo
