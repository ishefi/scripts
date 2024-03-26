" Vim configuration.
" Run:
" ```
" ln -s `realpath .vimrc` ~/.vimrc
" ```

set nocompatible              " required
filetype off                  " required
set rnu  " relative line numbers
set number  " line numbers
filetype plugin indent on    " required
syntax on
set splitright

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>


