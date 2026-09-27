# ════════════════════════════════════════════════════════════
# FUNCIONES — Utilidades del sistema
# ════════════════════════════════════════════════════════════

srun() {
    setsid "$@" >/dev/null 2>&1 &
}
complete -c srun

# Crear directorio y entrar inmediatamente
mkcd() {
    [[ -z "$1" ]] && { echo "Uso: mkcd <directorio>"; return 1; }
    command mkdir -p "$1" && cd "$1" || return 1
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
