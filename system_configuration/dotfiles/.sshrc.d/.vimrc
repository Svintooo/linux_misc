runtime! defaults.vim
let skip_defaults_vim=1

" Turn off the damned mouse support
set mouse=

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
set hlsearch
set ignorecase
