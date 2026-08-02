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
SETTINGS="$CFG/settings.db"

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

ORDER=({01..50})

need_root() {
  [[ $EUID -eq 0 ]] || { echo -e "${R}[!] Run as root${N}"; exit 1; }
}

parse() {
  local id
  id=$(printf "%02d" "$((10#${1}))" 2>/dev/null || echo "")
  [[ -n ${LOC[$id]+x} ]] && echo "$id"
}

init_settings() {
  mkdir -p "$CFG" "$DAT" "$LOG" "$STA"
  touch "$SETTINGS"
}

get_setting() {
  local id=$1 field=$2
  local line
  line=$(grep "^$id:" "$SETTINGS" 2>/dev/null | head -1)
  if [[ -n "$line" ]]; then
    IFS=':' read -r _ port bw uptime <<< "$line"
    case "$field" in
      port) echo "${port:-0}" ;;
      bandwidth) echo "${bw:-0}" ;;
      uptime) echo "${uptime:-0}" ;;
    esac
  else
    echo "0"
  fi
}

set_setting() {
  local id=$1 field=$2 value=$3
  local line
  line=$(grep "^$id:" "$SETTINGS" 2>/dev/null | head -1)
  if [[ -n "$line" ]]; then
    IFS=':' read -r _ port bw uptime <<< "$line"
    case "$field" in
      port) port="$value" ;;
      bandwidth) bw="$value" ;;
      uptime) uptime="$value" ;;
    esac
    sed -i "/^$id:/d" "$SETTINGS"
    echo "$id:$port:$bw:$uptime" >> "$SETTINGS"
  else
    local default_port
    IFS=':' read -r _ _ default_port <<< "${LOC[$id]}"
    echo "$id:$default_port:0:0" >> "$SETTINGS"
    set_setting "$id" "$field" "$value"
  fi
}

migrate_settings() {
  if [[ ! -f "$SETTINGS" ]]; then
    if [[ -f "$CFG/ports.db" ]] || [[ -f "$CFG/bandwidth.db" ]]; then
      for id in "${ORDER[@]}"; do
        local port=$(grep "^$id:" "$CFG/ports.db" 2>/dev/null | tail -1 | cut -d':' -f4 || echo "")
        local bw=$(grep "^$id:" "$CFG/bandwidth.db" 2>/dev/null | tail -1 | cut -d':' -f2 || echo "0")
        if [[ -z "$port" ]]; then
          IFS=':' read -r _ _ port <<< "${LOC[$id]}"
        fi
        echo "$id:$port:$bw:0" >> "$SETTINGS"
      done
      rm -f "$CFG/ports.db" "$CFG/bandwidth.db" 2>/dev/null
    else
      for id in "${ORDER[@]}"; do
        IFS=':' read -r _ _ port <<< "${LOC[$id]}"
        echo "$id:$port:0:0" >> "$SETTINGS"
      done
    fi
  fi
}

info() {
  local code name port
  IFS=':' read -r code name port <<< "${LOC[$1]}"
  local custom_port
  custom_port=$(get_setting "$1" "port")
  if [[ "$custom_port" != "0" ]]; then
    port="$custom_port"
  else
    set_setting "$1" "port" "$port"
  fi
  echo "$code|$name|$port"
}

running() {
  local code=$1 port=$2
  pgrep -f "tor -f $CFG/node_${code}_${port}.conf" >/dev/null 2>&1 || ss -lntp 2>/dev/null | grep -q ":$port "
}

