#!/usr/bin/env bash
# ================================================================
#  Connectivity & Power Management Audit  -  Linux (Debian/Ubuntu)
#  Target : Debian Server (WireGuard Web UI)
#  Features : Bilingual UI, Persistent Config, Auto-Remediation
# ================================================================
set -euo pipefail

# ================================================================
#  PATHS & VARIABLES
# ================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/audit_config.json"
LOG_DIR="${SCRIPT_DIR}/logs"
NO_LOG=0
SHOW_HELP=0
DO_CONFIGURE=0
RESET_CONFIG=0
EXPORT_JSON=0

# CLI overrides
CLI_IP=""
CLI_PORT=""
CLI_PING=""
CLI_LANG=""

# ================================================================
#  COLORS (ANSI)
# ================================================================
R='\033[0m'         # Reset
TITLE='\033[1;37m'  # Bold White
HEAD='\033[1;36m'   # Bold Cyan
COK='\033[0;32m'    # Green
CWARN='\033[0;33m'  # Yellow
CERR='\033[0;31m'   # Red
DIM='\033[0;90m'    # Dark Gray
ACCENT='\033[0;36m' # Cyan
CRESET='\033[0;37m' # Gray

# ================================================================
#  BILINGUAL STRINGS
# ================================================================
declare -A S_en S_fr

S_en=(
    [title]="CONNECTIVITY & POWER MANAGEMENT AUDIT"
    [target]="Target"
    [port]="Port"
    [step]="STEP"
    [adminOk]="Running as root"
    [adminWarn]="Not root - Mitigation restricted (run as sudo for full features)"
    [arpSection]="ARP Resolution & Routing"
    [arpFlushed]="Cache flushed for"
    [arpSkip]="Skipping cache flush - requires root"
    [arpOk]="ARP Resolved"
    [arpFail]="ARP Failed"
    [arpSleep]="server may be in deep sleep / power-save"
    [routeOk]="Route found"
    [routeFail]="No route to host"
    [latSection]="Latency Profile"
    [pings]="pings"
    [firstPkt]="First packet"
    [timeout]="Timeout"
    [avgRest]="Avg (rest)"
    [minMax]="Min / Max"
    [spikeDelta]="Spike delta"
    [spikeWarn]="NIC likely power-saving"
    [latStable]="Latency stable"
    [latFail]="Insufficient replies"
    [tcpSection]="TCP Port Probe"
    [portOpen]="OPEN"
    [portClosed]="CLOSED or Filtered"
    [httpSection]="HTTP Reachability Check"
    [httpOk]="HTTP responded"
    [httpFail]="HTTP unreachable"
    [traceSection]="Traceroute (first 5 hops)"
    [traceNoCmd]="traceroute not available - install with: sudo apt install traceroute"
    [dnsSection]="DNS Resolution Check"
    [dnsOk]="DNS resolved"
    [dnsFail]="DNS resolution failed"
    [nicSection]="NIC Power Management (ethtool)"
    [nicNoCmd]="ethtool not available - install with: sudo apt install ethtool"
    [nicNone]="No active NICs found"
    [osSleep]="OS Sleep/Suspend Targets"
    [summaryTitle]="AUDIT SUMMARY"
    [allOk]="All checks passed - server looks healthy."
    [someWarn]="check(s) require attention."
    [completed]="Completed at"
    [cfgTitle]="CONFIGURATION"
    [cfgCurrent]="Current settings"
    [cfgIpPrompt]="Enter server IP address"
    [cfgPortPrompt]="Enter target TCP port (1-65535)"
    [cfgPingPrompt]="Enter number of ping probes (1-20)"
    [cfgLangPrompt]="Choose language / Choisir la langue  [en/fr]"
    [cfgSaved]="Configuration saved."
    [cfgInvalidIp]="Invalid IP address format."
    [cfgInvalidPort]="Port must be between 1 and 65535."
    [cfgInvalidPing]="Ping count must be between 1 and 20."
    [cfgInvalidLang]="Language must be 'en' or 'fr'."
    [cfgReset]="Configuration reset to defaults."
    [logSaved]="Log saved to"
    [notSupported]="Not supported"
    [spikeOf]="First-packet spike of"
    [depCheck]="Dependency Check"
    [depMissing]="Missing (optional)"
    [depOk]="Available"
    [remTitle]="REMEDIATION PLAYBOOK (RUN AS ROOT)"
    [remNone]="SYSTEM FULLY OPTIMIZED - ZERO ANOMALIES DETECTED"
    [runRemediation]="Would you like to automatically apply these fixes now? [y/N]"
    [remApplied]="Fixes applied successfully."
    [jsonExported]="JSON Export saved to"
    [lossAndJitter]="Loss / Jitter"
)

