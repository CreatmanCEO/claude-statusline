#!/bin/bash
# claude-statusline — smart status line for Claude Code
# https://github.com/CreatmanCEO/claude-statusline
set -eo pipefail

CONFIG_FILE="${CLAUDE_STATUSLINE_CONF:-$HOME/.claude/statusline.conf}"

SHOW_MODEL="${SHOW_MODEL:-true}"
SHOW_COST="${SHOW_COST:-true}"
SHOW_CONTEXT="${SHOW_CONTEXT:-true}"
SHOW_LINES="${SHOW_LINES:-true}"
SHOW_DURATION="${SHOW_DURATION:-true}"
SHOW_GIT="${SHOW_GIT:-true}"
SHOW_VPS="${SHOW_VPS:-false}"
SHOW_TOKENS="${SHOW_TOKENS:-false}"
TMUX_BRIDGE="${TMUX_BRIDGE:-auto}"
TMUX_FILE="${TMUX_FILE:-/tmp/claude-status-${USER:-$(whoami)}}"
CONTEXT_WARN="${CONTEXT_WARN:-50}"
CONTEXT_CRIT="${CONTEXT_CRIT:-70}"
SEPARATOR="${SEPARATOR:- │ }"
STYLE="${STYLE:-plain}"
POWERLINE_SEP="${POWERLINE_SEP:-}"
LANG_RU="${LANG_RU:-false}"
VPS_WARN_RAM="${VPS_WARN_RAM:-80}"
VPS_CRIT_RAM="${VPS_CRIT_RAM:-90}"
VPS_WARN_DISK="${VPS_WARN_DISK:-80}"
VPS_CRIT_DISK="${VPS_CRIT_DISK:-90}"
COST_MODEL="${COST_MODEL:-auto}"
VPS_FOCUS="${VPS_FOCUS:-auto}"          # auto | имя_сервера | none
VPS_MCP_MAP=("${VPS_MCP_MAP[@]}")      # маппинг MCP→VPS: "main|vps-main" 

if [[ -f "$CONFIG_FILE" ]]; then source "$CONFIG_FILE"; fi

C_RESET="\033[0m"; C_BOLD="\033[1m"; C_DIM="\033[2m"
C_RED="\033[31m"; C_GREEN="\033[32m"; C_YELLOW="\033[33m"
C_BLUE="\033[34m"; C_MAGENTA="\033[35m"; C_CYAN="\033[36m"
C_WHITE="\033[37m"; C_GRAY="\033[90m"

color_by_threshold() {
  local value="$1" warn="$2" crit="$3"
  if (( value >= crit )); then echo -n "$C_RED"
  elif (( value >= warn )); then echo -n "$C_YELLOW"
  else echo -n "$C_GREEN"; fi
}

calc_api_cost() {
  local model_id="$1" input_tokens="$2" output_tokens="$3"
  local input_price output_price
  case "$model_id" in
    *opus*) input_price="15.00"; output_price="75.00" ;;
    *sonnet*) input_price="3.00"; output_price="15.00" ;;
    *haiku*) input_price="0.25"; output_price="1.25" ;;
    *) input_price="3.00"; output_price="15.00" ;;
  esac
  echo "$input_tokens $output_tokens $input_price $output_price" | awk '{printf "%.2f", ($1/1000000*$3)+($2/1000000*$4)}'
}

format_tokens() {
  local tokens="$1"
  if (( tokens >= 1000000 )); then printf "%.1fM" "$(echo "$tokens" | awk '{printf "%.1f",$1/1000000}')"
  elif (( tokens >= 1000 )); then printf "%.1fk" "$(echo "$tokens" | awk '{printf "%.1f",$1/1000}')"
  else echo "${tokens}"; fi
}

format_duration() {
  local ms="$1" seconds=$(($1/1000)) minutes=$(($1/1000/60)) hours=$(($1/1000/60/60))
  if (( hours > 0 )); then
    [[ "$LANG_RU" == "true" ]] && printf "%dч%dм" "$hours" "$((minutes%60))" || printf "%dh%dm" "$hours" "$((minutes%60))"
  elif (( minutes > 0 )); then
    [[ "$LANG_RU" == "true" ]] && printf "%dмин" "$minutes" || printf "%dm" "$minutes"
  else
    [[ "$LANG_RU" == "true" ]] && printf "%dс" "$seconds" || printf "%ds" "$seconds"
  fi
}

input=$(cat)
MODEL_ID=$(echo "$input" | jq -r '.model.id // "unknown"')
MODEL_NAME=$(echo "$input" | jq -r '.model.display_name // "?"')
COST_USD=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
WORK_DIR=$(echo "$input" | jq -r '.workspace.current_dir // ""')
TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path // ""')

segments=()

if [[ "$SHOW_MODEL" == "true" ]]; then
  segments+=("${C_MAGENTA}${C_BOLD}${MODEL_NAME}${C_RESET}")
fi

