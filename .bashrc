# ╔══════════════════════════════════════════════════════════════════╗
# ║                        ~/.bashrc                                 ║
# ║          Configuración interactiva de Bash — rápida y limpia     ║
# ╚══════════════════════════════════════════════════════════════════╝

# ── Salir si la sesión NO es interactiva (scripts, ssh sin tty, etc.) ──
case "$-" in
    *i*) ;;
    *) return ;;
esac


# ════════════════════════════════════════════════════════════
# EXPORTS — Variables de entorno globales
# ════════════════════════════════════════════════════════════

export TERM=xterm-256color          # Color básico por defecto
export SUDO_EDITOR=nvim             # Editor que usa sudo visudo, etc.
export EDITOR=nvim                  # Editor por defecto del sistema
export VISUAL=nvim
export PAGER=less                   # Paginador por defecto
export LESS='-R --quit-if-one-screen --ignore-case'

# Historial — más grande, sin duplicados, con timestamp
export HISTSIZE=10000               # Líneas en memoria
export HISTFILESIZE=20000           # Líneas guardadas en disco
export HISTCONTROL=ignoreboth       # Ignora duplicados y líneas con espacio inicial
export HISTTIMEFORMAT='%F %T  '     # Muestra fecha/hora en `history`
export HISTIGNORE='ls:ll:la:cd:pwd:exit:clear:history:bg:fg'

# Colores para man, less y grep
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

# Soporte truecolor dentro de tmux
case "$TERM" in
    tmux*)
        export TERM=tmux-256color
        export COLORTERM=truecolor
        ;;
esac


# ════════════════════════════════════════════════════════════
# PROMPT — PS1 bonito y funcional
# ════════════════════════════════════════════════════════════

# En una TTY real (Ctrl+Alt+F1) usamos prompt minimalista sin nerd fonts
if [[ $(tty) == /dev/tty* ]]; then
    export PS1="\[\e[1;31m\][TTY \l]\[\e[0m\] \u@\h:\w\$ "
else
    # Prompt con nerd font: ícono verde si último comando OK, rojo si falló
    export PS1='$([[ $? -eq 0 ]] && printf "󰊠 " || printf "\[\e[38;2;255;0;0m\]󰊠 \[\e[0m\]")\[\e[1;34m\]\w\[\e[0m\] '
fi

eval "$(fnm env --use-on-cd --shell bash)"


# ════════════════════════════════════════════════════════════
# SHELL OPTIONS — Opciones de comportamiento de Bash
# ════════════════════════════════════════════════════════════

shopt -s autocd          # Escribe solo el nombre de un directorio para entrar en él
shopt -s histappend      # Agrega al historial en vez de sobreescribirlo al salir
shopt -s checkwinsize    # Reajusta LINES/COLUMNS al redimensionar la ventana
shopt -s cmdhist         # Guarda comandos multilínea como una sola entrada
shopt -s cdspell         # Corrige errores tipográficos menores en `cd`
shopt -s dirspell        # Corrige autocompletado de directorios
shopt -s globstar        # Activa ** para búsqueda recursiva en globs
shopt -s nocaseglob      # Globs sin distinción mayúsculas/minúsculas
shopt -s dotglob         # Los globs incluyen archivos ocultos (dotfiles)
shopt -s expand_aliases  # Asegura que los aliases funcionen en todos los contextos

set -o vi                # Modo edición vi en la línea de comandos


# ════════════════════════════════════════════════════════════
# ALIASES — Atajos rápidos del día a día
# ════════════════════════════════════════════════════════════

## ── Listado de archivos ─────────────────────────────────────
alias ls='ls --color=auto -C --group-directories-first'
alias ll='ls -lahF --group-directories-first'   # Lista larga + ocultos + clasificados
alias la='ls -A'                                 # Todos excepto . y ..
alias lf='ls -alF'                               # Lista larga con tipo de archivo
alias lt='ls --human-readable --size -1 -S --classify'  # Ordenado por tamaño
alias lu='du -sh * | sort -h'                    # Uso de disco, ordenado
alias lc='find . -type f | wc -l'               # Cuenta archivos en el directorio
alias tree='tree -C --dirsfirst'                 # Árbol de directorios con color


## ── Seguridad: pedir confirmación antes de sobrescribir/borrar ──
alias mv='mv -i'
alias rm='rm -I --preserve-root'               # -I: pregunta si son 3+ archivos
alias cp='cp -i'
alias ln='ln -i'
alias mkdir='mkdir -pv'                         # Crea directorios padres y verbose

## ── Herramientas con color ───────────────────────────────────
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ip='ip -color=auto'
alias diff='diff --color=auto'
alias cat='cat -n'                              # Muestra números de línea

## ── Sistema ─────────────────────────────────────────────────
alias df='df -h'                               # Uso de disco legible
alias du='du -h'                               # Tamaños legibles
alias free='free -h'                           # RAM en MB/GB
alias ps='ps auxf'                             # Procesos en árbol
alias psg='ps aux | grep -v grep | grep -i'   # Buscar proceso: psg <nombre>
alias top='htop 2>/dev/null || top'            # Prefiere htop si está instalado
alias ports='ss -tulpn'                        # Puertos abiertos (reemplaza netstat)
alias myip='curl -s ifconfig.me && echo'       # IP pública

## ── Edición y navegación rápida ─────────────────────────────
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias e='$EDITOR'
alias reload='source ~/.bashrc && echo "~/.bashrc recargado ✓"'
alias bashrc='$EDITOR ~/.bashrc'               # Editar este archivo rápidamente

