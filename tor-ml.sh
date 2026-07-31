#!/usr/bin/env bash

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
M='\033[1;35m'
C='\033[1;36m'
W='\033[1;37m'
D='\033[2m'
N='\033[0m'
OR='\033[1;38;5;208m'

BASE="/opt/tor-ml"
CFG="$BASE/config"
DAT="$BASE/data"
LOG="$BASE/logs"
STA="$BASE/status"
CMD="/usr/local/bin/tor"

declare -A LOC=(
  [01]="DE:Germany:48180" [02]="TR:Turkey:48181"
  [03]="US:United States:48182" [04]="FR:France:48183"
  [05]="AT:Austria:48184" [06]="BE:Belgium:48185"
  [07]="RO:Romania:48186" [08]="CA:Canada:48187"
  [09]="SG:Singapore:48188" [10]="JP:Japan:48189"
  [11]="IE:Ireland:48190" [12]="FI:Finland:48191"
  [13]="ES:Spain:48192" [14]="PL:Poland:48193"
  [15]="NL:Netherlands:48194" [16]="IT:Italy:48195"
  [17]="CH:Switzerland:48196" [18]="SE:Sweden:48197"
  [19]="NO:Norway:48198" [20]="DK:Denmark:48199"
  [21]="IS:Iceland:48200" [22]="AU:Australia:48201"
  [23]="IN:India:48202" [24]="HK:Hong Kong:48203"
  [25]="UA:Ukraine:48204" [26]="CZ:Czech Republic:48205"
  [27]="KR:South Korea:48206" [28]="ZA:South Africa:48207"
  [29]="MX:Mexico:48208" [30]="MY:Malaysia:48209"
  [31]="AZ:Azerbaijan:48210" [32]="CY:Cyprus:48211"
  [33]="GR:Greece:48212" [34]="PT:Portugal:48213"
  [35]="HU:Hungary:48214" [36]="LU:Luxembourg:48215"
  [37]="GB:United Kingdom:48216" [38]="AR:Argentina:48217"
  [39]="TW:Taiwan:48218" [40]="BG:Bulgaria:48219"
  [41]="IL:Israel:48220" [42]="MD:Moldova:48221"
  [43]="RU:Russia:48222" [44]="CL:Chile:48223"
  [45]="CR:Costa Rica:48224" [46]="VN:Vietnam:48225"
  [47]="ID:Indonesia:48226" [48]="SC:Seychelles:48227"
  [49]="HR:Croatia:48228" [50]="TN:Tunisia:48229"
)

declare -A FLAG=(
  [DE]="🇩🇪" [TR]="🇹🇷" [US]="🇺🇸" [FR]="🇫🇷" [AT]="🇦🇹" [BE]="🇧🇪"
  [RO]="🇷🇴" [CA]="🇨🇦" [SG]="🇸🇬" [JP]="🇯🇵" [IE]="🇮🇪" [FI]="🇫🇮"
  [ES]="🇪🇸" [PL]="🇵🇱" [NL]="🇳🇱" [IT]="🇮🇹" [CH]="🇨🇭" [SE]="🇸🇪"
  [NO]="🇳🇴" [DK]="🇩🇰" [IS]="🇮🇸" [AU]="🇦🇺" [IN]="🇮🇳" [HK]="🇭🇰"
  [UA]="🇺🇦" [CZ]="🇨🇿" [KR]="🇰🇷" [ZA]="🇿🇦" [MX]="🇲🇽" [MY]="🇲🇾"
  [AZ]="🇦🇿" [CY]="🇨🇾" [GR]="🇬🇷" [PT]="🇵🇹" [HU]="🇭🇺" [LU]="🇱🇺"
  [GB]="🇬🇧" [AR]="🇦🇷" [TW]="🇹🇼" [BG]="🇧🇬" [IL]="🇮🇱" [MD]="🇲🇩"
  [RU]="🇷🇺" [CL]="🇨🇱" [CR]="🇨🇷" [VN]="🇻🇳" [ID]="🇮🇩" [SC]="🇸🇨"
  [HR]="🇭🇷" [TN]="🇹🇳"
)

