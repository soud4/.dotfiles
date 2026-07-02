#
# ~/.bashrc
#

# If not running interactively, don't do anything
 [[ $- != *i* ]] && return

## ---- EXPORTS ---- ##
    export HISTCONTROL=ignoreboth
    export HISTSIZE=10000
    export HISTFILESIZE=20000
    export PROMPT_DIRTRIM=3
    export TERM=xterm-256color
    export SUDO_EDITOR=nvim 

    # Solo si estamos dentro de tmux
    if [[ $TERM == "tmux-256color" || $TERM == "tmux" ]]; then
        export TERM=tmux-256color
        export COLORTERM=truecolor
    fi

    # Prompt simple y rápido (sin comandos de Git)
    if [[ $(tty) == /dev/tty* ]]; then
        export PS1="\[\e[1;31m\][TTY \l]\[\e[0m\] \u@\h:\w\$ "
    else
        export PS1='$([[ $? -eq 0 ]] && printf "󰊠 " || printf "\[\e[38;2;255;0;0m\]󰊠 \[\e[0m\]")\[\e[1;34m\]\w\[\e[0m\] '
    fi 

# ----------------- ##


## ---- AUTOMATIC TOOl SETUP ---- ##


## ------------------------------ ##



## ---- ALIASES ---- ##

    alias ls='ls --color=auto -C --group-directories-first'
    alias ll='ls -la'
    alias lf='ls -alF'
    alias la='ls -A'
    alias lt='ls --human-readable --size -1 -S --classify'
    alias lu='du -sh * | sort -h'
    alias lc='find . -type f | wc -l'
    alias ..='cd ..'
    alias ...='cd ../..'
    alias -- -='cd -'
    alias .2="cd ../../"
    alias .3="cd ../../../"
    alias .4="cd ../../../../"
    alias grep='grep --color=auto'
    alias ip='ip -color=auto'
    alias diff='diff --color=auto'
    alias cb='xclip -selection clipboard'

    alias cat="cat -n "
    alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

    ## File managment with prompts
    alias mv='mv -i'
    alias rm='rm -i'
    alias cp='cp -i'
    alias ln='ln -i'
    alias mkdir='mkdir -pv'
    alias tsod='tmux attach -t souda || tmux new-session -s souda'
    alias dusage='du -sh * 2>/dev/null'

    # alias code='code --reuse-window --disable-workspace-trust '

## ----------------- ##


## ---- SHELL OPTIONS ---- ##

    shopt -s autocd
    shopt -s histappend      # Evita sobrescribir el historial, lo agrega en cada sesión
    shopt -s checkwinsize    # Ajusta la terminal automáticamente cuando cambias de tamaño
    shopt -s cmdhist         # Guarda comandos multilínea como una sola entrada en el historial
    shopt -s cdspell         # Autocorrige errores tipográficos al usar cd
    shopt -s dirspell        # Autocorrige autocompletado en nombres de carpetas
    shopt -s globstar        # Habilita ** para búsqueda recursiva
    set -o vi           # Permite usar atajos de Vim en la línea de comandos.

## ----------------------- ##



## ---- FUNCTIONS ---- ##

    mkcd() {
        mkdir -pv "$1"
        cd "$1" || return 1
    }

    extract() {
        if [ -f "$1" ] ; then
            case "$1" in
                *.tar.bz2)   tar xvjf "$1"    ;;
                *.tar.gz)    tar xvzf "$1"    ;;
                *.bz2)       bunzip2 "$1"     ;;
                *.rar)       unrar x "$1"     ;;
                *.gz)        gunzip "$1"      ;;
                *.tar)       tar xvf "$1"     ;;
                *.tbz2)      tar xvjf "$1"    ;;
                *.tgz)       tar xvzf "$1"    ;;
                *.zip)       unzip "$1"       ;;
                *.Z)         uncompress "$1"  ;;
                *.7z)        7z x "$1"        ;;
                *)           echo "No sé cómo extraer '$1'..." ;;
            esac
        else
            echo "'$1' no es un archivo válido."
        fi
    }

    notes() {
        local dir="$HOME/notes"

        mkdir -p "$dir"

        local out query selection

        out=$(
            { find "$dir" -type f 2>/dev/null | sed "s|^$dir/||"; echo; } |
            fzf \
                --prompt="Nota > " \
                --print-query \
                --height=40%
        ) || return

        query=$(printf '%s\n' "$out" | head -n1)
        selection=$(printf '%s\n' "$out" | tail -n +2 | sed '/^$/d')

        if [[ -n "$selection" ]]; then
            nvim "$dir/$selection"
        elif [[ -n "$query" ]]; then
            [[ "$query" != *.* ]] && query="${query}.md"
            nvim "$dir/$query"
        fi
    }
## ------------------- ##



## ---- BINDKEYS ---- ##

    bind -r "\e<"
    bind 'set show-mode-in-prompt on'
    bind 'set vi-ins-mode-string "   "'
    bind 'set vi-cmd-mode-string "   "'

## ------------------ ##

eval "$(zoxide init bash)"

