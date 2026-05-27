#!/bin/bash

set -eEuo pipefail

# Detect Intel GPU via WSL2 driver directory (works before drivers are installed)
# iigd*.inf dirs are Intel Graphics Driver infs pushed from the Windows host.
# Use a glob check instead of ls|grep to avoid CLICOLOR/pipefail edge-cases.
_intel_detected=false
if ls -d /usr/lib/wsl/drivers/iigd* >/dev/null 2>&1; then
  _intel_detected=true
elif clinfo 2>/dev/null | grep -q "Device Vendor.*Intel\|Platform Vendor.*Intel"; then
  _intel_detected=true
fi

if ! $_intel_detected; then
  gum style --foreground 3 "⚠  No Intel Arc GPU detected, skipping Intel GPU packages"
  return 0
fi

gum style --foreground 39 "⚡ Intel Arc GPU detected, installing Intel GPU packages..."

PKGS_TO_INSTALL="$WARCHY_PATH/install/warchy-intel-yay.packages"

mapfile -t packages < <(grep -v '^#' "$PKGS_TO_INSTALL" | grep -v '^$')
$WARCHY_PATH/bin/install/warchy-pkg install yay "${packages[@]}"

gum style --foreground 82 "✔  Intel GPU packages installed"

# ---------------------------------------------------------------------------
# Intel GPU runtime tuning (SYCL / Level Zero) — XPU inference (PyTorch, ipex-llm,
# llama.cpp SYCL, OpenVINO, etc.). Block is idempotent and guarded by markers.
# ---------------------------------------------------------------------------
ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/bash/envs"
SYCL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/sycl"
mkdir -p "$SYCL_CACHE" "$(dirname "$ENV_FILE")"
touch "$ENV_FILE"

if ! grep -q '# >>> warchy intel-arc env >>>' "$ENV_FILE"; then
  cat >> "$ENV_FILE" <<'EOF'

# >>> warchy intel-arc env >>>
# Intel GPU (SYCL) — Arc / iGPU XPU
# Persistent JIT kernel cache (faster cold-starts between runs).
export SYCL_CACHE_PERSISTENT=1
export SYCL_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sycl"
# NOTE: Do NOT force ONEAPI_DEVICE_SELECTOR=level_zero:0 nor
# SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1 by default.
# On WSL2 + iGPU these flags caused 40-50% drop in tokens/s vs the
# default backend (measured on Arc 140T, May 2026). Re-enable only
# on bare-metal Linux + dGPU after benchmarking.
# <<< warchy intel-arc env <<<
EOF
  gum style --foreground 82 "✔  Intel SYCL env vars added to $ENV_FILE"
else
  gum style --foreground 244 "•  Intel SYCL env vars already present in $ENV_FILE"
fi
