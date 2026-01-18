#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Updating file location database..."

# Update localdb so that locate will find everything installed
gum style --foreground 245 "  → Start plocate-update.service"
sudo systemctl start plocate-updatedb.service
journalctl -u plocate-updatedb.service -o short-iso | grep -E "Finished|Consumed" | tail -2 | gum style --foreground 245

gum style --foreground 82 "✔  File location database updated"
echo