S_fr=(
    [title]="AUDIT CONNECTIVITE & GESTION D'ENERGIE"
    [target]="Cible"
    [port]="Port"
    [step]="ETAPE"
    [adminOk]="Execution en tant que root"
    [adminWarn]="Pas root - Mitigation restreinte (sudo requis pour tout)"
    [arpSection]="Resolution ARP & Routage"
    [arpFlushed]="Cache vide pour"
    [arpSkip]="Flush ignore - root requis"
    [arpOk]="ARP Resolu"
    [arpFail]="ARP Echoue"
    [arpSleep]="serveur en veille profonde / economie energie"
    [routeOk]="Route trouvee"
    [routeFail]="Aucune route vers l'hote"
    [latSection]="Profil de Latence"
    [pings]="pings"
    [firstPkt]="Premier paquet"
    [timeout]="Expiration"
    [avgRest]="Moy (reste)"
    [minMax]="Min / Max"
    [spikeDelta]="Delta pic"
    [spikeWarn]="NIC probablement en economie d'energie"
    [latStable]="Latence stable"
    [latFail]="Reponses insuffisantes"
    [tcpSection]="Sonde Port TCP"
    [portOpen]="OUVERT"
    [portClosed]="FERME ou Filtre"
    [httpSection]="Verification Accessibilite HTTP"
    [httpOk]="HTTP a repondu"
    [httpFail]="HTTP inaccessible"
    [traceSection]="Traceroute (5 premiers sauts)"
    [traceNoCmd]="traceroute absent - installer avec: sudo apt install traceroute"
    [dnsSection]="Verification Resolution DNS"
    [dnsOk]="DNS resolu"
    [dnsFail]="Resolution DNS echouee"
    [nicSection]="Gestion Energie NIC (ethtool)"
    [nicNoCmd]="ethtool absent - installer avec: sudo apt install ethtool"
    [nicNone]="Aucune NIC active trouvee"
    [osSleep]="Cibles Veille/Suspension OS"
    [summaryTitle]="RESUME DE L'AUDIT"
    [allOk]="Tous les tests passes - serveur en bonne sante."
    [someWarn]="test(s) necessitent attention."
    [completed]="Termine a"
    [cfgTitle]="CONFIGURATION"
    [cfgCurrent]="Parametres actuels"
    [cfgIpPrompt]="Entrez l'adresse IP du serveur"
    [cfgPortPrompt]="Entrez le port TCP cible (1-65535)"
    [cfgPingPrompt]="Entrez le nombre de pings (1-20)"
    [cfgLangPrompt]="Choisir la langue / Choose language  [fr/en]"
    [cfgSaved]="Configuration sauvegardee."
    [cfgInvalidIp]="Format d'adresse IP invalide."
    [cfgInvalidPort]="Le port doit etre entre 1 et 65535."
    [cfgInvalidPing]="Le nombre de pings doit etre entre 1 et 20."
    [cfgInvalidLang]="La langue doit etre 'fr' ou 'en'."
    [cfgReset]="Configuration reinitialisee par defaut."
    [logSaved]="Journal sauvegarde dans"
    [notSupported]="Non supporte"
    [spikeOf]="Pic premier paquet de"
    [depCheck]="Verification Dependances"
    [depMissing]="Absent (optionnel)"
    [depOk]="Disponible"
    [remTitle]="PLAYBOOK DE REMEDIATION (ROOT REQUIS)"
    [remNone]="SYSTEME OPTIMISE - ZERO ANOMALIE DETECTEE"
    [runRemediation]="Voulez-vous appliquer ces correctifs automatiquement maintenant ? [y/N]"
    [remApplied]="Correctifs appliques avec succes."
    [jsonExported]="Export JSON enregistre sous"
    [lossAndJitter]="Perte / Jitter"
)

# ================================================================
#  STRING GETTER
# ================================================================
LANG_KEY="en"
get_s() {
    local key="$1"
    if [[ "$LANG_KEY" == "fr" ]]; then echo "${S_fr[$key]:-$key}"
    else echo "${S_en[$key]:-$key}"; fi
}

