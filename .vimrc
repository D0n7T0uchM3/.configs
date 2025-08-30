" ========================
" TYOM VIM CONFIG
" ========================

" Basic setup
set nocompatible
syntax enable
filetype plugin indent on

" ========================
" VISUAL APPEARANCE
" ========================

" Color scheme (using built-in schemes)
colorscheme slate

" Line numbers
set number
set cursorline

" Syntax highlighting
syntax on

" Status line
set laststatus=2
set statusline=
set statusline+=%#PmenuSel#
set statusline+=%#LineNr#
set statusline+=\ %f
set statusline+=%m
set statusline+=%=
set statusline+=%#CursorColumn#
set statusline+=\ %y
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\[%{&fileformat}\]
set statusline+=\ %p%%
set statusline+=\ %l:%c
set statusline+=\

" ========================
" EDITING BEHAVIOR
" ========================

" Indentation
set autoindent
set smartindent
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab

" Text rendering
set encoding=utf-8
set linebreak
set wrap
set textwidth=80
set colorcolumn=+1

" Search
set ignorecase
set smartcase
set incsearch
set hlsearch

" UI
set showcmd
set showmode
set showmatch
set matchtime=2
set scrolloff=5
set sidescrolloff=5
set noerrorbells
set visualbell
set t_vb=

" Splits
set splitbelow
set splitright

" Backup files
set nobackup
set nowritebackup
set noswapfile
set undofile
set undodir=~/.vim/undodir

" Wildmenu
set wildmenu
set wildmode=full
set wildignore=*.o,*~,*.pyc,*.class,*.git,*node_modules*

" ========================
" ADDITIONAL SETTINGS
" ========================

" Mouse support
set mouse=a

" Command line completion
set wildchar=<Tab>
set wildmenu
set wildmode=full

" History
set history=1000
set undolevels=1000

" Clipboard integration (if available)
if has('clipboard')
  set clipboard=unnamedplus
endif

" Smooth scrolling
set ttyfast

" Timeout settings
set timeoutlen=500
set ttimeoutlen=50

" ========================
" CUSTOM HIGHLIGHTING
" ========================

" Custom syntax highlights
highlight Comment cterm=italic gui=italic
highlight CursorLine cterm=NONE ctermbg=234 guibg=#1c1c1c
highlight ColorColumn ctermbg=234 guibg=#1c1c1c
highlight Search cterm=bold ctermfg=white ctermbg=darkblue guibg=#000080

" ========================
" FINAL OPTIMIZATIONS
" ========================

" Performance
set lazyredraw
set ttyfast

" Encoding
set fileencodings=utf-8,default,latin1

" Match pairs
set matchpairs+=<:>

