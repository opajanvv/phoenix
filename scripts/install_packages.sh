#!/bin/sh
# install_packages.sh - Install common and host-specific packages

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

COMMON_PACKAGES_FILE="$REPO_ROOT/packages.txt"
HOST_PACKAGES_FILE="$REPO_ROOT/hosts/$HOST/packages.txt"

# Check for common packages file
if [ ! -f "$COMMON_PACKAGES_FILE" ]; then
    die "Common packages file not found: $COMMON_PACKAGES_FILE"
fi

# Function to read packages from a file
read_packages() {
    file="$1"
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        case "$line" in
            \#*|"") continue ;;
        esac
        echo "$line"
    done < "$file"
}

# Read packages from both files
log "Reading packages from $COMMON_PACKAGES_FILE"
common_packages=$(read_packages "$COMMON_PACKAGES_FILE")

if [ -f "$HOST_PACKAGES_FILE" ]; then
    log "Reading host-specific packages from $HOST_PACKAGES_FILE"
    host_packages=$(read_packages "$HOST_PACKAGES_FILE")
else
    log "Host-specific packages file not found: $HOST_PACKAGES_FILE (skipping)"
    host_packages=""
fi

# Combine and remove duplicates (using sort -u)
all_packages=$(printf "%s\n%s\n" "$common_packages" "$host_packages" | sort -u | tr '\n' ' ')

if [ -z "$all_packages" ]; then
    warn "No packages to install"
    exit 0
fi

# Install all packages
log "Installing packages (common + host-specific, duplicates removed)..."
install_packages "$all_packages"

log "Packages installed successfully"

