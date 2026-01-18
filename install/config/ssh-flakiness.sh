#!/bin/bash

set -eEuo pipefail

gum style --foreground 245 "  → Fixing SSH connection stability..."

# Solve common flakiness with SSH
gum style --foreground 245 "  → Create /etc/sysctl.d/99-sysctl.conf"
echo "net.ipv4.tcp_mtu_probing=1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf | gum style --foreground 245 --padding "0 0 0 4"

gum style --foreground 82 "✔  SSH stability improved"
echo