ORDER=({01..50})

need_root() {
  [[ $EUID -eq 0 ]] || { echo -e "${R}[!] Run as root${N}"; exit 1; }
}

parse() {
  local id
  id=$(printf "%02d" "$((10#${1}))" 2>/dev/null || echo "")
  [[ -n ${LOC[$id]+x} ]] && echo "$id"
}

info() {
  local code name port
  IFS=':' read -r code name port <<< "${LOC[$1]}"
  if [[ -f "$CFG/ports.db" ]]; then
    local custom
    custom=$(grep "^$1:" "$CFG/ports.db" 2>/dev/null | tail -1 || true)
    if [[ -n "$custom" ]]; then
      IFS=':' read -r _ _ _ port <<< "$custom"
    fi
  fi
  echo "$code|$name|$port"
}

running() {
  local code=$1 port=$2
  pgrep -f "tor -f $CFG/node_${code}_${port}.conf" >/dev/null 2>&1
}

list_running() {
  local out=()
  for id in "${ORDER[@]}"; do
    local code name port
    IFS='|' read -r code name port <<< "$(info "$id")"
    if running "$code" "$port"; then
      out+=("$id")
    fi
  done
  echo "${out[*]}"
}

get_stats() {
  local cpu=0 mem=0 cnt=0
  local pids
  pids=$(pgrep -f "tor -f $CFG/node_" 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    while read -r c m; do
      [[ -z "$c" ]] && continue
      cpu=$(awk -v a="$cpu" -v b="$c" 'BEGIN{printf "%.1f", a+b}')
      mem=$(awk -v a="$mem" -v b="$m" 'BEGIN{printf "%.1f", a+b}')
      cnt=$((cnt + 1))
    done < <(ps -p $(echo "$pids" | tr '\n' ',') -o %cpu=,%mem= --no-headers 2>/dev/null || true)
  fi
  printf "%.1f %.1f %d" "${cpu:-0}" "${mem:-0}" "$cnt"
}

line() {
  echo -e "${D}--------------------------------------------------------------${N}"
}

header() {
  clear
  local cpu mem cnt
  read -r cpu mem cnt <<< "$(get_stats)"
  echo
  echo -e "  ${C}${W}tor ML${N}  ${D}v1.0${N}"
  echo -e "  ${D}Lightweight Multi-Exit Tor Manager${N}"
  line
  echo -e "  Status   ${G}${cnt}${N} running   ${D}|${N}  CPU ${OR}${cpu}%${N}   ${D}|${N}  MEM ${OR}${mem}%${N}"
  echo -e "  Config   ${W}$CFG${N}"
  echo -e "  Logs     ${W}$LOG${N}"
  echo -e "  Data     ${W}$DAT${N}"
  line
  echo -e "  ${D}Made by${N} ${M}icubaby${N}  ${D}|${N}  ${C}t.me/icubaby${N}"
  line
  echo
}

start_one() {
  local id=$1
  local code name port
  IFS='|' read -r code name port <<< "$(info "$id")"

  local conf="$CFG/node_${code}_${port}.conf"
  local dir="$DAT/${code}_${port}"
  local logfile="$LOG/${code}_${port}.log"

  mkdir -p "$dir" "$LOG"
  chown -R debian-tor:debian-tor "$dir" 2>/dev/null || true
  chmod 700 "$dir" 2>/dev/null || true

  cat > "$conf" <<EOF
SocksPort 127.0.0.1:$port
DataDirectory $dir
ExitNodes {$code}
StrictNodes 1
RunAsDaemon 1
Log notice file $logfile
EOF
  chown debian-tor:debian-tor "$conf" 2>/dev/null || true
  chmod 600 "$conf" 2>/dev/null || true

  if running "$code" "$port"; then
    echo -e "  ${Y}•${N} ${FLAG[$code]} $name ${Y}already running${N}  port $port"
    return 0
  fi

  pkill -f "node_${code}_${port}.conf" 2>/dev/null || true
  sleep 0.3
  : > "$logfile"
  chown debian-tor:debian-tor "$logfile" 2>/dev/null || true

  if ! sudo -u debian-tor /usr/bin/tor -f "$conf" >/dev/null 2>&1; then
    echo -e "  ${R}✗${N} ${FLAG[$code]} $name ${R}failed to launch${N}"
    [[ -s "$logfile" ]] && { echo -e "  ${Y}Log:${N}"; tail -n 10 "$logfile" | sed 's/^/    /'; }
    return 1
  fi

  local i=0
  while ! running "$code" "$port" && (( i < 15 )); do
    sleep 0.4
    i=$((i + 1))
  done

  if running "$code" "$port"; then
    echo -e "  ${G}✓${N} ${FLAG[$code]} $name ${G}started${N}  →  ${W}$port${N}"
    return 0
  fi

  echo -e "  ${R}✗${N} ${FLAG[$code]} $name ${R}failed${N}"
  if [[ -s "$logfile" ]]; then
    echo -e "  ${Y}Log:${N}"
    tail -n 10 "$logfile" | sed 's/^/    /'
  fi
  return 1
}

stop_one() {
  local id=$1
  local code name port
  IFS='|' read -r code name port <<< "$(info "$id")"

  if ! running "$code" "$port"; then
    echo -e "  ${Y}•${N} ${FLAG[$code]} $name ${Y}not running${N}"
    return 0
  fi

  pkill -f "node_${code}_${port}.conf" 2>/dev/null || true
  sleep 0.3
  if running "$code" "$port"; then
    pkill -9 -f "node_${code}_${port}.conf" 2>/dev/null || true
    sleep 0.2
  fi
  echo -e "  ${G}✓${N} ${FLAG[$code]} $name ${G}stopped${N}"
}

show_running_table() {
  local ids
  ids=$(list_running)
  if [[ -z "$ids" ]]; then
    echo -e "  ${Y}No running locations.${N}"
    return 1
  fi
  echo -e "  ${C}ID   CC   Location                 Port${N}"
  line
  for id in $ids; do
    local code name port
    IFS='|' read -r code name port <<< "$(info "$id")"
    printf "  ${G}%-4s${N} %-4s %-24s ${W}%s${N}\n" "$id" "$code" "$name" "$port"
  done
  line
  return 0
}

full_status() {
  header
  echo -e "  ${C}ID   CC   Location                 Port      Status${N}"
  line
  for id in "${ORDER[@]}"; do
    local code name port
    IFS='|' read -r code name port <<< "$(info "$id")"
    if running "$code" "$port"; then
      printf "  ${G}%-4s${N} %-4s %-24s %-8s ${G}ONLINE${N}\n" "$id" "$code" "$name" "$port"
    else
      printf "  ${D}%-4s %-4s %-24s %-8s${N} ${R}OFFLINE${N}\n" "$id" "$code" "$name" "$port"
    fi
  done
  line
  echo
  read -rp "  Press Enter..."
}

do_start() {
  header
  echo -e "  ${C}Start Location(s)${N}"
  echo -e "  ${D}Format: 1   or  1.4.12   or  1 4 12${N}"
  echo
  for i in {1..25}; do
    local a b na nb
    a=$(printf "%02d" "$i")
    b=$(printf "%02d" "$((i + 25))")
    IFS='|' read -r _ na _ <<< "$(info "$a")"
    IFS='|' read -r _ nb _ <<< "$(info "$b")"
    printf "  ${C}[%s]${N} %-18s  ${C}[%s]${N} %-18s\n" "$a" "$na" "$b" "$nb"
  done
  echo
  read -rp "$(echo -e "  ${M}IDs: ${N}")" raw
  [[ -z "$raw" ]] && return
  raw=${raw//./ }
  raw=${raw//,/ }
  echo
  for x in $raw; do
    local id
    id=$(parse "$x") || { echo -e "  ${R}Invalid: $x${N}"; continue; }
    start_one "$id"
  done
  echo
  read -rp "  Press Enter..."
}

do_stop() {
  header
  echo -e "  ${C}Stop Location(s)${N}"
  echo
  if ! show_running_table; then
    echo
    read -rp "  Press Enter..."
    return
  fi
  echo -e "  ${D}Format: 3   or  3.7.15${N}"
  echo
  read -rp "$(echo -e "  ${M}IDs: ${N}")" raw
  [[ -z "$raw" ]] && return
  raw=${raw//./ }
  raw=${raw//,/ }
  echo
  for x in $raw; do
    local id
    id=$(parse "$x") || continue
    stop_one "$id"
  done
  echo
  read -rp "  Press Enter..."
}

start_all() {
  header
  echo -e "  ${Y}Starting all locations...${N}"
  echo
  for id in "${ORDER[@]}"; do
    start_one "$id" || true
    sleep 0.2
  done
  echo
  echo -e "  ${G}Done.${N}"
  read -rp "  Press Enter..."
}

stop_all() {
  header
  echo -e "  ${Y}Stopping all...${N}"
  echo
  for id in "${ORDER[@]}"; do
    stop_one "$id" || true
  done
  echo
  echo -e "  ${G}All stopped.${N}"
  read -rp "  Press Enter..."
}

change_port() {
  header
  echo -e "  ${C}Change Location Port${N}"
  echo
  echo -e "  ${C}ID   CC   Location                 Port      Status${N}"
  line
  for id in "${ORDER[@]}"; do
    local code name port
    IFS='|' read -r code name port <<< "$(info "$id")"
    if running "$code" "$port"; then
      printf "  ${G}%-4s${N} %-4s %-24s %-8s ${G}ONLINE${N}\n" "$id" "$code" "$name" "$port"
    else
      printf "  ${D}%-4s %-4s %-24s %-8s${N} ${R}OFF${N}\n" "$id" "$code" "$name" "$port"
    fi
  done
  line
  echo
  read -rp "$(echo -e "  ${M}Location ID: ${N}")" raw
  local id
  id=$(parse "$raw") || { echo -e "  ${R}Invalid ID${N}"; sleep 1; return; }
  local code name port
  IFS='|' read -r code name port <<< "$(info "$id")"
  echo
  echo -e "  Current: ${FLAG[$code]} $name  →  ${W}$port${N}"
  read -rp "  New port (40000-60000): " new
  if ! [[ "$new" =~ ^[0-9]+$ ]] || (( new < 40000 || new > 60000 )); then
    echo -e "  ${R}Invalid port${N}"
    sleep 1
    return
  fi
  stop_one "$id"
  mkdir -p "$CFG"
  echo "$id:$code:$name:$new" >> "$CFG/ports.db"
  echo -e "  ${G}Port updated to $new${N}  ${D}(applies on next start)${N}"
  sleep 1.5
}

speed_test() {
  header
  echo -e "  ${C}Speed / Latency Test${N}"
  echo
  if ! show_running_table; then
    echo
    read -rp "  Press Enter..."
    return
  fi
  echo -e "  ${D}Testing via Cloudflare (5MB download + latency)...${N}"
  echo
  local ids
  ids=$(list_running)
  for id in $ids; do
    local code name port
    IFS='|' read -r code name port <<< "$(info "$id")"
    printf "  ${FLAG[$code]} %-18s " "$name"

    local lat
    lat=$(curl --socks5-hostname "127.0.0.1:$port" -o /dev/null -s -w "%{time_total}" \
      --max-time 20 "https://www.cloudflare.com/cdn-cgi/trace" 2>/dev/null || echo "fail")

    if [[ "$lat" == "fail" ]]; then
      echo -e "${R}unreachable${N}"
      continue
    fi

    local speed_raw
    speed_raw=$(curl --socks5-hostname "127.0.0.1:$port" -o /dev/null -s -w "%{speed_download}" \
      --max-time 30 "https://speed.cloudflare.com/__down?bytes=5000000" 2>/dev/null || echo "0")

    local speed_kb
    speed_kb=$(awk -v s="$speed_raw" 'BEGIN{printf "%.1f", s/1024}')

    local ip
    ip=$(curl --socks5-hostname "127.0.0.1:$port" -s --max-time 10 https://api.ipify.org 2>/dev/null || echo "?")

    echo -e "lat ${Y}${lat}s${N}  speed ${G}${speed_kb} KB/s${N}  ip ${W}${ip}${N}"
  done
  echo
  line
  echo -e "  ${D}Note: Tor is optimized for anonymity, not speed.${N}"
  echo
  read -rp "  Press Enter..."
}

uninstall() {
  header
  echo -e "  ${R}WARNING: Complete removal of tor ML${N}"
  echo
  echo -e "  • All running nodes will be killed"
  echo -e "  • $BASE will be deleted"
  echo -e "  • Command 'tor' will be removed"
  echo
  echo -ne "  Type "
  echo -ne "${R}YES${N}"
  echo -n " to confirm: "
  read -r conf
  if [[ "$conf" != "YES" ]]; then
    echo -e "  ${Y}Cancelled.${N}"
    sleep 1
    return
  fi
  pkill -f "node_.*_48" 2>/dev/null || true
  sleep 1
  rm -rf "$BASE"
  rm -f "$CMD"
  echo
  echo -e "  ${G}tor ML completely removed.${N}"
  exit 0
}

install() {
  need_root
  header
  echo -e "  ${C}Installing tor ML v1.0 ...${N}"
  echo

  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y tor tor-geoipdb curl bc >/dev/null

  if ! id debian-tor &>/dev/null; then
    useradd --system --home-dir /var/lib/tor --shell /usr/sbin/nologin debian-tor 2>/dev/null || true
  fi

  systemctl stop tor 2>/dev/null || true
  systemctl disable tor 2>/dev/null || true

  mkdir -p "$CFG" "$DAT" "$LOG" "$STA"
  chown -R debian-tor:debian-tor "$DAT" "$LOG" 2>/dev/null || true

  cp "$0" "$CMD"
  chmod +x "$CMD"

  echo -e "  ${G}Installation complete!${N}"
  echo -e "  Run:  ${W}tor${N}"
  echo
  sleep 2
}

main() {
  while true; do
    header
    echo -e "  ${C}[1]${N}  Full Status"
    echo -e "  ${C}[2]${N}  Start Location"
    echo -e "  ${C}[3]${N}  Stop Location"
    echo -e "  ${C}[4]${N}  Start All"
    echo -e "  ${C}[5]${N}  Stop All"
    echo -e "  ${C}[6]${N}  Change Port"
    echo -e "  ${C}[7]${N}  Speed Test"
    echo -e "  ${R}[8]${N}  Uninstall"
    echo -e "  ${Y}[0]${N}  Exit"
    echo
    read -rp "$(echo -e "  ${M}Select: ${N}")" choice
    case $choice in
      1) full_status ;;
      2) do_start ;;
      3) do_stop ;;
      4) start_all ;;
      5) stop_all ;;
      6) change_port ;;
      7) speed_test ;;
      8) uninstall ;;
      0) clear; exit 0 ;;
    esac
  done
}

if [[ "${1:-}" == "--install" ]]; then
  install
  exit 0
fi

if [[ ! -d "$BASE" ]]; then
  echo -e "${Y}tor ML is not installed.${N}"
  echo -e "Run: ${W}sudo bash $0 --install${N}"
  exit 1
fi

main
