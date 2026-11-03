# by: souda

case "$-" in
*i*) ;;
*) return ;;
esac

case "$TERM" in
tmux* | screen*) export COLORTERM=truecolor ;;
esac

### EXPORTS

export PROMPT_DIRTRIMS=1
export SUDO_EDITOR=nvim # Editor que usa sudo visudo, etc.
export EDITOR=nvim      # Editor por defecto del sistema
export VISUAL=nvim
export PAGER=less # Paginador por defecto
export LESS='-R -F -X -i -M -j.5 -# .5 -~ -N --quit-if-one-screen --ignore-case'

# Historial — más grande, sin duplicados, con timestamp
export HISTSIZE=10000           # Líneas en memoria
export HISTFILESIZE=20000       # Líneas guardadas en disco
export HISTCONTROL=ignoreboth   # Ignora duplicados y líneas con espacio inicial
export HISTTIMEFORMAT='%F %T  ' # Muestra fecha/hora en `history`
export HISTIGNORE='ls:ll:la:cd:pwd:exit:clear:history:bg:fg'

# Colores para man, less y grep
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

export PS1='\[\e[38;5;246m\]\u:\h/\[\e[1;38;5;109m\]\W \[\e[1;38;5;214m\]›\[\e[0m\] '

[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"

### Bash options

shopt -s autocd         # Escribe solo el nombre de un directorio para entrar en él
shopt -s histappend     # Agrega al historial en vez de sobreescribirlo al salir
shopt -s checkwinsize   # Reajusta LINES/COLUMNS al redimensionar la ventana
shopt -s cmdhist        # Guarda comandos multilínea como una sola entrada
shopt -s cdspell        # Corrige errores tipográficos menores en `cd`
shopt -s dirspell       # Corrige autocompletado de directorios
shopt -s globstar       # Activa ** para búsqueda recursiva en globs
shopt -s nocaseglob     # Globs sin distinción mayúsculas/minúsculas
shopt -s dotglob        # Los globs incluyen archivos ocultos (dotfiles)
shopt -s expand_aliases # Asegura que los aliases funcionen en todos los contextos
set -o vi               # Modo edición vi en la línea de comandos

### Aliases

alias la='ls -Alh'                # show hidden files
alias ls='ls -aFh --color=always' # add colors and file type extensions
alias lx='ls -lXBh'               # sort by extension
alias lk='ls -lSrh'               # sort by size
alias lc='ls -lcrh'               # sort by change time
alias lu='ls -lurh'               # sort by access time
alias lr='ls -lRh'                # recursive ls
alias lt='ls -ltrh'               # sort by date
alias lm='ls -alh |more'          # pipe through 'more'
alias lw='ls -xAh'                # wide listing format
alias ll='ls -Fls'                # long listing format
alias labc='ls -lap'              #alphabetical sort
alias lf="ls -l | egrep -v '^d'"  # files only
alias ldir="ls -l | grep -E '^d'" # directories only
alias tree='tree -C --dirsfirst'  # Árbol de directorios con color

alias mv='mv -i'
alias rm='rm -I --preserve-root' # -I: pregunta si son 3+ archivos
alias cp='cp -i'
alias ln='ln -i'
alias mkdir='mkdir -pv' # Crea directorios padres y verbose

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ip='ip -color=auto'
alias diff='diff --color=auto'
alias cat='cat -n' # Muestra números de línea

alias df='df -h'                            # Uso de disco legible
alias du='du -h'                            # Tamaños legibles
alias free='free -h'                        # RAM en MB/GB
alias ps='ps auxf'                          # Procesos en árbol
alias psg='ps aux | grep -v grep | grep -i' # Buscar proceso: psg <nombre>
alias ports='ss -tulpn'                     # Puertos abiertos (reemplaza netstat)

alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias e='$EDITOR'
alias reload='source ~/.bashrc && echo "# Reloaded config"'
alias bashrc='$EDITOR ~/.bashrc' # Editar este archivo rápidamente
alias svi='sudo -e'
alias tsod='tmux attach -t souda || tmux new-session -s souda'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

### Funciones

srun() {
    setsid "$@" >/dev/null 2>&1 &
}
complete -c srun

# Crear directorio y entrar inmediatamente
mkcd() {
    [[ -z "$1" ]] && {
        echo "Uso: mkcd <directorio>"
        return 1
    }
    command mkdir -p "$1" && cd "$1" || return 1
}

# Extraer cualquier archivo comprimido automáticamente
extract() {
    if [[ ! -f "$1" ]]; then
        echo "'$1' no es un archivo válido." >&2
        return 1
    fi
    case "$1" in
    *.tar.bz2 | *.tbz2) tar xvjf "$1" ;;
    *.tar.gz | *.tgz) tar xvzf "$1" ;;
    *.tar.xz) tar xvJf "$1" ;;
    *.tar.zst) tar --zstd -xvf "$1" ;;
    *.tar) tar xvf "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.gz) gunzip "$1" ;;
    *.rar) unrar x "$1" ;;
    *.zip) unzip "$1" ;;
    *.Z) uncompress "$1" ;;
    *.7z) 7z x "$1" ;;
    *.xz) unxz "$1" ;;
    *.zst) zstd -d "$1" ;;
    *)
        echo "No sé cómo extraer '$1' (extensión desconocida)." >&2
        return 1
        ;;
    esac
}

