#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Parse arguments ---
UPDATE_MODE=false
if [[ "$1" == "--update" || "$1" == "update" ]]; then
    UPDATE_MODE=true
fi

# --- Helper functions ---
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local answer

    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n]: " answer
        [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
    else
        read -p "$prompt [y/N]: " answer
        [[ "$answer" =~ ^[Yy] ]]
    fi
}

if $UPDATE_MODE; then
    echo "=== Updating your setup ==="
else
    echo "=== Setting up your new machine ==="
fi
echo "Script directory: $SCRIPT_DIR"
echo ""

# --- Git pull (update mode) ---
if $UPDATE_MODE; then
    echo "Pulling latest changes..."
    git -C "$SCRIPT_DIR" pull --rebase
    echo ""
fi

# --- Prompt for user info (fresh setup only) ---
if ! $UPDATE_MODE; then
    echo "Git configuration:"

    CURRENT_NAME=""
    CURRENT_PERSONAL_EMAIL=""
    CURRENT_WORK_EMAIL=""

    # Try to read existing values
    if [[ -f "$HOME/.gitconfig" ]]; then
        CURRENT_NAME=$(git config --global user.name 2>/dev/null || echo "")
    fi
    if [[ -f "$HOME/.gitconfig-private" ]]; then
        CURRENT_PERSONAL_EMAIL=$(git config --file "$HOME/.gitconfig-private" user.email 2>/dev/null || echo "")
    fi
    if [[ -f "$HOME/.gitconfig-work" ]]; then
        CURRENT_WORK_EMAIL=$(git config --file "$HOME/.gitconfig-work" user.email 2>/dev/null || echo "")
    fi

    # Prompt with defaults
    if [[ -n "$CURRENT_NAME" ]]; then
        read -p "  Full name [$CURRENT_NAME]: " GIT_NAME
        GIT_NAME="${GIT_NAME:-$CURRENT_NAME}"
    else
        read -p "  Full name: " GIT_NAME
    fi

    if [[ -n "$CURRENT_PERSONAL_EMAIL" ]]; then
        read -p "  Personal email [$CURRENT_PERSONAL_EMAIL]: " PERSONAL_EMAIL
        PERSONAL_EMAIL="${PERSONAL_EMAIL:-$CURRENT_PERSONAL_EMAIL}"
    else
        read -p "  Personal email: " PERSONAL_EMAIL
    fi

    if [[ -n "$CURRENT_WORK_EMAIL" ]]; then
        read -p "  Work email [$CURRENT_WORK_EMAIL]: " WORK_EMAIL
        WORK_EMAIL="${WORK_EMAIL:-$CURRENT_WORK_EMAIL}"
    else
        read -p "  Work email: " WORK_EMAIL
    fi
    echo ""
fi

# --- Install/Update Homebrew ---
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for Apple Silicon Macs
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    if $UPDATE_MODE; then
        echo "Updating Homebrew..."
        brew update
    else
        echo "Homebrew already installed"
    fi
fi

# --- Install packages from Brewfile ---
echo ""
echo "Installing packages from Brewfile..."
brew bundle --file="$SCRIPT_DIR/Brewfile"

if $UPDATE_MODE; then
    echo ""
    echo "Upgrading installed packages..."
    brew upgrade
fi

# --- Symlink config files ---
echo ""
echo "Linking config files..."

# .myrc
ln -sf "$SCRIPT_DIR/.myrc" "$HOME/.myrc"
echo "  Linked .myrc"

# .vimrc
ln -sf "$SCRIPT_DIR/.vimrc" "$HOME/.vimrc"
echo "  Linked .vimrc"

# .gitignore-global
ln -sf "$SCRIPT_DIR/.gitignore-global" "$HOME/.gitignore-global"
echo "  Linked .gitignore-global"

# neovim init.lua
mkdir -p "$HOME/.config/nvim"
ln -sf "$SCRIPT_DIR/init.lua" "$HOME/.config/nvim/init.lua"
echo "  Linked nvim/init.lua"

# zellij config and layouts
mkdir -p "$HOME/.config/zellij/layouts"
ln -sf "$SCRIPT_DIR/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
echo "  Linked zellij/config.kdl"
for layout in "$SCRIPT_DIR/zellij/layouts/"*.kdl; do
    if [[ -f "$layout" ]]; then
        name="$(basename "$layout")"
        ln -sf "$layout" "$HOME/.config/zellij/layouts/$name"
        echo "  Linked zellij/layouts/$name"
    fi
done

# ghostty config
mkdir -p "$HOME/.config/ghostty"
ln -sf "$SCRIPT_DIR/ghostty/config" "$HOME/.config/ghostty/config"
echo "  Linked ghostty/config"

# --- Symlink put_in_path scripts to /usr/local/bin ---
echo ""
echo "Linking scripts to /usr/local/bin..."

