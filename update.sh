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

# --- Symlink any new zellij layouts ---
echo ""
echo "Updating zellij layouts..."
mkdir -p "$HOME/.config/zellij/layouts"
for layout in "$SCRIPT_DIR/zellij/layouts/"*.kdl; do
    if [[ -f "$layout" ]]; then
        name="$(basename "$layout")"
        ln -sf "$layout" "$HOME/.config/zellij/layouts/$name"
        echo "  Linked $name"
    fi
done

echo ""
echo "=== Update complete! ==="
