#!/bin/bash
# vps-poller.sh — background VPS monitor for claude-statusline
# Usage: ./vps-poller.sh {start|stop|status|once}
set -eo pipefail
CONFIG_FILE="${CLAUDE_STATUSLINE_CONF:-$HOME/.claude/statusline.conf}"
PID_FILE="/tmp/vps-poller-${USER:-$(whoami)}.pid"
CACHE_DIR="/tmp"; LOG_FILE="/tmp/vps-poller.log"

VPS_POLL_INTERVAL="${VPS_POLL_INTERVAL:-30}"
VPS_SSH_TIMEOUT="${VPS_SSH_TIMEOUT:-5}"
VPS_BOOT_THRESHOLD="${VPS_BOOT_THRESHOLD:-300}"
VPS_SERVERS=()
VPS_WARN_RAM="${VPS_WARN_RAM:-80}"; VPS_CRIT_RAM="${VPS_CRIT_RAM:-90}"
VPS_WARN_CPU="${VPS_WARN_CPU:-80}"; VPS_CRIT_CPU="${VPS_CRIT_CPU:-90}"
VPS_WARN_DISK="${VPS_WARN_DISK:-80}"; VPS_CRIT_DISK="${VPS_CRIT_DISK:-90}"
if [[ -f "$CONFIG_FILE" ]]; then source "$CONFIG_FILE"; fi

RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; RESET='\033[0m'
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"; }

poll_server() {
  local name="$1" host="$2" port="$3" user="$4" key="$5"
  local cache_file="${CACHE_DIR}/vps-${name}.json" timestamp=$(date +%s)
  local remote_cmd='
    RAM_PCT=$(free 2>/dev/null|awk "/Mem:/{printf \"%.0f\",\$3/\$2*100}"||echo 0)
    RAM_USED=$(free -m 2>/dev/null|awk "/Mem:/{print \$3}"||echo 0)
    RAM_TOTAL=$(free -m 2>/dev/null|awk "/Mem:/{print \$2}"||echo 0)
    CPU_LOAD=$(cat /proc/loadavg 2>/dev/null|awk "{print \$1}"||echo 0)
    CPU_CORES=$(nproc 2>/dev/null||echo 1)
    CPU_PCT=$(awk -v l="$CPU_LOAD" -v c="$CPU_CORES" "BEGIN{printf \"%.0f\",(l/c)*100}")
    DISK_PCT=$(df / 2>/dev/null|awk "NR==2{gsub(/%/,\"\");print \$5}"||echo 0)
    DISK_USED=$(df -h / 2>/dev/null|awk "NR==2{print \$3}"||echo "?")
    DISK_TOTAL=$(df -h / 2>/dev/null|awk "NR==2{print \$2}"||echo "?")
    UPTIME_SEC=$(awk "{printf \"%.0f\",\$1}" /proc/uptime 2>/dev/null||echo 99999)
    echo "${RAM_PCT}|${RAM_USED}|${RAM_TOTAL}|${CPU_LOAD}|${CPU_PCT}|${CPU_CORES}|${DISK_PCT}|${DISK_USED}|${DISK_TOTAL}|${UPTIME_SEC}"'
  local ssh_opts="-o ConnectTimeout=${VPS_SSH_TIMEOUT} -o ServerAliveInterval=3 -o ServerAliveCountMax=1 -o StrictHostKeyChecking=no -o BatchMode=yes -o LogLevel=ERROR"
  [[ -n "$key" && "$key" != "-" ]] && ssh_opts+=" -i $key"
  local result
  if result=$(ssh $ssh_opts -p "$port" "${user}@${host}" "$remote_cmd" 2>/dev/null); then
    IFS='|' read -r ram_pct ram_used ram_total cpu_load cpu_pct cpu_cores disk_pct disk_used disk_total uptime_sec <<< "$result"
    local status="ok" status_reason=""
    (( uptime_sec < VPS_BOOT_THRESHOLD )) && { status="boot"; status_reason="uptime ${uptime_sec}s"; }
    if (( ram_pct >= VPS_WARN_RAM || cpu_pct >= VPS_WARN_CPU || disk_pct >= VPS_WARN_DISK )); then
      status="warn"
      (( ram_pct >= VPS_WARN_RAM )) && status_reason+="RAM:${ram_pct}% "
      (( cpu_pct >= VPS_WARN_CPU )) && status_reason+="CPU:${cpu_load} "
      (( disk_pct >= VPS_WARN_DISK )) && status_reason+="Disk:${disk_pct}% "
    fi
    (( ram_pct >= VPS_CRIT_RAM || cpu_pct >= VPS_CRIT_CPU || disk_pct >= VPS_CRIT_DISK )) && status="crit"
    echo "{\"name\":\"${name}\",\"host\":\"${host}\",\"status\":\"${status}\",\"reason\":\"${status_reason}\",\"ram_pct\":${ram_pct:-0},\"ram_used\":\"${ram_used:-0}\",\"ram_total\":\"${ram_total:-0}\",\"cpu_load\":\"${cpu_load:-0}\",\"cpu_pct\":${cpu_pct:-0},\"cpu_cores\":${cpu_cores:-1},\"disk_pct\":${disk_pct:-0},\"disk_used\":\"${disk_used:-?}\",\"disk_total\":\"${disk_total:-?}\",\"uptime_sec\":${uptime_sec:-0},\"timestamp\":${timestamp}}" > "$cache_file"
    log "OK: ${name} (${host}) — status=${status} ram=${ram_pct}% cpu=${cpu_load} disk=${disk_pct}%"
  else
    echo "{\"name\":\"${name}\",\"host\":\"${host}\",\"status\":\"down\",\"reason\":\"SSH timeout\",\"ram_pct\":0,\"cpu_pct\":0,\"disk_pct\":0,\"timestamp\":${timestamp}}" > "$cache_file"
    log "DOWN: ${name} (${host}) — SSH failed"
  fi
}

