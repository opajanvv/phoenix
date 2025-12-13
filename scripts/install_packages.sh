#!/bin/sh
# install_packages.sh - Install packages from packages.txt

set -eu

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source helpers
. "$SCRIPT_DIR/helpers.sh"

PACKAGES_FILE="$REPO_ROOT/packages.txt"

# Function to read all packages from a file
read_all_packages() {
    file="$1"

    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        case "$line" in
            \#*|"") continue ;;
        esac
        echo "$line"
    done < "$file"
}

# Function to read packages that need installation
read_packages_to_install() {
    file="$1"

    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        case "$line" in
            \#*|"") continue ;;
        esac

        # Only include package if it's NOT already installed
        if ! yay -Q "$line" >/dev/null 2>&1; then
            echo "$line"
        fi
    done < "$file"
}

# Read all packages for post-install scripts
all_packages=$(read_all_packages "$PACKAGES_FILE" | tr '\n' ' ')

# Read packages that need installation
log "Reading packages from $PACKAGES_FILE"
packages_to_install=$(read_packages_to_install "$PACKAGES_FILE" | tr '\n' ' ')

# Install packages that aren't already installed
if [ -n "$packages_to_install" ]; then
    log "Installing packages with yay: $packages_to_install"
    yay -S --needed --noconfirm $packages_to_install || die "Failed to install packages"
    log "Packages installed successfully"
else
    log "All packages already installed"
fi

# Run post-install scripts for ALL packages (not just newly installed)
log "Checking for post-install scripts..."

# Process each package for post-install scripts
for package in $all_packages; do
    script_path="$REPO_ROOT/install/${package}.sh"
    if [ -f "$script_path" ] && [ -x "$script_path" ]; then
        log "Running post-install script: $script_path"
        "$script_path" || warn "Post-install script failed: $script_path"
    fi
done

log "Post-install scripts completed"
