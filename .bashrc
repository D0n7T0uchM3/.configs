# ~/.bashrc
# ========================
# PERSONAL BASHRC CONFIGURATION
# ========================

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ========================
# ENVIRONMENT VARIABLES
# ========================
export EDITOR=vim
export VISUAL=vim
export PAGER=less
export LESS='-R'
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="ls:ps:history:exit:pwd:clear"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color

# Add local bin to PATH
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# ========================
# SHELL OPTIONS
# ========================
shopt -s histappend      # Append to history file
shopt -s checkwinsize    # Check window size after each command
shopt -s globstar        # Enable ** pattern matching
shopt -s dotglob         # Include dotfiles in pathname expansion
shopt -s autocd          # Type directory name to cd into it
shopt -s cdspell         # Auto-correct typos in directory names

# ========================
# PROMPT CUSTOMIZATION
# ========================
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

set_prompt() {
    local EXIT_CODE="$?"
    
    # Colors
    local RED='\[\033[0;31m\]'
    local GREEN='\[\033[0;32m\]'
    local YELLOW='\[\033[1;33m\]'
    local BLUE='\[\033[0;34m\]'
    local PURPLE='\[\033[0;35m\]'
    local CYAN='\[\033[0;36m\]'
    local WHITE='\[\033[1;37m\]'
    local RESET='\[\033[0m\]'
    
    # Git branch
    local GIT_BRANCH="$(parse_git_branch)"
    
    # Exit code indicator
    local EXIT_INDICATOR=""
    [[ $EXIT_CODE != 0 ]] && EXIT_INDICATOR="${RED}✗${RESET} "
    
    # User and host
    local USER_HOST="${GREEN}\u@\h${RESET}"
    
    # Current directory
    local CURRENT_DIR="${BLUE}\w${RESET}"
    
    # Git branch color
    if [[ -n $GIT_BRANCH ]]; then
        GIT_BRANCH="${PURPLE}${GIT_BRANCH}${RESET}"
    fi
    
    # Set PS1
    PS1="${EXIT_INDICATOR}${USER_HOST}:${CURRENT_DIR}${GIT_BRANCH}\n${WHITE}\$${RESET} "
}

PROMPT_COMMAND=set_prompt

# ========================
# ALIASES
# ========================

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

alias ls='ls --color=auto'
alias ll='ls -alFh --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias lsd='ls -l | grep "^d"'
alias tree='tree -C'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias igrep='grep -i'

# ========================
# FUNCTIONS
# ========================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar x "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create a backup of a file
backup() {
    cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
}

# Calculator
calc() {
    echo "$*" | bc -l
}

# Create a new script file with shebang
newscript() {
    if [ -z "$1" ]; then
        echo "Usage: newscript <filename>"
        return 1
    fi
    echo '#!/bin/bash' > "$1"
    chmod +x "$1"
    vim "$1"
}

# Find file by name
ff() {
    find . -type f -iname "*$1*" 2>/dev/null
}

# Find directory by name
fd() {
    find . -type d -iname "*$1*" 2>/dev/null
}

# Count lines of code in a directory
cloc() {
    find "${1:-.}" -name "*.${2:-py}" -exec wc -l {} + | sort -n
}

# ========================
# COMPLETION
# ========================
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Enable git completion
if [ -f ~/.git-completion.bash ]; then
    . ~/.git-completion.bash
fi

# ========================
# WELCOME MESSAGE
# ========================
echo
echo -e "\033[1;32mWelcome back, \033[1;34m$(whoami)\033[0m!"
echo -e "\033[1;36mSystem: \033[0m$(uname -srm)"
echo -e "\033[1;36mUptime: \033[0m$(uptime -p | sed 's/up //')"
echo -e "\033[1;36mDate: \033[0m$(date '+%Y-%m-%d %H:%M:%S')"
echo

# ========================
# CUSTOM WORKSPACE
# ========================
# Auto-change to projects directory if it exists
PROJECTS_DIR="$HOME/projects"
[ -d "$PROJECTS_DIR" ] && cd "$PROJECTS_DIR"

# ========================
# LOCAL OVERRIDES
# ========================
# Load machine-specific settings if they exist
[ -f ~/.bashrc_local ] && source ~/.bashrc_local

# ========================
# FINAL SETTINGS
# ========================
# Set window title
echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\007"