get_pid() {
  local code=$1 port=$2
  pgrep -f "node_${code}_${port}.conf" 2>/dev/null | head -1
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

# === FIXED STATS FUNCTIONS ===
get_stats() {
  local cpu=0 mem=0 cnt=0

  while read -r pid; do
    [[ -z "$pid" ]] && continue

    read -r c m <<< "$(ps -p "$pid" -o %cpu=,%mem= --no-headers 2>/dev/null)"
    [[ -z "$c" ]] && c=0
    [[ -z "$m" ]] && m=0

    cpu=$(awk -v a="$cpu" -v b="$c" 'BEGIN {printf "%.1f", a+b}')
    mem=$(awk -v a="$mem" -v b="$m" 'BEGIN {printf "%.1f", a+b}')
    cnt=$((cnt + 1))

  done < <(pgrep -f "node_.*\.conf")

  printf "%.1f %.1f %d" "$cpu" "$mem" "$cnt"
}

get_node_stats() {
  local pid=$1
  if [[ -z "$pid" ]]; then
    echo "0.0 0.0"
    return
  fi
  ps -p "$pid" -o %cpu=,%mem= --no-headers 2>/dev/null || echo "0.0 0.0"
}
# === END FIXED STATS FUNCTIONS ===

is_port_listening() {
  local port=$1
  nc -z 127.0.0.1 "$port" 2>/dev/null && echo "Active" || echo "Inactive"
}

check_bootstrap() {
  local logfile=$1
  local port=$2

  # If port is listening, definitely Active
  if nc -z 127.0.0.1 "$port" 2>/dev/null; then
    echo "Active"
    return
  fi

  # Otherwise check log
  if grep -q "Bootstrapped 100%" "$logfile" 2>/dev/null; then
    echo "Active"
  elif grep -q "Bootstrapped" "$logfile" 2>/dev/null; then
    echo "Connecting"
  else
    echo "Inactive"
  fi
}

get_ip() {
  local port=$1 code=$2
  local ip_file="$STA/${code}_${port}.ip"
  if [[ -f "$ip_file" ]] && [[ $(find "$ip_file" -mmin -10 2>/dev/null) ]]; then
    cat "$ip_file"
  else
    local ip
    ip=$(curl --socks5-hostname "127.0.0.1:$port" -s --max-time 3 https://api.ipify.org 2>/dev/null 2>/dev/null || echo "?")
    echo "$ip" > "$ip_file"
    echo "$ip"
  fi
}

get_bandwidth() {
  local id=$1
  local bw
  bw=$(get_setting "$id" "bandwidth")
  echo "${bw:-0}"
}

set_bandwidth_db() {
  set_setting "$1" "bandwidth" "$2"
}

get_uptime() {
  local id=$1
  local up
  up=$(get_setting "$id" "uptime")
  echo "${up:-0}"
}

set_uptime() {
  set_setting "$1" "uptime" "$2"
}

format_uptime() {
  local start=$1
  [[ "$start" == "0" || -z "$start" ]] && { echo "--"; return; }
  local now diff
  now=$(date +%s)
  diff=$((now - start))
  if (( diff < 0 )); then echo "--"; return; fi
  if (( diff < 60 )); then echo "${diff}s"
  elif (( diff < 3600 )); then echo "$((diff/60))m $((diff%60))s"
  elif (( diff < 86400 )); then echo "$((diff/3600))h $(((diff%3600)/60))m"
  else echo "$((diff/86400))d $(((diff%86400)/3600))h"
  fi
}

line() {
  echo -e "${D}--------------------------------------------------------------${N}"
}

header() {
  clear
  local cpu mem cnt
  read -r cpu mem cnt <<< "$(get_stats)"
  echo
  echo -e "  ${C}${W}tor ML${N}  ${D}v2${N}"
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

  local bw
  bw=$(get_bandwidth "$id")

  cat > "$conf" <<EOF
SocksPort 127.0.0.1:$port
DataDirectory $dir
ExitNodes {$code}
StrictNodes 1
RunAsDaemon 1
Log notice file $logfile
ClientUseIPv6 0
SocksPolicy accept 127.0.0.1
SocksPolicy reject *
ClientOnly 1
AvoidDiskWrites 1
NumEntryGuards 2
CircuitBuildTimeout 20
MaxClientCircuitsPending 6
KeepalivePeriod 60
EOF

  if [[ "$bw" != "0" ]]; then
    cat >> "$conf" <<EOF
BandwidthRate $bw MB
BandwidthBurst $((bw * 2)) MB
EOF
  fi

  chown debian-tor:debian-tor "$conf" 2>/dev/null || true
  chmod 600 "$conf" 2>/dev/null || true

  if running "$code" "$port"; then
    echo -e "  ${Y}•${N} $name [${code}] already running on port $port"
    return 0
  fi

  pkill -f "node_${code}_${port}.conf" 2>/dev/null || true
  sleep 0.2
  : > "$logfile"
  chown debian-tor:debian-tor "$logfile" 2>/dev/null || true

  if ! sudo -u debian-tor /usr/bin/tor -f "$conf" >/dev/null 2>&1; then
    echo -e "  ${R}✗${N} $name [${code}] failed to start"
    [[ -s "$logfile" ]] && { echo -e "  ${Y}Log:${N}"; tail -n 5 "$logfile" | sed 's/^/    /'; }
    return 1
  fi

  local i=0
  while ! running "$code" "$port" && (( i < 10 )); do
    sleep 0.3
    i=$((i + 1))
  done

  if running "$code" "$port"; then
    set_uptime "$id" "$(date +%s)"
    local status="Connecting"
    local wait=0
    while (( wait < 20 )); do
      if grep -q "Bootstrapped 100%" "$logfile" 2>/dev/null; then
        status="Connected"
        break
      elif grep -q "Bootstrapped" "$logfile" 2>/dev/null; then
        status="Connecting"
      fi
      sleep 0.3
      wait=$((wait + 1))
    done
    echo -e "  ${G}✓${N} $name [${code}] started on port ${W}$port${N} [${G}$status${N}]"
    return 0
  fi

  echo -e "  ${R}✗${N} $name [${code}] failed to start"
  if [[ -s "$logfile" ]]; then
    echo -e "  ${Y}Log:${N}"
    tail -n 5 "$logfile" | sed 's/^/    /'
  fi
  return 1
}

stop_one() {
  local id=$1
  local code name port
  IFS='|' read -r code name port <<< "$(info "$id")"

  if ! running "$code" "$port"; then
    echo -e "  ${Y}•${N} $name [${code}] not running"
    return 0
  fi

  pkill -f "node_${code}_${port}.conf" 2>/dev/null || true
  sleep 0.2
  if running "$code" "$port"; then
    pkill -9 -f "node_${code}_${port}.conf" 2>/dev/null || true
    sleep 0.2
  fi
  echo -e "  ${G}✓${N} $name [${code}] stopped"
  set_uptime "$id" "0"
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
  echo -e "  ${C}ID   CC   Location                 Port      CPU   MEM   Socks  Status     Uptime       IP${N}"
  line
  for id in "${ORDER[@]}"; do
    local code name port
    IFS='|' read -r code name port <<< "$(info "$id")"
    local pid
    pid=$(get_pid "$code" "$port")

    if running "$code" "$port"; then
      local cpu mem
      read -r cpu mem <<< "$(get_node_stats "$pid")"
      local socks_status=$(is_port_listening "$port")
      local logfile="$LOG/${code}_${port}.log"
      local boot_status=$(check_bootstrap "$logfile" "$port")
      local ip=$(get_ip "$port" "$code")
      local uptime_display=$(format_uptime "$(get_uptime "$id")")

      case "$boot_status" in
        Active)  boot_col="$G" ;;
        Inactive) boot_col="$R" ;;
        Connecting) boot_col="$Y" ;;
      esac

      if [[ "$socks_status" == "Active" ]]; then
        socks_col="$G"
      else
        socks_col="$R"
      fi

      printf "  ${G}%-4s${N} %-4s %-24s %-8s ${G}%-5s${N} ${G}%-5s${N}  ${socks_col}%-6s${N}  ${boot_col}%-10s${N}  ${W}%-12s${N}  ${W}%s${N}\n" \
        "$id" "$code" "$name" "$port" "$cpu%" "$mem%" "$socks_status" "$boot_status" "$uptime_display" "$ip"
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
  echo -e "  ${D}Format: 1   or   1.4.12   or   1 4 12${N}"
  echo
  read -rp "$(echo -e "  ${C}Location(s): ${N}")" raw
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
  echo -e "  ${D}Format: 3   or   3.7.15${N}"
  echo
  read -rp "$(echo -e "  ${C}Location(s): ${N}")" raw
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
  ulimit -n 65535
  for id in "${ORDER[@]}"; do
    start_one "$id" | true
    sleep 0.1
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
    stop_one "$id" | true
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
  read -rp "$(echo -e "  ${C}Location ID: ${N}")" raw
  local id
  id=$(parse "$raw") || { echo -e "  ${R}Invalid ID${N}"; sleep 1; return; }
  local code name port
  IFS='|' read -r code name port <<< "$(info "$id")"
  echo
  echo -e "  Current: $name [${code}] on port ${W}$port${N}"
  read -rp "  New port (40000-60000): " new
  if ! [[ "$new" =~ ^[0-9]+$ ]] || (( new < 40000 || new > 60000 )); then
    echo -e "  ${R}Invalid port${N}"
    sleep 1
    return
  fi
  stop_one "$id"
  set_setting "$id" "port" "$new"
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
    printf "  %-18s " "$name"

    local lat
    lat=$(curl --socks5-hostname "127.0.0.1:$port" -o /dev/null -s -w "%{time_total}" \
      --max-time 15 "https://www.cloudflare.com/cdn-cgi/trace" 2>/dev/null | true || echo "fail")

    if [[ "$lat" == "fail" ]]; then
      echo -e "${R}unreachable${N}"
      continue
    fi

    local speed_raw
    speed_raw=$(curl --socks5-hostname "127.0.0.1:$port" -o /dev/null -s -w "%{speed_download}" \
      --max-time 20 "https://speed.cloudflare.com/__down?bytes=5000000" 2>/dev/null | true || echo "0")

    local speed_kb
    speed_kb=$(awk -v s="$speed_raw" 'BEGIN{printf "%.1f", s/1024}')

    local ip
    ip=$(curl --socks5-hostname "127.0.0.1:$port" -s --max-time 5 https://api.ipify.org 2>/dev/null | true || echo "?")

    echo -e "lat ${Y}${lat}s${N}  speed ${G}${speed_kb} KB/s${N}  ip ${W}${ip}${N}"
  done
  echo
  line
  echo -e "  ${D}Note: Tor is optimized for anonymity, not speed.${N}"
  echo
  read -rp "  Press Enter..."
}

