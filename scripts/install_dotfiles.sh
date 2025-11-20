#!/bin/sh
# install_dotfiles.sh - Install dotfiles using GNU Stow

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

COMMON_STOW_FILE="$REPO_ROOT/stow.txt"
HOST_STOW_FILE="$REPO_ROOT/hosts/$HOST/stow.txt"
DOTFILES_DIR="$REPO_ROOT/dotfiles"

# Verify stow is installed
if ! has_cmd stow; then
    die "stow not found. Please install it first (should be in common packages)."
fi

# If dotfiles directory is a git repo, pull updates
if [ -d "$DOTFILES_DIR/.git" ]; then
    log "Dotfiles directory is a git repository, pulling updates..."
    if has_cmd git; then
        cd "$DOTFILES_DIR"
        git pull || warn "Failed to pull dotfiles updates, continuing anyway"
        cd "$REPO_ROOT"
    fi
fi

# Function to stow packages from a file
stow_from_file() {
    stow_file="$1"
    if [ ! -f "$stow_file" ]; then
        return 0
    fi
    
    while IFS= read -r package || [ -n "$package" ]; do
        # Skip comments and empty lines
        case "$package" in
            \#*|"") continue ;;
        esac
        
        package_dir="$DOTFILES_DIR/$package"
        
        if [ ! -d "$package_dir" ]; then
            warn "Package directory not found: $package_dir (skipping)"
            continue
        fi
        
        log "Stowing $package..."
        
        # Remove conflicting defaults before stowing
        # This is a TODO: implement specific cleanup logic per package
        # For now, stow will handle conflicts
        
        stow -d "$DOTFILES_DIR" -t "$HOME" "$package" || warn "Failed to stow $package"
    done < "$stow_file"
}

# Stow common dotfiles
if [ -f "$COMMON_STOW_FILE" ]; then
    log "Stowing common dotfiles..."
    stow_from_file "$COMMON_STOW_FILE"
fi

# Stow host-specific dotfiles
if [ -f "$HOST_STOW_FILE" ]; then
    log "Stowing host-specific dotfiles for $HOST..."
    stow_from_file "$HOST_STOW_FILE"
fi

log "Dotfiles installed successfully"