if [[ "$SHOW_GIT" == "true" && -n "$WORK_DIR" ]]; then
  if git -C "$WORK_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
    GIT_BRANCH=$(git -C "$WORK_DIR" branch --show-current 2>/dev/null || echo "")
    GIT_DIRTY=""
    if ! git -C "$WORK_DIR" diff --quiet HEAD &>/dev/null 2>&1; then GIT_DIRTY="*"; fi
    if [[ -n "$GIT_BRANCH" ]]; then
      segments+=("${C_CYAN}${GIT_BRANCH}${GIT_DIRTY}${C_RESET}")
    fi
  fi
fi

if [[ "$SHOW_LINES" == "true" ]]; then
  if [[ "$LANG_RU" == "true" ]]; then
    segments+=("${C_GREEN}+${LINES_ADD}${C_RESET}${C_RED}/-${LINES_DEL}${C_RESET} ${C_DIM}стр${C_RESET}")
  else
    segments+=("${C_GREEN}+${LINES_ADD}${C_RESET}${C_RED}/-${LINES_DEL}${C_RESET}")
  fi
fi

if [[ "$SHOW_TOKENS" == "true" ]]; then
  IN_FMT=$(format_tokens "$INPUT_TOKENS"); OUT_FMT=$(format_tokens "$OUTPUT_TOKENS")
  segments+=("${C_BLUE}${IN_FMT}${C_DIM}→${C_RESET}${C_BLUE}${OUT_FMT}${C_RESET}")
fi

if [[ "$SHOW_COST" == "true" ]]; then
  DISPLAY_COST=$(printf '%.2f' "$COST_USD")
  if [[ "$DISPLAY_COST" != "0.00" ]]; then
    segments+=("${C_YELLOW}\$${DISPLAY_COST}${C_RESET}")
  else
    if [[ "$COST_MODEL" == "auto" ]]; then API_COST=$(calc_api_cost "$MODEL_ID" "$INPUT_TOKENS" "$OUTPUT_TOKENS")
    else API_COST=$(calc_api_cost "$COST_MODEL" "$INPUT_TOKENS" "$OUTPUT_TOKENS"); fi
    segments+=("${C_YELLOW}~\$${API_COST}${C_DIM}(api)${C_RESET}")
  fi
fi

if [[ "$SHOW_DURATION" == "true" ]]; then
  segments+=("${C_DIM}$(format_duration "$DURATION_MS")${C_RESET}")
fi

if [[ "$SHOW_VPS" == "local" ]]; then
  RAM_PCT=""
  if command -v free &>/dev/null; then RAM_PCT=$(free | awk '/Mem:/{printf "%.0f",$3/$2*100}')
  elif command -v vm_stat &>/dev/null; then RAM_PCT=$(vm_stat | awk '/Pages active/{a=$3}/Pages wired/{w=$4}/Pages free/{f=$3}/Pages inactive/{i=$3}/Pages speculative/{s=$3}END{gsub(/\./,"",a);gsub(/\./,"",w);gsub(/\./,"",f);gsub(/\./,"",i);gsub(/\./,"",s);total=a+w+f+i+s;used=a+w;printf "%.0f",(used/total)*100}'); fi
  [[ -n "$RAM_PCT" ]] && segments+=("$(color_by_threshold "$RAM_PCT" "$VPS_WARN_RAM" "$VPS_CRIT_RAM")RAM:${RAM_PCT}%${C_RESET}")
  LOAD=""
  if [[ -f /proc/loadavg ]]; then LOAD=$(awk '{print $1}' /proc/loadavg); CORES=$(nproc 2>/dev/null||echo 1)
  elif command -v sysctl &>/dev/null && sysctl -n vm.loadavg &>/dev/null; then LOAD=$(sysctl -n vm.loadavg|awk '{print $2}'); CORES=$(sysctl -n hw.ncpu 2>/dev/null||echo 1); fi
  [[ -n "$LOAD" ]] && { LOAD_PCT=$(echo "$LOAD ${CORES:-1}"|awk '{printf "%.0f",($1/$2)*100}'); segments+=("$(color_by_threshold "$LOAD_PCT" 70 90)CPU:${LOAD}${C_RESET}"); }
  if command -v df &>/dev/null; then
    DISK_PCT=$(df -h / | awk 'NR==2{gsub(/%/,"");print $5}'); DISK_LABEL="Disk"
    [[ "$LANG_RU" == "true" ]] && DISK_LABEL="Диск"
    segments+=("$(color_by_threshold "$DISK_PCT" "$VPS_WARN_DISK" "$VPS_CRIT_DISK")${DISK_LABEL}:${DISK_PCT}%${C_RESET}")
  fi
