# Scripts

Personal dotfiles and scripts for setting up a new machine.

## Quick Start

```bash
git clone git@github.com:ishefi/scripts.git
cd scripts
./setup.sh
```

The setup script will:
1. Prompt for your name and email addresses (personal & work)
2. Install Homebrew (if not present)
3. Install packages: `fortune`, `cowsay`, `neovim`, `zellij`
4. Symlink config files to your home directory
5. Generate git configs from templates
6. Install Oh My Zsh
7. Add `source ~/.myrc` to your `.zshrc`

## What's Included

### Config Files
| File | Description |
|------|-------------|
| `.myrc` | Shell aliases, vi mode, weather + fortune on startup |
| `.vimrc` | Vim configuration |
| `init.lua` | Neovim configuration |
| `.gitconfig.template` | Git config with conditional includes for work/private |
| `.gitignore-global` | Global gitignore |

### Scripts
| Script | Description |
|--------|-------------|
| `notify.py` | Send macOS notifications: `notify.py TITLE TEXT SOUND` |
| `progress.py` | Display progress bar: `progress.py TOTAL DONE` |

### put_in_path/
Scripts symlinked to `/usr/local/bin`:
- `git-debranch` - Delete local branches whose remote is gone
