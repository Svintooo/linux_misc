" defaults.vim
" load it here before the settings in this file.
runtime! defaults.vim
" stop it from loading afterwards if ~/.vimrc is missing.
let skip_defaults_vim=1

" turn off some defaults we don't like
set mouse=
filetype on
filetype plugin on
filetype plugin indent off

" Theme
"colorscheme dark_eyes
"colorscheme molokai
colorscheme desert

" Change how matching brackets are highlighted
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
"set autoindent
set nostartofline
set laststatus=2
set listchars=tab:▸\ ,trail:·   " Use this symbol for invisibles
set notitle                     " Disable 'Thanks for tlying Vim' message
set shortmess=I                 " Disable startup message
set softtabstop=2               " Number of spaces inserted instead of tab characters
set tabstop=2
set expandtab                   " Replace tabs with spaces
set wrap                        " Enable soft linewrap
set wrapmargin=0                " Number of characters from the right