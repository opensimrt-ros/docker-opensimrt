set mouse=n
set encoding=UTF-8
syntax enable
set shell=/bin/bash
set list
set listchars=eol:⏎,tab:␉·,trail:␠,nbsp:⎵
set guifont=DroidSansMono\ Nerd\ Font\ Mono\ 11
set termguicolors
call plug#begin()

Plug 'preservim/nerdtree' |
            \ Plug 'Xuyuanp/nerdtree-git-plugin' |
	    \ Plug 'ryanoasis/vim-devicons'

Plug 'rafi/awesome-vim-colorschemes'
Plug 'tibabit/vim-templates'
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'christoomey/vim-tmux-navigator'
Plug 'ycm-core/YouCompleteMe'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/vim-easy-align'
Plug 'https://github.com/junegunn/vim-github-dashboard.git'
Plug 'lervag/vimtex'
"Plug 'LaTeX-Suite-aka-Vim-LaTeX'

call plug#end()
let g:tex_flavor='xelatex'
let g:airline_powerline_fonts = 1
let g:NERDTreeFileExtensionHighlightFullName = 1

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * NERDTree | if argc() > 0 || exists("s:std_in") | wincmd p | endif
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

let g:webdevicons_enable = 1
let g:webdevicons_enable_nerdtree = 1
let g:webdevicons_enable_airline_tabline = 1
let g:webdevicons_enable_airline_statusline = 1
let g:webdevicons_enable_flagship_statusline = 1
let g:tmpl_search_paths = ['~/Templates']
let g:github_dashboard = { 'username': $GITHUB_USER, 'password': $GITHUB_TOKEN }
let g:vimtex_compiler_latexmk = { 
        \ 'executable' : 'latexmk',
        \ 'options' : [ 
        \   '-xelatex',
        \   '-file-line-error',
        \   '-synctex=1',
        \   '-interaction=nonstopmode',
        \ ],
        \}

colorscheme molokai

function Test() range
  echo system('echo '.shellescape(join(getline(a:firstline, a:lastline), "\n")).'| pbcopy')
endfunction

hi Normal guibg=NONE ctermbg=NONE

filetype plugin indent on


augroup tmux_ft
  au!
  autocmd BufNewFile,BufRead *.tmux   set syntax=bash
augroup END

augroup launch_ft
  au!
  autocmd BufNewFile,BufRead *.launch   set syntax=xml
augroup END