# Create /usr/local/bin if it doesn't exist
if [[ ! -d /usr/local/bin ]]; then
    echo "  Creating /usr/local/bin (requires sudo)..."
    sudo mkdir -p /usr/local/bin
fi

# Collect and link scripts
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

# --- Generate git config files (fresh setup only) ---
if ! $UPDATE_MODE; then
    echo ""
    echo "Generating git config files..."

    # .gitconfig
    sed -e "s/{{NAME}}/$GIT_NAME/g" "$SCRIPT_DIR/.gitconfig.template" > "$HOME/.gitconfig"
    echo "  Generated ~/.gitconfig"

    # .gitconfig-private
    sed -e "s/{{PERSONAL_EMAIL}}/$PERSONAL_EMAIL/g" "$SCRIPT_DIR/.gitconfig-private.template" > "$HOME/.gitconfig-private"
    echo "  Generated ~/.gitconfig-private"

    # .gitconfig-work
    sed -e "s/{{WORK_EMAIL}}/$WORK_EMAIL/g" "$SCRIPT_DIR/.gitconfig-work.template" > "$HOME/.gitconfig-work"
    echo "  Generated ~/.gitconfig-work"
fi

# --- Oh My Zsh ---
echo ""
if $UPDATE_MODE; then
    echo "Updating Oh My Zsh..."
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        "$HOME/.oh-my-zsh/tools/upgrade.sh"
    else
        echo "  Oh My Zsh not installed, skipping"
    fi
else
    echo "Installing Oh My Zsh..."
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "  Oh My Zsh already installed"
    else
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
fi

# --- Fresh setup only: SSH keys, .zshrc, macOS defaults ---
if ! $UPDATE_MODE; then
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

    # --- SSH Key Setup ---
    echo ""
    echo "SSH Key Setup..."

    SSH_KEY_PRIVATE="$HOME/.ssh/id_rsa_private"
    SSH_KEY_WORK="$HOME/.ssh/id_rsa"

    setup_ssh_key() {
        local key_path="$1"
        local key_name="$2"
        local email="$3"

        if [[ -f "$key_path" ]]; then
            echo "  $key_name key already exists at $key_path"
        else
            if prompt_yes_no "  Generate $key_name SSH key?" "y"; then
                ssh-keygen -t rsa -b 4096 -C "$email" -f "$key_path"
                echo "  Generated $key_path"
            fi
        fi
    }

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    setup_ssh_key "$SSH_KEY_PRIVATE" "Private" "$PERSONAL_EMAIL"
    setup_ssh_key "$SSH_KEY_WORK" "Work" "$WORK_EMAIL"

    # Offer to copy public key to clipboard for GitHub
    for key in "$SSH_KEY_PRIVATE" "$SSH_KEY_WORK"; do
        if [[ -f "$key.pub" ]]; then
            key_name=$(basename "$key")
            if prompt_yes_no "  Copy $key_name.pub to clipboard for GitHub?" "y"; then
                pbcopy < "$key.pub"
                echo "  Copied! Add it at: https://github.com/settings/ssh/new"
                read -p "  Press Enter to continue..."
            fi
        fi
    done

    # --- macOS Defaults ---
    echo ""
    if prompt_yes_no "Configure macOS defaults?" "y"; then
        echo "Configuring macOS defaults..."

        # Keyboard: fast key repeat
        defaults write NSGlobalDomain KeyRepeat -int 2
        defaults write NSGlobalDomain InitialKeyRepeat -int 15
        echo "  Set fast key repeat"

        # Keyboard: disable press-and-hold for keys
        defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
        echo "  Disabled press-and-hold for keys"

        # Trackpad: enable tap to click
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
        defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
        echo "  Enabled tap to click"

        # Finder: show hidden files
        defaults write com.apple.finder AppleShowAllFiles -bool true
        echo "  Finder shows hidden files"

        # Finder: show file extensions
        defaults write NSGlobalDomain AppleShowAllExtensions -bool true
        echo "  Finder shows all file extensions"

        # Finder: show path bar
        defaults write com.apple.finder ShowPathbar -bool true
        echo "  Finder shows path bar"

        # Dock: auto-hide
        defaults write com.apple.dock autohide -bool true
        echo "  Dock auto-hides"

        # Dock: minimize to application icon
        defaults write com.apple.dock minimize-to-application -bool true
        echo "  Minimize to application icon"

        # Dock: don't show recent apps
        defaults write com.apple.dock show-recents -bool false
        echo "  Dock won't show recent apps"

        # Screenshots: save to Downloads
        defaults write com.apple.screencapture location -string "$HOME/Downloads"
        echo "  Screenshots save to Downloads"

        # Restart affected apps
        echo "  Restarting Finder and Dock..."
        killall Finder
        killall Dock

        echo "  Note: Some settings may require a logout/restart to take effect"
    fi
fi

echo ""
if $UPDATE_MODE; then
    echo "=== Update complete! ==="
else
    echo "=== Setup complete! ==="
    echo "Restart your terminal or run: source ~/.zshrc"
fi
