#!/bin/sh
# helpers.sh - Utility functions for Phoenix bootstrap scripts
# POSIX sh compatible utilities

set -eu

# Logging utilities
log() {
    echo "[INFO] $*"
}

warn() {
    echo "[WARN] $*" >&2
}

die() {
    echo "[ERROR] $*" >&2
    exit 1
}

has_cmd() {
    # Check if a command exists
    command -v "$1" >/dev/null 2>&1
}

get_hostname() {
    # Get hostname, preferring HOST environment variable, then hostname command
    if [ -n "${HOST:-}" ]; then
        echo "$HOST"
    elif has_cmd hostname; then
        hostname
    else
        # Fallback: read from /etc/hostname
        if [ -f /etc/hostname ]; then
            head -n1 /etc/hostname | tr -d '\n'
        else
            die "Cannot determine hostname"
        fi
    fi
}

append_if_absent() {
    # Append a line to a file if it doesn't already exist
    # Usage: append_if_absent <file> <line>
    file="$1"
    line="$2"
    
    if [ ! -f "$file" ]; then
        die "File does not exist: $file"
    fi
    
    if ! grep -qF "$line" "$file" 2>/dev/null; then
        echo "$line" >> "$file"
        log "Appended to $file: $line"
    else
        log "Line already present in $file, skipping"
    fi
}

install_packages() {
    # Install packages using yay (handles both official repos and AUR)
    # Usage: install_packages <packages>
    packages="$1"
    
    if [ -z "$packages" ]; then
        return 0
    fi
    
    if ! has_cmd yay; then
        die "yay not found. This script requires yay to be installed."
    fi
    
    log "Installing packages with yay: $packages"
    yay -S --needed --noconfirm $packages || die "Failed to install packages"
}


