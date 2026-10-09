# ════════════════════════════════════════════════════════════
# EXPORTS — Variables de entorno globales
# ════════════════════════════════════════════════════════════
export PROMPT_DIRTRIMS=1
export TERM=xterm-256color # Color básico por defecto
export SUDO_EDITOR=nvim    # Editor que usa sudo visudo, etc.
export EDITOR=nvim         # Editor por defecto del sistema
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

# Soporte truecolor dentro de tmux
case "$TERM" in
tmux*)
    export TERM=tmux-256color
    export COLORTERM=truecolor
    ;;
esac
PS1='\[\e[38;5;246m\]\u:\h/\[\e[1;38;5;109m\]\W \[\e[1;38;5;214m\]›\[\e[0m\] '
# Binarios locales del usuario
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
