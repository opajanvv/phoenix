#!/bin/sh
# install_all.sh - Main entry point for Phoenix bootstrap system
# Orchestrates the installation process for workstation setup

set -eu

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Source helpers
. "$SCRIPTS_DIR/helpers.sh"

FORCE=false
HOST=""

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force)
            FORCE=true
            shift
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        *)
            die "Unknown option: $1. Usage: $0 [-f|--force] [--host <hostname>]"
            ;;
    esac
done

# Detect hostname
if [ -z "$HOST" ]; then
    HOST=$(get_hostname)
fi

log "Detected hostname: $HOST"

# Check for updates if repo is a git checkout
HAS_UPDATES=false
IS_GIT_REPO=false
if [ -d "$SCRIPT_DIR/.git" ]; then
    IS_GIT_REPO=true
    if has_cmd git; then
        cd "$SCRIPT_DIR"
        # Check if there are updates before pulling
        git fetch -q 2>/dev/null || true
        current_head=$(git rev-parse HEAD 2>/dev/null || echo "")
        remote_head=$(git rev-parse @{u} 2>/dev/null || echo "")
        
        if [ -n "$current_head" ] && [ -n "$remote_head" ] && [ "$current_head" != "$remote_head" ]; then
            HAS_UPDATES=true
            log "Pulling latest changes from git repository..."
            git pull || warn "Failed to pull updates, continuing anyway"
        else
            log "Repository is already up to date"
        fi
    else
        warn "git not found, skipping pull"
    fi
fi

# Exit early if no updates and not forced (only for git repos)
if [ "$IS_GIT_REPO" = "true" ] && [ "$HAS_UPDATES" = "false" ] && [ "$FORCE" = "false" ]; then
    log "No updates found. Use -f or --force to re-apply everything anyway."
    exit 0
fi

# Run installation scripts in order
log "Starting installation process..."

# 1. Install packages (common + host-specific)
log "Step 1/3: Installing packages..."
"$SCRIPTS_DIR/install_packages.sh" --host "$HOST" || die "Packages installation failed"

# 2. Install dotfiles
log "Step 2/3: Installing dotfiles..."
"$SCRIPTS_DIR/install_dotfiles.sh" --host "$HOST" || die "Dotfiles installation failed"

# 3. Install overrides
log "Step 3/3: Installing overrides..."
"$SCRIPTS_DIR/install_overrides.sh" --host "$HOST" || die "Overrides installation failed"

log "Installation complete!"