poll_all() {
  [[ ${#VPS_SERVERS[@]} -eq 0 ]] && { log "WARN: VPS_SERVERS not configured"; return 1; }
  for entry in "${VPS_SERVERS[@]}"; do
    IFS='|' read -r name host port user key <<< "$entry"
    poll_server "$name" "$host" "${port:-22}" "${user:-root}" "${key:--}" &
  done; wait
}

case "${1:-start}" in
  start)
    [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null && { echo -e "${YELLOW}Already running (PID $(cat "$PID_FILE"))${RESET}"; exit 1; }
    [[ ${#VPS_SERVERS[@]} -eq 0 ]] && { echo -e "${RED}Error: VPS_SERVERS not configured${RESET}\nAdd to ~/.claude/statusline.conf:\nVPS_SERVERS=(\n  \"main|1.2.3.4|22|root|~/.ssh/key\"\n)"; exit 1; }
    echo -e "${GREEN}Starting vps-poller${RESET}\n  Servers: ${#VPS_SERVERS[@]}\n  Interval: ${VPS_POLL_INTERVAL}s\n"
    echo "First poll..."; poll_all; echo ""
    for entry in "${VPS_SERVERS[@]}"; do
      IFS='|' read -r name host _ _ _ <<< "$entry"
      cf="${CACHE_DIR}/vps-${name}.json"
      [[ -f "$cf" ]] && { s=$(jq -r '.status' "$cf" 2>/dev/null||echo "?")
        case "$s" in ok) echo -e "  ${GREEN}●${RESET} ${name} — OK";; warn) echo -e "  ${YELLOW}◉${RESET} ${name} — WARNING";;
        crit) echo -e "  \033[31m◉${RESET} ${name} — CRITICAL";; down) echo -e "  \033[31m✗${RESET} ${name} — DOWN";;
        boot) echo -e "  \033[35m↻${RESET} ${name} — BOOTING";; esac; }
    done; echo ""
    ( echo $$ > "$PID_FILE"; log "Started (PID $$)"
      while true; do sleep "$VPS_POLL_INTERVAL"; [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"; poll_all; done ) &
    disown; echo -e "${GREEN}Poller running in background${RESET}\nStop: $0 stop";;
  stop)
    if [[ -f "$PID_FILE" ]]; then PID=$(cat "$PID_FILE")
      kill -0 "$PID" 2>/dev/null && { kill "$PID" 2>/dev/null; rm -f "$PID_FILE"; echo -e "${GREEN}Stopped (PID $PID)${RESET}"; } || { rm -f "$PID_FILE"; echo -e "${YELLOW}Not running (stale PID removed)${RESET}"; }
    else echo -e "${YELLOW}Not running${RESET}"; fi;;
  status)
    [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null && echo -e "${GREEN}Running${RESET} (PID $(cat "$PID_FILE"))" || echo -e "${YELLOW}Not running${RESET}"
    echo ""; for f in ${CACHE_DIR}/vps-*.json; do [[ -f "$f" ]] || continue
      echo "  $(jq -r '.name' "$f"):  status=$(jq -r '.status' "$f")  age=$(($(date +%s)-$(jq -r '.timestamp' "$f")))s"; done;;
  once) echo "Polling..."; poll_all; echo "Results:"
    for f in ${CACHE_DIR}/vps-*.json; do [[ -f "$f" ]] || continue; echo "  $(cat "$f")" | jq -c '.'; done;;
  *) echo "Usage: $0 {start|stop|status|once}"; exit 1;;
esac