# ================================================================
#  CONFIG HELPERS
# ================================================================
load_config() {
    CFG_LANG="en"; CFG_IP="192.168.1.254"; CFG_PORT="51821"; CFG_PING="5"

    if [[ -f "$CONFIG_FILE" ]]; then
        local lang ip port ping_n
        # Try Python, fallback to grep
        if command -v python3 &>/dev/null; then
            lang=$(python3 -c "import json,sys; d=json.load(open('$CONFIG_FILE')); print(d.get('Language','en'))" 2>/dev/null || echo "en")
            ip=$(python3 -c "import json,sys; d=json.load(open('$CONFIG_FILE')); print(d.get('ServerIP','192.168.1.254'))" 2>/dev/null || echo "192.168.1.254")
            port=$(python3 -c "import json,sys; d=json.load(open('$CONFIG_FILE')); print(d.get('TargetPort',51821))" 2>/dev/null || echo "51821")
            ping_n=$(python3 -c "import json,sys; d=json.load(open('$CONFIG_FILE')); print(d.get('PingCount',5))" 2>/dev/null || echo "5")
        else
            lang=$(grep -oP '(?<="Language": ")[^"]*' "$CONFIG_FILE" 2>/dev/null || echo "en")
            ip=$(grep -oP '(?<="ServerIP": ")[^"]*' "$CONFIG_FILE" 2>/dev/null || echo "192.168.1.254")
            port=$(grep -oP '(?<="TargetPort": )\d+' "$CONFIG_FILE" 2>/dev/null || echo "51821")
            ping_n=$(grep -oP '(?<="PingCount": )\d+' "$CONFIG_FILE" 2>/dev/null || echo "5")
        fi

        [[ "$lang" =~ ^(en|fr)$ ]] && CFG_LANG="$lang"
        [[ "$ip"   =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && CFG_IP="$ip"
        [[ "$port" =~ ^[0-9]+$ ]] && CFG_PORT="$port"
        [[ "$ping_n" =~ ^[0-9]+$ ]] && CFG_PING="$ping_n"
    fi
}

save_config() {
    cat > "$CONFIG_FILE" <<EOF
{
  "Language": "$CFG_LANG",
  "ServerIP": "$CFG_IP",
  "TargetPort": $CFG_PORT,
  "PingCount": $CFG_PING
}
EOF
}

# ================================================================
#  VALIDATION
# ================================================================
is_valid_ip() { [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }
is_valid_port() { [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= 1 && $1 <= 65535 )); }
is_valid_ping() { [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= 1 && $1 <= 20 )); }

# ================================================================
#  DISPLAY HELPERS
# ================================================================
LOG_BUFFER=""
log_append() { LOG_BUFFER+="$1"$'\n'; }

wh() {
    local msg="$1" color="${2:-$CRESET}" nonl="${3:-}"
    if [[ -n "$nonl" ]]; then printf "${color}%s${R}" "$msg"
    else printf "${color}%s${R}\n" "$msg"; fi
    log_append "$msg"
}

write_banner() {
    local w=62 line; printf -v line '%0.s=' $(seq 1 $w)
    local date_str; date_str=$(date '+%A %d %B %Y  -  %H:%M:%S')

    wh ""
    wh "  +${line}+" "$ACCENT"
    wh "  |$(printf '%-62s' "")|" "$ACCENT"
    printf "${TITLE}  |  %-60s|${R}\n" "$(get_s title)"
    printf "${HEAD}  |  %-60s|${R}\n" "$(get_s target): $SERVER_IP   $(get_s port): $TARGET_PORT"
    printf "${DIM}  |  %-60s|${R}\n"  "$date_str"
    wh "  |$(printf '%-62s' "")|" "$ACCENT"
    wh "  +${line}+" "$ACCENT"
    wh ""
}

write_section() {
    local title="$1" step="$2" step_label dashes
    step_label="$(get_s step) $step"
    printf -v dashes '%0.s-' $(seq 1 $((44 - ${#step_label})))
    wh ""
    printf "${ACCENT}  +--[ ${HEAD}%s${ACCENT} ]%s${R}\n" "$step_label" "$dashes"
    wh "  |  >> $title" "$TITLE"
    printf "${ACCENT}  +%s${R}\n" "$(printf '%0.s-' $(seq 1 50))"
}

write_status_line() {
    local label="$1" value="$2" status="$3" icon color
    case "$status" in
        ok)   icon="[OK]"; color="$COK"  ;;
        warn) icon="[!!]"; color="$CWARN" ;;
        err)  icon="[XX]"; color="$CERR"  ;;
        *)    icon="[..]"; color="$CRESET" ;;
    esac
    if [[ -n "$value" ]]; then printf "${color}     %s ${CRESET}%s ${DIM}-> ${color}%s${R}\n" "$icon" "$label" "$value"
    else printf "${color}     %s ${CRESET}%s${R}\n" "$icon" "$label"; fi
    log_append "     $icon $label -> $value"
}

write_latency_bar() {
    local ms=$1 max_ms=${2:-300} bar_w=${3:-28} fill empty color
    fill=$(( ms * bar_w / max_ms )); (( fill > bar_w )) && fill=$bar_w
    empty=$(( bar_w - fill ))
    if (( ms < 20 )); then color="$COK"; elif (( ms < 80 )); then color="$CWARN"; else color="$CERR"; fi

    printf "${DIM}          [${color}"
    printf '%0.s#' $(seq 1 $fill) 2>/dev/null || true
    printf "${DIM}"
    printf '%0.s.' $(seq 1 $empty) 2>/dev/null || true
    printf "${color}] %4dms${R}\n" "$ms"
}

# ================================================================
#  INTERACTIVE CONFIGURE
# ================================================================
invoke_configure() {
    load_config
    LANG_KEY="$CFG_LANG"
    local w=60 line; printf -v line '%0.s=' $(seq 1 $w)

    printf "\n${ACCENT}  +%s+${R}\n" "$line"
    printf "${TITLE}  |  %-58s|${R}\n" "$(get_s cfgTitle)"
    printf "${ACCENT}  +%s+${R}\n\n" "$line"
    printf "${HEAD}  $(get_s cfgCurrent):${R}\n"
    printf "${CRESET}    Language   : %s\n" "$CFG_LANG"
    printf "${CRESET}    IP         : %s\n" "$CFG_IP"
    printf "${CRESET}    Port       : %s\n" "$CFG_PORT"
    printf "${CRESET}    Ping count : %s\n${R}\n" "$CFG_PING"

    while true; do
        printf "${HEAD}  >> $(get_s cfgLangPrompt) [%s] : ${R}" "$CFG_LANG"
        read -r input; [[ -z "$input" ]] && input="$CFG_LANG"; input="${input,,}"
        if [[ "$input" =~ ^(en|fr)$ ]]; then CFG_LANG="$input"; LANG_KEY="$CFG_LANG"; break; fi
        printf "${CERR}     [XX] $(get_s cfgInvalidLang)${R}\n"
    done

    while true; do
        printf "${HEAD}  >> $(get_s cfgIpPrompt) [%s] : ${R}" "$CFG_IP"
        read -r input; [[ -z "$input" ]] && input="$CFG_IP"
        if is_valid_ip "$input"; then CFG_IP="$input"; break; fi
        printf "${CERR}     [XX] $(get_s cfgInvalidIp)${R}\n"
    done

    while true; do
        printf "${HEAD}  >> $(get_s cfgPortPrompt) [%s] : ${R}" "$CFG_PORT"
        read -r input; [[ -z "$input" ]] && input="$CFG_PORT"
        if is_valid_port "$input"; then CFG_PORT="$input"; break; fi
        printf "${CERR}     [XX] $(get_s cfgInvalidPort)${R}\n"
    done

    while true; do
        printf "${HEAD}  >> $(get_s cfgPingPrompt) [%s] : ${R}" "$CFG_PING"
        read -r input; [[ -z "$input" ]] && input="$CFG_PING"
        if is_valid_ping "$input"; then CFG_PING="$input"; break; fi
        printf "${CERR}     [XX] $(get_s cfgInvalidPing)${R}\n"
    done

    save_config
    printf "\n${COK}  [OK] $(get_s cfgSaved)${R}\n\n"
    exit 0
}

# ================================================================
#  HELP
# ================================================================
show_help() {
    load_config; LANG_KEY="$CFG_LANG"
    if [[ "$LANG_KEY" == "fr" ]]; then
        cat <<EOF
UTILISATION:  ./audit_linux.sh [options]
OPTIONS:
  --server-ip  <ip>     Forcer l'IP cible pour cette execution
  --port       <port>   Forcer le port cible pour cette execution
  --ping-count <n>      Forcer le nombre de pings
  --lang       <fr|en>  Forcer la langue pour cette execution
  --configure           Interface de configuration interactive
  --reset-config        Reinitialiser la configuration
  --no-log              Desactiver la generation de journal
  --help / -h           Afficher cette aide
EOF
    else
        cat <<EOF
USAGE:  ./audit_linux.sh [options]
OPTIONS:
  --server-ip  <ip>     Override target IP for this run
  --port       <port>   Override target port for this run
  --ping-count <n>      Override ping count for this run
  --lang       <en|fr>  Override language for this run
  --configure           Launch interactive configuration UI
  --reset-config        Reset config file to defaults
  --no-log              Disable log file generation
  --export-json         Export audit results as JSON
  --help / -h           Show this help
EOF
    fi
    exit 0
}

# ================================================================
#  PARSE ARGUMENTS
# ================================================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --server-ip)   CLI_IP="$2";   shift 2 ;;
        --port)        CLI_PORT="$2"; shift 2 ;;
        --ping-count)  CLI_PING="$2"; shift 2 ;;
        --lang)        CLI_LANG="$2"; shift 2 ;;
        --configure)   DO_CONFIGURE=1; shift ;;
        --reset-config) RESET_CONFIG=1; shift ;;
        --no-log)      NO_LOG=1; shift ;;
        --export-json) EXPORT_JSON=1; shift ;;
        --help|-h)     SHOW_HELP=1; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

