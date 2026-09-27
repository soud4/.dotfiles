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
