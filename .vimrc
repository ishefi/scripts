" Vim configuration.
" Run:
" ```
" ln -s `realpath .vimrc` ~/.vimrc
" ```

set nocompatible              " required
set backspace=indent,eol,start
filetype off                  " required
set rnu  " relative line numbers
set number  " line numbers
filetype plugin indent on    " required
syntax on
set splitright
set clipboard=unnamed " Enables the clipboard between Vim/Neovim and other applications.
set mouse=a " Enable mouse support
set autoindent
set smartindent
set title " Show file title
set cc=89 " Show at 89 column a border for good code style
set ttyfast " Speed up scrolling in Vim




"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>


" Plugin installation
" git clone https://github.com/morhetz/gruvbox.git ~/.vim/pack/dist/start/gruvbox.vim
" git clone https://github.com/vim-airline/vim-airline ~/.vim/pack/dist/start/vim-airline.vim
" git clone https://github.com/neoclide/coc.nvim.git ~/.vim/pack/dist/start/coc.nvim
" git clone --recursive https://github.com/davidhalter/jedi-vim.git ~/.vim/pack/dist/start/jedi-vim.vim
