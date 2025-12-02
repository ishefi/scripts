#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Updating your setup ==="
echo ""

# --- Pull latest changes ---
echo "Pulling latest changes..."
git -C "$SCRIPT_DIR" pull --rebase
echo ""

# --- Update Homebrew and packages ---
echo "Updating Homebrew..."
brew update

echo ""
echo "Upgrading packages from Brewfile..."
brew bundle --file="$SCRIPT_DIR/Brewfile"

echo ""
echo "Upgrading all installed packages..."
brew upgrade

# --- Update Oh My Zsh ---
echo ""
echo "Updating Oh My Zsh..."
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    "$HOME/.oh-my-zsh/tools/upgrade.sh"
else
    echo "  Oh My Zsh not installed, skipping"
fi

echo ""
echo "=== Update complete! ==="
