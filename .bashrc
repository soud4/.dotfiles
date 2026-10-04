# ╔══════════════════════════════════════════════════════════════════╗
# ║                        ~/.bashrc                                 ║
# ║          Configuración interactiva de Bash — modular             ║
# ╚══════════════════════════════════════════════════════════════════╝

# Salir si la sesión NO es interactiva
case "$-" in
    *i*) ;;
    *) return ;;
esac

# Carga modular desde ~/.config/bash/
BASH_CONFIG_DIR="$HOME/.config/bash"
if [[ -d "$BASH_CONFIG_DIR" ]]; then
    for module in "$BASH_CONFIG_DIR"/*.bash; do
        [[ -r "$module" ]] && source "$module"
    done
    unset module
fi
unset BASH_CONFIG_DIR


# Added by Antigravity CLI installer
export PATH="/home/souda/.local/bin:$PATH"
