#!/bin/sh
# install_overrides.sh - Install Hyprland overrides

set -eu

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source helpers
. "$SCRIPT_DIR/helpers.sh"

HOST=""

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --host)
            HOST="$2"
            shift 2
            ;;
        *)
            die "Unknown option: $1. Usage: $0 --host <hostname>"
            ;;
    esac
done

if [ -z "$HOST" ]; then
    die "Hostname not specified. Usage: $0 --host <hostname>"
fi

# Prefer host-specific overrides, fallback to common
HOST_OVERRIDES_FILE="$REPO_ROOT/hosts/$HOST/overrides.conf"
COMMON_OVERRIDES_FILE="$REPO_ROOT/overrides.conf"
HYPRLAND_CONFIG="$HOME/.config/hypr/hyprland.conf"

# Determine which overrides file to use
if [ -f "$HOST_OVERRIDES_FILE" ] && [ -s "$HOST_OVERRIDES_FILE" ]; then
    OVERRIDES_FILE="$HOST_OVERRIDES_FILE"
    log "Using host-specific overrides for $HOST"
elif [ -f "$COMMON_OVERRIDES_FILE" ] && [ -s "$COMMON_OVERRIDES_FILE" ]; then
    OVERRIDES_FILE="$COMMON_OVERRIDES_FILE"
    log "Using common overrides"
else
    log "No overrides file found (skipping)"
    exit 0
fi

# Check if Hyprland config exists
if [ ! -f "$HYPRLAND_CONFIG" ]; then
    log "Hyprland config not found: $HYPRLAND_CONFIG (skipping overrides)"
    exit 0
fi

# Append source line if not already present
source_line="source = $OVERRIDES_FILE"
append_if_absent "$HYPRLAND_CONFIG" "$source_line"

log "Overrides installed successfully"

