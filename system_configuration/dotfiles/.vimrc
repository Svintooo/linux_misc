"VERSION: 2020-02-28

" Include system global defaults.vim
runtime! defaults.vim
" In case this file is also a global vim config, prevent loading defaults again
let skip_defaults_vim=1

" Turn off some defaults I don't like
set mouse=
filetype on
filetype plugin on
filetype plugin indent off

" Change how matching brackets are highlighted
" NOTE: Will probably be negated when setting a colorscheme
:hi MatchParen cterm=underline ctermbg=none ctermfg=none

" Add Line numbers Toggle
nmap <F2> :set number!<CR>

" Find next/prev by pressing (shift+)F3
nnoremap <F3> n
nnoremap <S-F3> N

" Toggle autoindent
nmap <F4> :set autoindent!<CR>
imap <F4> <Esc>:set autoindent!<CR>i<Right>

" Misc
set clipboard=unnamed           " Copy to system clipboard
set encoding=utf-8              " Set UTF-8 encoding
set hlsearch
set ignorecase
set smartcase
set noautoindent
set nostartofline
set laststatus=2
set notitle                     " Disable 'Thanks for trying Vim' message
set shortmess=I                 " Disable startup message
set softtabstop=2               " Number of spaces inserted instead of tab characters
set tabstop=2
set expandtab                   " Replace tabs with spaces
set wrap                        " Enable soft linewrap
set wrapmargin=0                " Number of characters from the right

" Include extra config
if !empty(glob("~/.vimrc-custom"))
  source ~/.vimrc-custom
endif
