# ════════════════════════════════════════════════════════════
# HERRAMIENTAS EXTERNAS — Integraciones y Node / Package Managers
# ════════════════════════════════════════════════════════════

# Fast Node Manager (fnm)
if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd --shell bash)"
fi

# zoxide: cd inteligente con memoria de directorios frecuentes
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

# pnpm
export PNPM_HOME="/home/souda/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
