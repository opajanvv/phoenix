# Phoenix

An idempotent bootstrap and re-apply system for Omarchy workstations.

> **Note**: This repository is inspired by and based on the approach explained in the YouTube video ["You installed Omarchy, Now What?"](https://www.youtube.com/watch?v=d23jFJmcaMI) by **typecraft**. The source files for this approach can be found in the [typecraft-dev/omarchy-supplement](https://github.com/typecraft-dev/omarchy-supplement) repository.

## Overview

Phoenix provides a single repository that can:
1. Bootstrap a workstation once
2. Re-apply updates any time (pull latest dotfiles/config and reconcile)

The system is designed with strict idempotency: safe to re-run, no interactive prompts, and guarded edits.

## Features

- **Idempotent**: Safe to run multiple times without duplication
- **Host-specific configuration**: Common packages/dotfiles + per-workstation customization
- **POSIX sh**: Portable shell scripts that work across systems
- **GNU Stow**: Clean dotfile management with symlinks
- **yay-based**: Uses `yay` for all package management (official repos and AUR)
- **Auto-detection**: Automatically detects hostname, or specify with `--host` flag

## Quick Start

1. Clone the repository:
```bash
git clone <repository-url> phoenix
cd phoenix
```

2. Run the installer:
```bash
./install_all.sh
```

The installer will auto-detect your hostname and:
   - Install common packages
   - Install host-specific packages (if any)
   - Stow common dotfiles
   - Stow host-specific dotfiles (if any)
   - Apply Hyprland overrides (host-specific preferred, falls back to common)

You can also specify a hostname explicitly:
```bash
./install_all.sh --host laptop1
```

Or use an environment variable:
```bash
HOST=laptop1 ./install_all.sh
```

## Re-Applying Updates

Phoenix is designed to be re-run safely. To update your system:

```bash
./install_all.sh
```

The installer will:
- Pull latest changes from git (if repository is a git checkout)
- Reconcile package installations (using `--needed` flag)
- Update dotfile symlinks via stow
- Re-apply overrides (idempotently)

If no updates are found, the installer will exit early. Use `-f` or `--force` to re-apply everything anyway:

```bash
./install_all.sh --force
```

## Repository Structure

```
phoenix/
├── install_all.sh          # Main entry point
├── packages.txt            # Common packages for all workstations
├── stow.txt                # Common dotfiles to stow
├── overrides.conf          # Common Hyprland overrides (optional)
├── scripts/
│   ├── helpers.sh          # Utility functions
│   ├── install_packages.sh # Package installation (common + host-specific)
│   ├── install_dotfiles.sh # Dotfile stowing
│   └── install_overrides.sh # Override application
├── hosts/
│   ├── laptop1/            # Host-specific configuration
│   │   ├── packages.txt    # Additional packages for laptop1
│   │   ├── stow.txt        # Additional dotfiles (optional)
│   │   └── overrides.conf  # Host-specific Hyprland overrides
│   └── laptop2/            # Another workstation
│       ├── packages.txt
│       ├── stow.txt
│       └── overrides.conf
└── dotfiles/               # Dotfile packages for stow
    ├── nvim/
    ├── tmux/
    ├── shell/
    ├── starship/
    ├── hypr/
    └── waybar/
```

## Configuration Files

### packages.txt
List of packages to install, one per line. Comments start with `#`.
All packages are installed via `yay`, which handles both official repository and AUR packages.

- Root `packages.txt`: Common packages for all workstations
- `hosts/<hostname>/packages.txt`: Additional packages for specific workstations

### stow.txt
List of dotfile packages to stow, one per line. These correspond to directories in `dotfiles/`.

- Root `stow.txt`: Common dotfiles for all workstations
- `hosts/<hostname>/stow.txt`: Additional dotfiles for specific workstations (optional)

### overrides.conf
Hyprland configuration overrides. This file is automatically sourced by the Hyprland config.

- Root `overrides.conf`: Common overrides (optional)
- `hosts/<hostname>/overrides.conf`: Host-specific overrides (preferred if exists)

Host-specific overrides take precedence over common overrides. This is useful for different monitor setups per workstation.

## Requirements

- Arch Linux (or Arch-based distribution)
- `yay` package manager (handles both official repos and AUR)
- `stow` (installed automatically as base package)

## Idempotency Guarantees

- Packages installed with `--needed` flag (skips already installed)
- File edits guarded: `append_if_absent` for source lines
- Stow re-run does not duplicate symlinks
- Re-running `install_all.sh` makes zero duplicate changes
