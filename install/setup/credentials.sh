#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Configuring credential storage..."

CRED_HOME="${WARCHY_CREDENTIAL_HOME:-$HOME/.ssh}"
CRED_KEYRINGS="$CRED_HOME/keyrings"
XDG_KEYRINGS="${XDG_DATA_HOME:-$HOME/.local/share}/keyrings"

mkdir -p "$CRED_HOME"
chmod 700 "$CRED_HOME"

# A mounted VHD reports a different device than $HOME; report which one is in use
if [[ "$(stat -c %d "$CRED_HOME")" != "$(stat -c %d "$HOME")" ]]; then
  gum style --foreground 245 "  → Credential home: $CRED_HOME (portable — separate volume)"
else
  gum style --foreground 245 "  → Credential home: $CRED_HOME (local to this distro)"
fi

mkdir -p "$CRED_KEYRINGS"
chmod 700 "$CRED_KEYRINGS"

# gnome-keyring has no path setting of its own — it always reads
# $XDG_DATA_HOME/keyrings — so the directory is linked into the credential home
# rather than relocated with an env var.
if [[ -L "$XDG_KEYRINGS" ]]; then
  if [[ "$(readlink -f "$XDG_KEYRINGS")" == "$(readlink -f "$CRED_KEYRINGS")" ]]; then
    gum style --foreground 245 "  → Secret Service keyrings already linked to $CRED_KEYRINGS"
  else
    gum style --foreground 3 "  ⚠ $XDG_KEYRINGS points elsewhere ($(readlink "$XDG_KEYRINGS")) — leaving untouched"
  fi
elif [[ -d "$XDG_KEYRINGS" ]]; then
  if [[ -n "$(ls -A "$XDG_KEYRINGS" 2>/dev/null)" ]]; then
    gum style --foreground 245 "  → Migrating existing keyrings to $CRED_KEYRINGS"
    cp -an "$XDG_KEYRINGS/." "$CRED_KEYRINGS/" 2>/dev/null || true
    mv "$XDG_KEYRINGS" "$XDG_KEYRINGS.pre-warchy.$(date +%Y%m%d%H%M%S)"
  else
    rmdir "$XDG_KEYRINGS"
  fi
  ln -s "$CRED_KEYRINGS" "$XDG_KEYRINGS"
  gum style --foreground 245 "  → Linked $XDG_KEYRINGS → $CRED_KEYRINGS"
else
  mkdir -p "$(dirname "$XDG_KEYRINGS")"
  ln -s "$CRED_KEYRINGS" "$XDG_KEYRINGS"
  gum style --foreground 245 "  → Linked $XDG_KEYRINGS → $CRED_KEYRINGS"
fi

gum style --foreground 82 "✔  Credential storage configured"
echo