elif [[ "$SHOW_VPS" == "remote" || "$SHOW_VPS" == "true" ]]; then
  VPS_CACHE_DIR="${VPS_CACHE_DIR:-/tmp}"; VPS_STALE_SEC="${VPS_STALE_SEC:-120}"; now=$(date +%s)

  # --- Авто-определение активного VPS из transcript ---
  FOCUSED_VPS=""
  if [[ "$VPS_FOCUS" == "auto" && -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" && ${#VPS_MCP_MAP[@]} -gt 0 ]]; then
    # Читаем последние 10KB transcript — ищем последний MCP SSH вызов
    TAIL_DATA=$(tail -c 10000 "$TRANSCRIPT_PATH" 2>/dev/null || true)
    for mapping in "${VPS_MCP_MAP[@]}"; do
      IFS='|' read -r vps_name mcp_name <<< "$mapping"
      if echo "$TAIL_DATA" | grep -q "$mcp_name" 2>/dev/null; then
        FOCUSED_VPS="$vps_name"  # последний найденный = последний использованный
      fi
    done
  elif [[ "$VPS_FOCUS" != "auto" && "$VPS_FOCUS" != "none" ]]; then
    FOCUSED_VPS="$VPS_FOCUS"  # ручной режим
  fi

  vps_segment=""; has_vps=false
  for cache_file in "${VPS_CACHE_DIR}"/vps-*.json; do
    [[ -f "$cache_file" ]] || continue; has_vps=true
    vps_name=$(jq -r '.name // "?"' "$cache_file" 2>/dev/null)
    vps_status=$(jq -r '.status // "down"' "$cache_file" 2>/dev/null)
    vps_ts=$(jq -r '.timestamp // 0' "$cache_file" 2>/dev/null)
    vps_ram=$(jq -r '.ram_pct // 0' "$cache_file" 2>/dev/null)
    vps_cpu=$(jq -r '.cpu_load // "0"' "$cache_file" 2>/dev/null)
    vps_disk=$(jq -r '.disk_pct // 0' "$cache_file" 2>/dev/null)
    cache_age=$(( now - vps_ts ))
    (( cache_age > VPS_STALE_SEC )) && vps_status="stale"

    # Этот VPS в фокусе? (активный или проблемный)
    is_focused=false
    [[ "$vps_name" == "$FOCUSED_VPS" ]] && is_focused=true
    [[ "$vps_status" == "warn" || "$vps_status" == "crit" || "$vps_status" == "down" ]] && is_focused=true

    case "$vps_status" in
      ok) sym="●"; color="$C_GREEN" ;; warn) sym="◉"; color="$C_YELLOW" ;;
      crit) sym="◉"; color="$C_RED" ;; down) sym="✗"; color="$C_RED" ;;
      boot) sym="↻"; color="$C_MAGENTA" ;; *) sym="?"; color="$C_GRAY" ;;
    esac

    if [[ "$is_focused" == "true" ]]; then
      # Развёрнутый вид — активный или проблемный сервер
      if [[ "$vps_status" == "down" ]]; then
        [[ "$LANG_RU" == "true" ]] && vps_segment+="${color}${C_BOLD}${vps_name}${sym} НЕТ СВЯЗИ${C_RESET} " || vps_segment+="${color}${C_BOLD}${vps_name}${sym} DOWN${C_RESET} "
      else
        vps_segment+="${color}${vps_name}${sym}${C_RESET}"
        vps_segment+=" $(color_by_threshold "$vps_ram" "$VPS_WARN_RAM" "$VPS_CRIT_RAM")R:${vps_ram}%${C_RESET}"
        vps_segment+=" $(color_by_threshold "$vps_disk" "$VPS_WARN_DISK" "$VPS_CRIT_DISK")D:${vps_disk}%${C_RESET}"
        vps_segment+=" "
      fi
    else
      # Компактный вид — только точка
      vps_segment+="${color}${vps_name}${sym}${C_RESET} "
    fi
  done
  [[ "$has_vps" == "true" ]] && { vps_segment="${vps_segment% }"; segments+=("$vps_segment"); }
fi

if [[ "$SHOW_CONTEXT" == "true" ]]; then
  CTX_COLOR=$(color_by_threshold "$CTX_PCT" "$CONTEXT_WARN" "$CONTEXT_CRIT")
  if (( CTX_PCT >= CONTEXT_CRIT )); then
    CTX_LABEL="${C_BOLD}${CTX_COLOR}${CTX_PCT}% ctx${C_RESET} ${C_RED}${C_BOLD}/compact!${C_RESET}"
  else
    [[ "$LANG_RU" == "true" ]] && CTX_LABEL="${CTX_COLOR}${CTX_PCT}% контекст${C_RESET}" || CTX_LABEL="${CTX_COLOR}${CTX_PCT}% ctx${C_RESET}"
  fi
  segments+=("$CTX_LABEL")
fi

output=""
for i in "${!segments[@]}"; do
  (( i > 0 )) && output+="${C_DIM}${SEPARATOR}${C_RESET}"
  output+="${segments[$i]}"
done
printf "%b" "$output"

if [[ "$TMUX_BRIDGE" == "on" ]] || { [[ "$TMUX_BRIDGE" == "auto" ]] && [[ -n "${TMUX:-}" ]]; }; then
  PLAIN_OUTPUT=$(printf "%b" "$output" | sed 's/\x1b\[[0-9;]*m//g')
  echo "$PLAIN_OUTPUT" > "$TMUX_FILE"
fi