## ── Portapapeles ─────────────────────────────────────────────
# alias cb='xclip -selection clipboard'         # Copiar: echo "texto" | cb
# alias cbp='xclip -selection clipboard -o'     # Pegar desde portapapeles

## ── Tmux ────────────────────────────────────────────────────
alias tsod='tmux attach -t souda || tmux new-session -s souda'
alias tls='tmux ls'                            # Listar sesiones
alias tk='tmux kill-session -t'               # Matar sesión: tk <nombre>

## ── Git ─────────────────────────────────────────────────────
# alias g='git'
# alias gs='git status -sb'
# alias ga='git add'
# alias gaa='git add -A'
# alias gc='git commit -m'
# alias gca='git commit --amend'
# alias gp='git push'
# alias gl='git log --oneline --graph --decorate --all -20'
# alias gd='git diff'
# alias gds='git diff --staged'
# alias gb='git branch -vv'
# alias gco='git checkout'
# alias gcb='git checkout -b'
# alias gst='git stash'
# alias gstp='git stash pop'

## ── Dotfiles (bare repo) ────────────────────────────────────
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

## ── Misceláneos ─────────────────────────────────────────────
alias dusage='du -sh * 2>/dev/null | sort -h'

# ════════════════════════════════════════════════════════════
# §5  FUNCIONES — Utilidades más complejas
# ════════════════════════════════════════════════════════════

srun() {
    setsid "$@" >/dev/null 2>&1 &
}
complete -c srun

# Crear directorio y entrar inmediatamente
mkcd() {
    [[ -z "$1" ]] && { echo "Uso: mkcd <directorio>"; return 1; }
    mkdir -pv "$1" && cd "$1" || return 1
}

# Extraer cualquier archivo comprimido automáticamente
extract() {
    if [[ ! -f "$1" ]]; then
        echo "'$1' no es un archivo válido." >&2
        return 1
    fi
    case "$1" in
        *.tar.bz2|*.tbz2) tar xvjf "$1"   ;;
        *.tar.gz|*.tgz)   tar xvzf "$1"   ;;
        *.tar.xz)          tar xvJf "$1"   ;;
        *.tar.zst)         tar --zstd -xvf "$1" ;;
        *.tar)             tar xvf  "$1"   ;;
        *.bz2)             bunzip2  "$1"   ;;
        *.gz)              gunzip   "$1"   ;;
        *.rar)             unrar x  "$1"   ;;
        *.zip)             unzip    "$1"   ;;
        *.Z)               uncompress "$1" ;;
        *.7z)              7z x     "$1"   ;;
        *.xz)              unxz     "$1"   ;;
        *.zst)             zstd -d  "$1"   ;;
        *)  echo "No sé cómo extraer '$1' (extensión desconocida)." >&2; return 1 ;;
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
    [[ -z "$1" ]] && { echo "Uso: bak <archivo>"; return 1; }
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
    bin=$(which "$1" 2>/dev/null) || { echo "'$1' no encontrado en PATH" >&2; return 1; }
    cd "$(dirname "$bin")" || return 1
}


powermode() {
    if [ "$1" = "1" ]; then
        modo="performance"
    else
        modo="powersave"
    fi
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$modo" | sudo tee "$gov" > /dev/null
    done
    echo "Gobernador cambiado a: $modo"
}

net_up() {
    iface="${1:-enp3s0}"
    sudo ip link set "$iface" up
    sudo ip addr add 192.168.0.14/24 dev "$iface"
    sudo ip route add default via 192.168.0.1
}

# ════════════════════════════════════════════════════════════
# READLINE / BINDKEYS — Atajos de teclado
# ════════════════════════════════════════════════════════════

# Quita el atajo conflictivo de Meta+< en modo vi
bind -r "\e<"

# Muestra el modo vi actual en el prompt (INS / CMD)
bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string "  "'
bind 'set vi-cmd-mode-string "󰯉  "'

# Búsqueda en historial con flechas (↑/↓ filtra según lo ya escrito)
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Completado inteligente: ignora mayúsculas y muestra candidatos al 2° Tab
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'          # Colorea el tipo de archivo en el completado
bind 'set visible-stats on'
bind 'set mark-symlinked-directories on'


# ════════════════════════════════════════════════════════════
# HERRAMIENTAS EXTERNAS — Integraciones opcionales
# ════════════════════════════════════════════════════════════

# zoxide: cd inteligente con memoria de directorios frecuentes
#   z <patrón>  →  salta al directorio más probable
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

# Estética de fzf con colores Catppuccin Mocha
export FZF_DEFAULT_OPTS='
  --height=40% --layout=reverse --border=rounded
  --color=fg:#cdd6f4,hl:#f38ba8,fg+:#cdd6f4,bg+:#313244
  --color=hl+:#f38ba8,info:#cba6f7,prompt:#89b4fa,pointer:#f5c2e7
  --color=marker:#a6e3a1,spinner:#f5c2e7,header:#94e2d5
'
# fzf usa fd si está disponible (más rápido que find)
if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Binarios locales del usuario
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# ════════════════════════════════════════════════════════════
# §8  COMPLETADO AVANZADO
# ════════════════════════════════════════════════════════════

# Carga bash-completion si está disponible (paquete bash-completion)
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        source /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        source /etc/bash_completion
    fi
fi

# Completado del alias `dotfiles` igual que git
__git_complete dotfiles __git_main 2>/dev/null || true


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# pnpm
export PNPM_HOME="/home/souda/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
