# ════════════════════════════════════════════════════════════
# READLINE / BINDKEYS — Atajos de teclado
# ════════════════════════════════════════════════════════════

# Quita el atajo conflictivo de Meta+< en modo vi
bind -r "\e<"

# Muestra el modo vi actual en el prompt (INS / CMD)
bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string "\1\e[38;5;142m\2[I]\1\e[0m\2 "'
bind 'set vi-cmd-mode-string "\1\e[38;5;167m\2[N]\1\e[0m\2 "'

# Búsqueda en historial con flechas (↑/↓ filtra según lo ya escrito)
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Completado inteligente: ignora mayúsculas y muestra candidatos al 2° Tab
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'          # Colorea el tipo de archivo en el completado
bind 'set visible-stats on'
bind 'set mark-symlinked-directories on'
