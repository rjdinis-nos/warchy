#!/bin/bash

set -eEuo pipefail

gum style --foreground 39 "⚡ Configuring development tools..."

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"


# Configure Neovim
[[ -d "$XDG_CONFIG_HOME/nvim" ]] && rm -rf "$XDG_CONFIG_HOME/nvim"
if git clone --depth 1 https://github.com/LazyVim/starter "$XDG_CONFIG_HOME/nvim" >/dev/null 2>&1; then
  rm -rf "$XDG_CONFIG_HOME/nvim/.git"
  gum style --foreground 245 "  → Git clone LazyVim successful to $XDG_CONFIG_HOME/nvim"
else
  gum log --level error "  ✖  Failed to clone LazyVim. Please check your internet connection or URL."
fi


# Configure wget
mkdir -p "$XDG_CONFIG_HOME"/wget
mkdir -p "$XDG_CACHE_HOME"/wget
echo hsts-file \= "$XDG_CACHE_HOME"/wget/wget-hsts >>"$XDG_CONFIG_HOME/wget/wgetrc"
gum style --foreground 245 "  → Configure wget"


gum style --foreground 82 "✔  Development tools configuration completed"
echo