[[ $SHOW_HELP -eq 1 ]] && show_help

load_config

if [[ $RESET_CONFIG -eq 1 ]]; then
    CFG_LANG="en"; CFG_IP="192.168.1.254"; CFG_PORT="51821"; CFG_PING="5"
    save_config
    printf "${COK}  [OK] Configuration reset to defaults.${R}\n"
    exit 0
fi

[[ $DO_CONFIGURE -eq 1 ]] && invoke_configure

# Apply overrides
[[ -n "$CLI_LANG" && "$CLI_LANG" =~ ^(en|fr)$ ]] && CFG_LANG="$CLI_LANG"
if [[ -n "$CLI_IP" ]]; then is_valid_ip "$CLI_IP" && CFG_IP="$CLI_IP" || { echo "Invalid IP: $CLI_IP" >&2; exit 1; }; fi
if [[ -n "$CLI_PORT" ]]; then is_valid_port "$CLI_PORT" && CFG_PORT="$CLI_PORT" || { echo "Invalid port: $CLI_PORT" >&2; exit 1; }; fi
if [[ -n "$CLI_PING" ]]; then is_valid_ping "$CLI_PING" && CFG_PING="$CLI_PING" || { echo "Invalid ping count: $CLI_PING" >&2; exit 1; }; fi

