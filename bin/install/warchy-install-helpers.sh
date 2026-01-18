#!/usr/bin/env bash
set -eEuo pipefail

# ---------------------------
# Loader for Helper Functions
# ---------------------------
# This file sources all split helper files for backward compatibility
# All helper functions have been split into focused files by responsibility:
# - helpers/validation.sh: Input validation and script execution mode checks
# - helpers/package.sh: Package management, version checking, config parsing
# - helpers/env.sh: Environment variable management

# Get script directory to find helper files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all helper files
source "$SCRIPT_DIR/helpers/validation.sh"
source "$SCRIPT_DIR/helpers/package.sh"
source "$SCRIPT_DIR/helpers/env.sh"
