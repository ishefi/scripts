# Scripts

Personal dotfiles and scripts for setting up a new machine.

## Quick Start

```bash
git clone git@github.com:ishefi/scripts.git
cd scripts
./setup.sh
```

## Updating

To pull the latest changes and update packages:

```bash
./update.sh
```

## What Setup Does

1. **Prompts for git configuration** (name, personal email, work email)
   - Detects existing values and offers them as defaults
2. **Installs Homebrew** (if not present)
3. **Installs packages** from `Brewfile` via `brew bundle`
4. **Symlinks config files** (asks before overwriting existing files)
5. **Generates git configs** from templates with your info
6. **Sets up SSH keys** for personal and work GitHub accounts
   - Offers to copy public keys to clipboard
7. **Installs Oh My Zsh**
8. **Configures macOS defaults** (optional):
   - Fast key repeat, disable press-and-hold
   - Tap to click
   - Finder: show hidden files, extensions, path bar
   - Dock: auto-hide, no recent apps
   - Screenshots save to Downloads
9. **Adds `source ~/.myrc`** to `.zshrc`

## Brewfile

Edit `Brewfile` to customize packages:

```ruby
# CLI tools
brew "fortune"
brew "cowsay"
brew "neovim"
brew "zellij"

# GUI apps
cask "rectangle"
cask "caffeine"
cask "ghostty"
```

## What's Included

### Config Files
| File | Description |
|------|-------------|
| `.myrc` | Shell aliases, vi mode, weather + fortune on startup |
| `.vimrc` | Vim configuration |
| `init.lua` | Neovim configuration |
| `.gitconfig.template` | Git config with conditional includes for work/private |
| `.gitignore-global` | Global gitignore |
| `zellij/layouts/` | Zellij layouts |
| `ghostty/config` | Ghostty terminal config (Option as Alt, Shift+Enter fix) |

### Scripts
| Script | Description |
|--------|-------------|
| `notify.py` | Send macOS notifications: `notify.py TITLE TEXT SOUND` |
| `progress.py` | Display progress bar: `progress.py TOTAL DONE` |

### put_in_path/
Scripts symlinked to `/usr/local/bin`:
- `git-debranch` - Delete local branches whose remote is gone
