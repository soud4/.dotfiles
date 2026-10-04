# ════════════════════════════════════════════════════════════
# VIFM — integración con el shell
# ════════════════════════════════════════════════════════════

# `vv` abre vifm y, al salir, deja el shell en el directorio donde estabas
# navegando. vifm no puede hacer esto por sí mismo: un proceso hijo no puede
# cambiar el directorio de su padre, así que escribe la ruta final en un
# archivo temporal (--choose-dir) y es el shell quien hace el cd.
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

# Recordatorio: dentro de vifm, `,c` edita la configuración y la recarga,
# y `:help` abre el manual completo.