view_log() {
  header
  echo -e "  ${C}View Log (last 20 lines)${N}"
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
  read -rp "$(echo -e "  ${C}Location ID: ${N}")" raw
  local id
  id=$(parse "$raw") || { echo -e "  ${R}Invalid ID${N}"; sleep 1; return; }
  local code name port
  IFS='|' read -r code name port <<< "$(info "$id")"
  local logfile="$LOG/${code}_${port}.log"
  if [[ ! -f "$logfile" ]]; then
    echo -e "  ${Y}No log file for this location.${N}"
    sleep 1.5
    return
  fi
  echo
  line
  tail -n 20 "$logfile" | sed 's/^/  /'
  line
  echo
  read -rp "  Press Enter..."
}

set_bandwidth() {
  header
  echo -e "  ${C}Set Bandwidth for Location${N}"
  echo
  echo -e "  ${D}Current bandwidth: 0 = unlimited${N}"
  echo
  for id in "${ORDER[@]}"; do
    local code name port
    IFS='|' read -r code name port <<< "$(info "$id")"
    local bw
    bw=$(get_bandwidth "$id")
    if [[ "$bw" == "0" ]]; then
      bw_display="${D}unlimited${N}"
    else
      bw_display="${G}${bw} MB${N}"
    fi
    printf "  ${C}[%s]${N} %-20s ${W}%-6s${N}  %b\n" "$id" "$name" "$port" "$bw_display"
  done
  line
  echo
  read -rp "$(echo -e "  ${C}Location ID: ${N}")" raw
  local id
  id=$(parse "$raw") || { echo -e "  ${R}Invalid ID${N}"; sleep 1; return; }
  local code name port
  IFS='|' read -r code name port <<< "$(info "$id")"
  echo
  echo -e "  ${D}Enter bandwidth in MB (0 = unlimited, 5, 10, 20, 50, 100):${N}"
  read -rp "$(echo -e "  ${M}Bandwidth (MB): ${N}")" bw
  if ! [[ "$bw" =~ ^[0-9]+$ ]]; then
    echo -e "  ${R}Invalid number${N}"
    sleep 1
    return
  fi
  set_bandwidth_db "$id" "$bw"
  if [[ "$bw" != "0" ]]; then
    echo -e "  ${G}Bandwidth set to ${bw} MB${N}  ${D}(apply on restart)${N}"
  else
    echo -e "  ${G}Bandwidth set to unlimited${N}"
  fi
  if running "$code" "$port"; then
    echo -e "  ${Y}Restart location to apply new bandwidth${N}"
  fi
  sleep 1.5
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
  pkill -f "node_.*\.conf" 2>/dev/null || true
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
  echo -e "  ${C}Installing tor ML v2 ...${N}"
  echo

  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y tor tor-geoipdb curl bc netcat-openbsd >/dev/null

  if ! id debian-tor &>/dev/null; then
    useradd --system --home-dir /var/lib/tor --shell /usr/sbin/nologin debian-tor 2>/dev/null || true
  fi

  systemctl stop tor 2>/dev/null || true
  systemctl disable tor 2>/dev/null || true

  mkdir -p "$CFG" "$DAT" "$LOG" "$STA"
  chown -R debian-tor:debian-tor "$DAT" "$LOG" 2>/dev/null || true

  cp "$0" "$CMD"
  chmod +x "$CMD"

  init_settings
  migrate_settings

  echo -e "  ${G}Installation complete!${N}"
  echo -e "  Run:  ${W}tor${N}"
  echo
  sleep 2
}

main() {
  ulimit -n 65535
  init_settings
  migrate_settings
  while true; do
    header
    echo -e "  ${C}[1]${N}  Full Status"
    echo -e "  ${C}[2]${N}  Start Location"
    echo -e "  ${C}[3]${N}  Stop Location"
    echo -e "  ${C}[4]${N}  Start All"
    echo -e "  ${C}[5]${N}  Stop All"
    echo -e "  ${C}[6]${N}  Change Port"
    echo -e "  ${C}[7]${N}  Speed Test"
    echo -e "  ${C}[8]${N}  View Log"
    echo -e "  ${C}[9]${N}  Set Bandwidth"
    echo -e "  ${R}[10]${N} Uninstall"
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
      8) view_log ;;
      9) set_bandwidth ;;
      10) uninstall ;;
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