LANG_KEY="$CFG_LANG"
SERVER_IP="$CFG_IP"
TARGET_PORT="$CFG_PORT"
PING_COUNT="$CFG_PING"

if [[ $NO_LOG -eq 0 ]]; then
    mkdir -p "$LOG_DIR"
    LOG_FILE="${LOG_DIR}/audit_${SERVER_IP}_$(date '+%Y%m%d_%H%M%S').log"
fi

# ================================================================
#  REPORT DATA STRUCTURES
# ================================================================
declare -A REPORT_VALS
declare -a REPORT_KEYS_ORDER=()
REMEDIATION=()

report_set() {
    local key="$1" val="$2"
    if [[ -z "${REPORT_VALS[$key]+x}" ]]; then REPORT_KEYS_ORDER+=("$key"); fi
    REPORT_VALS["$key"]="$val"
}

# ================================================================
#  INIT
# ================================================================
write_banner

if [[ $EUID -eq 0 ]]; then wh "  [OK] $(get_s adminOk)" "$COK"; IS_ROOT=1
else wh "  [!!] $(get_s adminWarn)" "$CWARN"; IS_ROOT=0; fi

# ================================================================
#  [1] ARP RESOLUTION & ROUTING
# ================================================================
write_section "$(get_s arpSection)" 1

IFACE=$(ip route get "$SERVER_IP" 2>/dev/null | grep -Po '(?<=dev )(\S+)' || true)
if [[ -n "$IFACE" ]]; then
    write_status_line "$(get_s routeOk)" "Interface: $IFACE" "ok"
    report_set "Routing" "IF: $IFACE"
else
    write_status_line "$(get_s routeFail)" "" "err"
    report_set "Routing" "FAILED"
fi

if [[ $IS_ROOT -eq 1 ]]; then
    ip neigh flush to "$SERVER_IP" 2>/dev/null || true
    wh "       $(get_s arpFlushed) $SERVER_IP" "$DIM"
else
    wh "       $(get_s arpSkip)" "$DIM"
fi

ping -c 1 -W 1 "$SERVER_IP" &>/dev/null || true
ARP_MAC=$(ip neigh show "$SERVER_IP" | awk '{print $5}' || true)

