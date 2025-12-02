#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

file_exists_and_skip() {
    local file="$1"
    local description="$2"

    if [[ -e "$file" ]]; then
        if ! prompt_yes_no "  $description already exists. Overwrite?" "n"; then
            echo "  Skipping $description"
            return 0
        fi
    fi
    return 1
}

echo "=== Setting up your new machine ==="
echo "Script directory: $SCRIPT_DIR"
echo ""

# --- Prompt for user info (with existing value detection) ---
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

# --- Install packages from Brewfile ---
echo ""
echo "Installing packages from Brewfile..."
brew bundle --file="$SCRIPT_DIR/Brewfile"

# --- Symlink config files ---
echo ""
echo "Linking config files..."

# .myrc
if ! file_exists_and_skip "$HOME/.myrc" "~/.myrc"; then
    ln -sfv "$SCRIPT_DIR/.myrc" "$HOME/.myrc"
fi

# .vimrc
if ! file_exists_and_skip "$HOME/.vimrc" "~/.vimrc"; then
    ln -sfv "$SCRIPT_DIR/.vimrc" "$HOME/.vimrc"
fi

# .gitignore-global
if ! file_exists_and_skip "$HOME/.gitignore-global" "~/.gitignore-global"; then
    ln -sfv "$SCRIPT_DIR/.gitignore-global" "$HOME/.gitignore-global"
fi

# neovim init.lua
mkdir -p "$HOME/.config/nvim"
if ! file_exists_and_skip "$HOME/.config/nvim/init.lua" "~/.config/nvim/init.lua"; then
    ln -sfv "$SCRIPT_DIR/init.lua" "$HOME/.config/nvim/init.lua"
fi

# --- Generate git config files from templates ---
echo ""
echo "Generating git config files..."

# .gitconfig
if ! file_exists_and_skip "$HOME/.gitconfig" "~/.gitconfig"; then
    sed -e "s/{{NAME}}/$GIT_NAME/g" "$SCRIPT_DIR/.gitconfig.template" > "$HOME/.gitconfig"
    echo "  Generated ~/.gitconfig"
fi

# .gitconfig-private
if ! file_exists_and_skip "$HOME/.gitconfig-private" "~/.gitconfig-private"; then
    sed -e "s/{{PERSONAL_EMAIL}}/$PERSONAL_EMAIL/g" "$SCRIPT_DIR/.gitconfig-private.template" > "$HOME/.gitconfig-private"
    echo "  Generated ~/.gitconfig-private"
fi

# .gitconfig-work
if ! file_exists_and_skip "$HOME/.gitconfig-work" "~/.gitconfig-work"; then
    sed -e "s/{{WORK_EMAIL}}/$WORK_EMAIL/g" "$SCRIPT_DIR/.gitconfig-work.template" > "$HOME/.gitconfig-work"
    echo "  Generated ~/.gitconfig-work"
fi

# --- Symlink put_in_path scripts to /usr/local/bin ---
echo ""
echo "Linking scripts to /usr/local/bin..."

# Create /usr/local/bin if it doesn't exist
if [[ ! -d /usr/local/bin ]]; then
    echo "Creating /usr/local/bin (requires sudo)..."
    sudo mkdir -p /usr/local/bin
fi

# Collect scripts to link
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

echo ""
echo "=== Setup complete! ==="
echo "Restart your terminal or run: source ~/.zshrc"
