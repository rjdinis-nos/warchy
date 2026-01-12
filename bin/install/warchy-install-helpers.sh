#!/usr/bin/env bash
set -euo pipefail

# ---------------------------
# Helper Functions
# ---------------------------

# Remove a block of text in a file between start_marker and end_marker
remove_marked_block() {
    local file="$1"
    local start_marker="$2"
    local end_marker="$3"

    # Escape $ for sed usage
    local escaped_end_marker="${end_marker//$/\\$}"

    if grep -qF "$start_marker" "$file" && grep -qF "$end_marker" "$file"; then
        sed -i "\|$start_marker|,\|$escaped_end_marker|d" "$file"
    fi
}

# Append a block to a file idempotently
append_env_block() {
    local file="$1"
    local block="$2"

    # Determine start and end markers from the block
    local start_marker end_marker
    start_marker="$(head -n1 <<<"$block")"
    end_marker="$(tail -n1 <<<"$block")"

    # Remove any existing block in the file
    remove_marked_block "$file" "$start_marker" "$end_marker"

    # Append newline if last line is not empty
    [ -s "$file" ] && [ "$(tail -n1 "$file")" != "" ] && echo >> "$file"

    # Append the new block
    echo "$block" >> "$file"
}