if [[ -n "$ARP_MAC" && "$ARP_MAC" != "" ]]; then
    write_status_line "$(get_s arpOk)" "$ARP_MAC" "ok"
    report_set "ARP" "Resolved"
else
    write_status_line "$(get_s arpFail)" "$(get_s arpSleep)" "err"
    report_set "ARP" "FAILED"
    [[ -n "$IFACE" ]] && REMEDIATION+=("ip link set $IFACE arp on")
fi

# ================================================================
#  [2] LATENCY PROFILE
# ================================================================
write_section "$(get_s latSection)  ($PING_COUNT $(get_s pings))" 2

latencies=()
timeout_count=0

# Gather ping timings
for (( i=1; i<=PING_COUNT; i++ )); do
    lat=$(ping -c 1 -W 1 "$SERVER_IP" 2>/dev/null | grep -oP 'time=\K[0-9.]+' | head -1 || true)
    if [[ -n "$lat" ]]; then
        # Handle fractional ms with awk
        lat_int=$(echo "$lat" | awk '{printf "%d", $1 + 0.5}')
        tag=""
        [[ $i -eq 1 ]] && tag="  <- $(get_s firstPkt)"
        printf "${DIM}     Ping [%d/%d]%s${R}\n" "$i" "$PING_COUNT" "$tag"
        write_latency_bar "$lat_int"
        latencies+=("$lat_int")
    else
        printf "${DIM}     Ping [%d/%d] ${CERR}$(get_s timeout)${R}\n" "$i" "$PING_COUNT"
        (( timeout_count++ )) || true
    fi
done

wh ""

