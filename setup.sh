#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Setting up your new machine ==="
echo "Script directory: $SCRIPT_DIR"
echo ""

# --- Install Homebrew if not present ---
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for Apple Silicon Macs
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew already installed"
fi

# --- Install brew packages ---
echo ""
echo "Installing brew packages..."
PACKAGES=(
    fortune
    cowsay
    neovim
    zellij
)

for pkg in "${PACKAGES[@]}"; do
    if brew list "$pkg" &> /dev/null; then
        echo "  $pkg already installed"
    else
        echo "  Installing $pkg..."
        brew install "$pkg"
    fi
done

# --- Symlink config files ---
echo ""
echo "Linking config files..."

# .myrc
ln -sfv "$SCRIPT_DIR/.myrc" "$HOME/.myrc"

# .vimrc
ln -sfv "$SCRIPT_DIR/.vimrc" "$HOME/.vimrc"

# .gitconfig
ln -sfv "$SCRIPT_DIR/.gitconfig" "$HOME/.gitconfig"

# .gitconfig-private (if exists)
if [[ -f "$SCRIPT_DIR/.gitconfig-private" ]]; then
    ln -sfv "$SCRIPT_DIR/.gitconfig-private" "$HOME/.gitconfig-private"
fi

# .gitignore-global
ln -sfv "$SCRIPT_DIR/.gitignore-global" "$HOME/.gitignore-global"

# neovim init.lua
mkdir -p "$HOME/.config/nvim"
ln -sfv "$SCRIPT_DIR/init.lua" "$HOME/.config/nvim/init.lua"

# --- Symlink put_in_path scripts to /usr/local/bin ---
echo ""
echo "Linking scripts to /usr/local/bin..."

# Create /usr/local/bin if it doesn't exist
if [[ ! -d /usr/local/bin ]]; then
    echo "Creating /usr/local/bin (requires sudo)..."
    sudo mkdir -p /usr/local/bin
fi

# Collect scripts to link, then run sudo once
SCRIPTS_TO_LINK=()
for script in "$SCRIPT_DIR/put_in_path/"*; do
    if [[ -f "$script" && "$(basename "$script")" != "README.md" ]]; then
        SCRIPTS_TO_LINK+=("$script")
    fi
done

if [[ ${#SCRIPTS_TO_LINK[@]} -gt 0 ]]; then
    echo "  Linking ${#SCRIPTS_TO_LINK[@]} scripts (requires sudo)..."
    for script in "${SCRIPTS_TO_LINK[@]}"; do
        name="$(basename "$script")"
        sudo ln -sf "$script" "/usr/local/bin/$name"
        echo "  Linked $name"
    done
fi

# --- Install Oh My Zsh ---
echo ""
echo "Installing Oh My Zsh..."

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "  Oh My Zsh already installed"
else
    # RUNZSH=no prevents oh-my-zsh from launching a new shell
    # KEEP_ZSHRC=yes prevents it from overwriting .zshrc
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# --- Add source line to .zshrc ---
echo ""
echo "Configuring shell..."

SOURCE_LINE='source ~/.myrc'
if [[ -f "$HOME/.zshrc" ]] && grep -qF "$SOURCE_LINE" "$HOME/.zshrc"; then
    echo "  .zshrc already sources .myrc"
else
    echo "  Adding 'source ~/.myrc' to .zshrc"
    echo "" >> "$HOME/.zshrc"
    echo "# Added by scripts/setup.sh" >> "$HOME/.zshrc"
    echo "$SOURCE_LINE" >> "$HOME/.zshrc"
fi

echo ""
echo "=== Setup complete! ==="
echo "Restart your terminal or run: source ~/.zshrc"
