# ════════════════════════════════════════════════════════════
# ALIASES — Atajos rápidos del día a día
# ════════════════════════════════════════════════════════════

## ── Listado de archivos ─────────────────────────────────────
alias la='ls -Alh' # show hidden files
alias ls='ls -aFh --color=always' # add colors and file type extensions
alias lx='ls -lXBh' # sort by extension
alias lk='ls -lSrh' # sort by size
alias lc='ls -lcrh' # sort by change time
alias lu='ls -lurh' # sort by access time
alias lr='ls -lRh' # recursive ls
alias lt='ls -ltrh' # sort by date
alias lm='ls -alh |more' # pipe through 'more'
alias lw='ls -xAh' # wide listing format
alias ll='ls -Fls' # long listing format
alias labc='ls -lap' #alphabetical sort
alias lf="ls -l | egrep -v '^d'" # files only
alias ldir="ls -l | grep -E '^d'" # directories only
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
alias ports='ss -tulpn'                        # Puertos abiertos (reemplaza netstat)
alias myip='curl -s ifconfig.me && echo'       # IP pública

## ── Edición y navegación rápida ─────────────────────────────
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias e='$EDITOR'
alias reload='source ~/.bashrc && echo "# Reloaded config"'
alias bashrc='$EDITOR ~/.bashrc'               # Editar este archivo rápidamente
alias svi='sudo -e'

## ── Tmux ────────────────────────────────────────────────────
alias tsod='tmux attach -t souda || tmux new-session -s souda'
alias tls='tmux ls'                            # Listar sesiones
alias tk='tmux kill-session -t'               # Matar sesión: tk <nombre>

## ── Dotfiles (bare repo) ────────────────────────────────────
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

## ── Misceláneos ─────────────────────────────────────────────
alias dusage='du -sh * 2>/dev/null | sort -h'