if (( ${#latencies[@]} >= 1 )); then
    first_pkt="${latencies[0]}"
    min_lat="${latencies[0]}"
    max_lat="${latencies[0]}"
    for v in "${latencies[@]}"; do
        (( v < min_lat )) && min_lat=$v
        (( v > max_lat )) && max_lat=$v
    done

    jitter=0
    if (( ${#latencies[@]} >= 2 )); then
        sum=0
        jitter_sum=0
        for (( j=1; j<${#latencies[@]}; j++ )); do
            (( sum += latencies[j] )) || true
            if (( j > 1 )); then
                diff=$(( latencies[j] - latencies[j-1] ))
                (( diff < 0 )) && diff=$(( -diff ))
                (( jitter_sum += diff )) || true
            fi
        done
        rest_avg=$(( sum / (${#latencies[@]} - 1) ))
        spike=$(( first_pkt - rest_avg ))
        if (( ${#latencies[@]} > 2 )); then
            jitter=$(( jitter_sum / (${#latencies[@]} - 2) ))
        fi
    else
        rest_avg=$first_pkt
        spike=0
    fi

    loss_pct=$(( (timeout_count * 100) / PING_COUNT ))

    spike_color="$COK"; (( spike > 50 )) && spike_color="$CWARN"

    printf "${ACCENT}     +------------------------------------+${R}\n"
    printf "${CRESET}     |  %-16s: %6dms           |${R}\n" "$(get_s firstPkt)" "$first_pkt"
    printf "${CRESET}     |  %-16s: %6dms           |${R}\n" "$(get_s avgRest)"  "$rest_avg"
    printf "${CRESET}     |  %-16s: %4dms / %4dms    |${R}\n" "$(get_s minMax)"  "$min_lat" "$max_lat"
    printf "${spike_color}     |  %-16s: %6dms           |${R}\n" "$(get_s spikeDelta)" "$spike"
    printf "${CRESET}     |  %-16s: %5d%% / %4dms    |${R}\n" "$(get_s lossAndJitter)" "$loss_pct" "$jitter"
    printf "${ACCENT}     +------------------------------------+${R}\n\n"

    if (( spike > 50 )); then
        write_status_line "$(get_s spikeOf) ${spike}ms" "$(get_s spikeWarn)" "warn"
        report_set "Latency" "Spike: ${spike}ms"
        [[ -n "$IFACE" ]] && REMEDIATION+=("ethtool -s $IFACE wol d")
    else
        write_status_line "$(get_s latStable)" "spike ${spike}ms" "ok"
        report_set "Latency" "Stable"
    fi

    if (( loss_pct > 0 )); then
        report_set "Packet Loss" "${loss_pct}%"
    fi
else
    write_status_line "$(get_s latFail)" "$timeout_count timeouts" "err"
    report_set "Latency" "FAILED ($timeout_count timeouts)"
fi

# ================================================================
#  [3] TCP & HTTP
# ================================================================
write_section "$(get_s tcpSection) $TARGET_PORT" 3

if timeout 2 bash -c "echo >/dev/tcp/${SERVER_IP}/${TARGET_PORT}" 2>/dev/null; then
    write_status_line "$(get_s port) $TARGET_PORT" "$(get_s portOpen)" "ok"
    report_set "Port $TARGET_PORT" "Open"
else
    write_status_line "$(get_s port) $TARGET_PORT" "$(get_s portClosed)" "err"
    report_set "Port $TARGET_PORT" "Closed"
    REMEDIATION+=("ufw allow out $TARGET_PORT/tcp" "iptables -A OUTPUT -p tcp --dport $TARGET_PORT -j ACCEPT")
fi

write_section "$(get_s httpSection)" 4
if command -v curl &>/dev/null; then
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://${SERVER_IP}:${TARGET_PORT}" 2>/dev/null || echo "000")
    if [[ "$http_code" != "000" && "$http_code" != "" ]]; then
        write_status_line "$(get_s httpOk)" "HTTP $http_code" "ok"
        report_set "HTTP" "OK ($http_code)"
    else
        write_status_line "$(get_s httpFail)" "connection refused or timeout" "err"
        report_set "HTTP" "FAILED"
    fi
else
    write_status_line "$(get_s notSupported)" "curl not installed" "warn"
fi

# ================================================================
#  [4] TRACEROUTE (first 5 hops)
# ================================================================
write_section "$(get_s traceSection)" 5

if command -v traceroute &>/dev/null; then
    wh "       (running...)" "$DIM"
    trace_out=$(traceroute -m 5 -w 2 "$SERVER_IP" 2>/dev/null | tail -n +2 | head -5 || true)
    if [[ -n "$trace_out" ]]; then
        while IFS= read -r line; do
            wh "     $line" "$DIM"
        done <<< "$trace_out"
        report_set "Traceroute" "Completed"
    else
        wh "     (no hops captured)" "$DIM"
        report_set "Traceroute" "No hops"
    fi
else
    write_status_line "$(get_s notSupported)" "$(get_s traceNoCmd)" "warn"
    report_set "Traceroute" "N/A"
fi

# ================================================================
#  [5] DNS RESOLUTION
# ================================================================
write_section "$(get_s dnsSection)" 6

if host "$SERVER_IP" &>/dev/null 2>&1; then
    dns_result=$(host "$SERVER_IP" 2>/dev/null | head -1 || true)
    write_status_line "$(get_s dnsOk)" "$dns_result" "ok"
    report_set "DNS" "Resolved"
else
    write_status_line "$(get_s dnsFail)" "no PTR record / host unreachable" "warn"
    report_set "DNS" "No PTR"
fi

# ================================================================
#  [6] NIC POWER MANAGEMENT
# ================================================================
write_section "$(get_s nicSection)" 7

if ! command -v ethtool &>/dev/null; then
    write_status_line "$(get_s notSupported)" "$(get_s nicNoCmd)" "warn"
else
    if [[ -z "$IFACE" ]]; then
        write_status_line "$(get_s nicNone)" "" "err"
    else
        wol_info=$(ethtool "$IFACE" 2>/dev/null | grep "Wake-on:" | awk '{print $2}' || true)
        if [[ "$wol_info" == *"g"* || "$wol_info" == *"p"* ]]; then
            write_status_line "$IFACE WoL" "Active ($wol_info)" "warn"
            report_set "NIC: $IFACE" "WoL Active"
            REMEDIATION+=("ethtool -s $IFACE wol d")
        else
            write_status_line "$IFACE WoL" "Disabled" "ok"
            report_set "NIC: $IFACE" "Optimized"
        fi
    fi
fi

# ================================================================
#  [7] OS POWER TARGETS & CPU GOVERNOR
# ================================================================
write_section "$(get_s osSleep)" 8

SLP=$(systemctl status sleep.target suspend.target 2>/dev/null | grep -c "loaded" || true)
if (( SLP > 0 )); then
    write_status_line "Systemd Sleep Targets" "Active" "warn"
    report_set "OS Sleep" "Active"
    REMEDIATION+=("systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target")
else
    write_status_line "Systemd Sleep Targets" "Masked" "ok"
    report_set "OS Sleep" "Disabled"
fi

if [[ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]]; then
    gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    if [[ "$gov" == "performance" ]]; then
        write_status_line "CPU Governor" "Performance" "ok"
        report_set "OS Power" "High Perf"
    else
        write_status_line "CPU Governor" "$gov" "warn"
        report_set "OS Power" "Not Optimal"
        REMEDIATION+=("echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor")
    fi
fi

# ================================================================
#  SUMMARY
# ================================================================
w=58; line_sum=$(printf '%0.s=' $(seq 1 $w))
printf "\n${ACCENT}  +%s+${R}\n" "$line_sum"
printf "${TITLE}  |  %-56s|${R}\n" "$(get_s summaryTitle)"
printf "${ACCENT}  +%s+${R}\n" "$line_sum"

failed_count=0
for key in "${REPORT_KEYS_ORDER[@]}"; do
    val="${REPORT_VALS[$key]}"
    local_color="$CWARN"; icon="[!!]"
    if [[ "$val" =~ FAILED|Closed|Spike|FERME|ECHOUE ]]; then
        local_color="$CERR"; icon="[XX]"; (( failed_count++ )) || true
    elif [[ "$val" =~ Stable|Open|Resolved|OK|Optimized|High|Resolu|Ouvert ]]; then
        local_color="$COK"; icon="[OK]"
    fi
    # Use spaces instead of zero-length formatting logic
    printf "${local_color}  |  %s  %-20s %30s  |${R}\n" "$icon" "$key" "$val"
done
printf "${ACCENT}  +%s+${R}\n" "$line_sum"

# ================================================================
#  REMEDIATION PLAYBOOK
# ================================================================
if (( ${#REMEDIATION[@]} > 0 )); then
    printf "\n${CERR}  +%s+${R}\n" "$line_sum"
    printf "${TITLE}  |  %-56s|${R}\n" "$(get_s remTitle)"
    printf "${CERR}  +%s+${R}\n" "$line_sum"

    unique_remediations=$(printf "%s\n" "${REMEDIATION[@]}" | sort -u)

    echo "$unique_remediations" | while read -r cmd; do
        printf "${CWARN}  > %s${R}\n" "$cmd"
    done
    printf "${CERR}  +%s+${R}\n" "$line_sum"

    if [[ $IS_ROOT -eq 1 ]]; then
        if [ -t 0 ]; then
            printf "\n${CWARN}  [?] $(get_s runRemediation) ${R}"
            read -r apply_fixes
            if [[ "${apply_fixes,,}" == "y" || "${apply_fixes,,}" == "yes" ]]; then
                wh ""
                echo "$unique_remediations" | while read -r cmd; do
                    wh "      Executing: $cmd" "$DIM"
                    eval "$cmd" 2>/dev/null || wh "      -> Failed." "$CERR"
                done
                wh "  [OK] $(get_s remApplied)" "$COK"
            fi
        else
            wh "\n  [i] Non-interactive environment detected. Skipping auto-remediation prompt." "$DIM"
        fi
    fi
else
    printf "\n${COK}  [OK] $(get_s remNone)${R}\n"
fi

wh "\n  $(get_s completed) $(date '+%H:%M:%S')" "$DIM"

if [[ $EXPORT_JSON -eq 1 ]]; then
    mkdir -p "${LOG_DIR:-$SCRIPT_DIR}"
    json_path="${LOG_DIR:-$SCRIPT_DIR}/audit_${SERVER_IP}_$(date '+%Y%m%d_%H%M%S').json"
    if command -v python3 &>/dev/null; then
        # Build JSON using Python to ensure escaping
        json_str="{"
        first=1
        for key in "${REPORT_KEYS_ORDER[@]}"; do
            val="${REPORT_VALS[$key]}"
            if [[ $first -eq 1 ]]; then first=0; else json_str+=","; fi
            # Primitive escaping
            key_esc="${key//\"/\\\"}"
            val_esc="${val//\"/\\\"}"
            json_str+="\"$key_esc\":\"$val_esc\""
        done
        json_str+="}"
        echo "$json_str" > "$json_path"
        python3 -m json.tool "$json_path" > "${json_path}.tmp" && mv "${json_path}.tmp" "$json_path" || true
        wh "  [OK] $(get_s jsonExported) $json_path" "$DIM"
    else
        wh "  [XX] Python3 required for JSON export." "$CWARN"
    fi
fi

if [[ -n "${LOG_FILE:-}" ]]; then
    echo "$LOG_BUFFER" > "$LOG_FILE" 2>/dev/null || true
    printf "${DIM}  $(get_s logSaved) %s${R}\n\n" "$LOG_FILE"
fi