# Ver el proceso que usa un puerto dado
# Uso: whichport 8080
whichport() {
    local port="${1:?Uso: whichport <puerto>}"
    ss -tulpn | grep ":$port"
}

# Backup rápido de un archivo (agrega fecha al nombre)
# Uso: bak archivo.conf
bak() {
    [[ -z "$1" ]] && {
        echo "Uso: bak <archivo>"
        return 1
    }
    cp -v "$1" "${1}.$(date +%Y%m%d_%H%M%S).bak"
}

# Crear archivo y abrirlo con el editor
# Uso: te nuevo.txt
te() {
    touch "$1" && $EDITOR "$1"
}

# Ver las últimas N líneas de un log con follow
# Uso: logf /var/log/syslog [líneas]
logf() {
    tail -f -n "${2:-50}" "${1:?Uso: logf <archivo> [líneas]}"
}

# Resumen rápido del sistema
sysinfo() {
    echo "───────────────────────────────────"
    echo " Host    : $(hostname)"
    echo " Kernel  : $(uname -r)"
    echo " Uptime  : $(uptime -p)"
    echo " Shell   : $BASH_VERSION"
    echo " CPU     : $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
    echo " RAM     : $(free -h | awk '/^Mem/ {print $3 " usado / " $2 " total"}')"
    echo " Disco   : $(df -h / | awk 'NR==2 {print $3 " usado / " $2 " total (" $5 " lleno)"}')"
    echo " IP local: $(hostname -i | awk '{print $1}')"
    echo "───────────────────────────────────"
}

# Ir rápidamente al directorio donde vive un binario
# Uso: cdwhich nvim
cdwhich() {
    local bin
    bin=$(which "$1" 2>/dev/null) || {
        echo "'$1' no encontrado en PATH" >&2
        return 1
    }
    cd "$(dirname "$bin")" || return 1
}

powermode() {
    if [ "$1" = "1" ]; then
        modo="performance"
    else
        modo="powersave"
    fi
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$modo" | sudo tee "$gov" >/dev/null
    done
    echo "Gobernador cambiado a: $modo"
}

net_up() {
    iface="${1:-enp3s0}"
    sudo ip link set "$iface" up
    sudo ip addr add 192.168.0.14/24 dev "$iface"
    sudo ip route add default via 192.168.0.1
}

vv() {
    local dst
    dst="$(mktemp)" || return 1
    vifm --choose-dir "$dst" "$@"
    local dir
    dir="$(cat -- "$dst")"
    command rm -f -- "$dst"
    if [[ -n "$dir" && "$dir" != "$PWD" ]]; then
        cd -- "$dir" || return 1
    fi
}

### Bindkeys

bind -r "\e<"

bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string "\1\e[6 q\2"'
bind 'set vi-cmd-mode-string "\1\e[2 q\2"'
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on' # Colorea el tipo de archivo en el completado
bind 'set visible-stats on'
bind 'set mark-symlinked-directories on'

### Extern tools
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# fzf: búsqueda difusa interactiva (Ctrl+R historial, Ctrl+T archivos)
if [[ -f /usr/share/fzf/key-bindings.bash ]]; then
    source /usr/share/fzf/key-bindings.bash
fi
if [[ -f /usr/share/fzf/completion.bash ]]; then
    source /usr/share/fzf/completion.bash
fi
# Estética de fzf con colores Gruvbox Dark
export FZF_DEFAULT_OPTS='
  --height=40% --layout=reverse --border=rounded
  --color=fg:#ebdbb2,bg:#282828,hl:#fabd2f
  --color=fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f
  --color=info:#83a598,prompt:#d79921,pointer:#fb4934
  --color=marker:#b8bb26,spinner:#d3869b,header:#8ec07c
'
# fzf usa fd si está disponible (más rápido que find)
if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
# Autocompletado general del sistema
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        source /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        source /etc/bash_completion
    fi
fi
# Completado del alias `dotfiles` igual que git
__git_complete dotfiles __git_main 2>/dev/null || true
