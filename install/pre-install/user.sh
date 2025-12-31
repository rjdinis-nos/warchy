#!/bin/bash

set -eEo pipefail

gum style --foreground 39 "⚡ Configuring user..."

# If running as root, handle user setup
if [ "$USER" == "root" ]; then
    # Check if WARCHY_USER is set
    if [ -z "$WARCHY_USER" ]; then
        # Try to find existing non-root users
        EXISTING_USERS=($(ls /home 2>/dev/null))
        
        if [ ${#EXISTING_USERS[@]} -gt 0 ]; then
            # Users exist, let user choose or create new one
            gum style --foreground 245 "  → Found existing users: ${EXISTING_USERS[*]}"
            
            # Add "Create new user" option
            CHOICE=$(gum choose "${EXISTING_USERS[@]}" "Create new user")
            
            if [ "$CHOICE" == "Create new user" ]; then
                # Ask for new username
                export WARCHY_USER=$(gum input --placeholder "Enter username to create")
                gum style --foreground 245 "  → Will create new user: $WARCHY_USER"
            else
                export WARCHY_USER="$CHOICE"
                gum style --foreground 245 "  → Selected existing user: $WARCHY_USER"
            fi
        else
            # No existing users, ask for username
            gum style --foreground 245 "  → No existing users found"
            export WARCHY_USER=$(gum input --placeholder "Enter username to create" --value "warchy")
            gum style --foreground 245 "  → Will create user: $WARCHY_USER"
        fi
    else
        gum style --foreground 245 "  → WARCHY_USER is set to: $WARCHY_USER"
    fi
    
    # Check if WARCHY_USER exists in the system
    if id "$WARCHY_USER" &>/dev/null; then
        gum style --foreground 245 "  → User $WARCHY_USER exists in the system"
    else
        # User doesn't exist, create it
        gum style --foreground 245 "  → Creating user $WARCHY_USER..."
        useradd -m "$WARCHY_USER"
        usermod -aG wheel "$WARCHY_USER"
        echo -e "changeme\nchangeme" | passwd "$WARCHY_USER"
        gum style --foreground 245 "  → User $WARCHY_USER created with password: changeme"
    fi
    
    # If WARCHY_PATH is in /root, move it to user's home directory
    USER_HOME=$(eval echo "~$WARCHY_USER")
    NEW_WARCHY_PATH="$USER_HOME/.local/share/warchy"
    
    if [[ "$WARCHY_PATH" == /root/* ]]; then
        gum style --foreground 245 "  → Moving Warchy from $WARCHY_PATH to $NEW_WARCHY_PATH..."
        mkdir -p "$(dirname "$NEW_WARCHY_PATH")"
        
        # Remove destination if it exists to avoid conflicts
        if [ -d "$NEW_WARCHY_PATH" ]; then
            rm -rf "$NEW_WARCHY_PATH"
        fi
        
        mv "$WARCHY_PATH" "$NEW_WARCHY_PATH"
        chown -R "$WARCHY_USER:$WARCHY_USER" "$NEW_WARCHY_PATH"
        
        # Create marker file BEFORE switching to signal parent to stop
        echo "RESTARTING_AS_USER" > /tmp/warchy-restart-marker
        
        # Switch to WARCHY_USER with new path and restart installation
        gum style --foreground 245 "  → Switching to user $WARCHY_USER..."
        sudo -u "$WARCHY_USER" bash -c "cd '$NEW_WARCHY_PATH' && export WARCHY_USER='$WARCHY_USER' && export WARCHY_PATH='$NEW_WARCHY_PATH' && ./install.sh"
        
        # Installation completed, just exit (marker will be cleaned by parent or next run)
        gum style --foreground 82 "✔  Installation completed under user $WARCHY_USER"
        exit 0
    else
        # Make WARCHY_PATH accessible to the target user
        gum style --foreground 245 "  → Making $WARCHY_PATH accessible to $WARCHY_USER..."
        chown -R "$WARCHY_USER:$WARCHY_USER" "$WARCHY_PATH"
        
        # Switch to WARCHY_USER
        gum style --foreground 245 "  → Switching to user $WARCHY_USER..."
        sudo -u "$WARCHY_USER" bash -c "cd '$WARCHY_PATH' && export WARCHY_USER='$WARCHY_USER' && ./install.sh"
        gum style --foreground 82 "✔  Installation completed under user $WARCHY_USER"
        exit 0
    fi
else
    # Not running as root, use current user
    if [ -z "$WARCHY_USER" ]; then
        export WARCHY_USER="$USER"
    fi
    gum style --foreground 245 "  → Running as non-root user: $WARCHY_USER"
fi

gum style --foreground 82 "✔  User configured: $WARCHY_USER"
echo
