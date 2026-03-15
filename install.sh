#!/bin/bash
# claude-statusline — installer
set -euo pipefail
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; CYAN='\033[36m'; BOLD='\033[1m'; RESET='\033[0m'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"; STATUSLINE_PATH="$CLAUDE_DIR/statusline.sh"
CONF_PATH="$CLAUDE_DIR/statusline.conf"; SETTINGS_PATH="$CLAUDE_DIR/settings.json"
OPT_VPS=false; OPT_RU=false; OPT_TMUX=false; OPT_MINIMAL=false; OPT_UNINSTALL=false

for arg in "$@"; do
  case "$arg" in
    --vps) OPT_VPS=true;; --ru) OPT_RU=true;; --tmux) OPT_TMUX=true;;
    --minimal) OPT_MINIMAL=true;; --uninstall) OPT_UNINSTALL=true;;
    --help|-h) echo -e "${BOLD}claude-statusline installer${RESET}\n\nUsage: ./install.sh [OPTIONS]\n\n  --vps     VPS monitoring\n  --ru      Russian labels\n  --tmux    tmux integration\n  --minimal Model + context only\n  --uninstall Remove\n\nExamples:\n  ./install.sh\n  ./install.sh --vps --tmux --ru\n  ./install.sh --minimal"; exit 0;;
    *) echo -e "${RED}Unknown: $arg${RESET}"; exit 1;;
  esac
done

if [[ "$OPT_UNINSTALL" == "true" ]]; then
  echo -e "${YELLOW}Removing claude-statusline...${RESET}"
  [[ -f "$STATUSLINE_PATH" ]] && rm "$STATUSLINE_PATH" && echo "  Removed $STATUSLINE_PATH"
  [[ -f "$CONF_PATH" ]] && rm "$CONF_PATH" && echo "  Removed $CONF_PATH"
  if [[ -f "$SETTINGS_PATH" ]] && command -v jq &>/dev/null; then
    if jq -e '.statusLine' "$SETTINGS_PATH" &>/dev/null; then
      TMP=$(mktemp); jq 'del(.statusLine)' "$SETTINGS_PATH" > "$TMP" && mv "$TMP" "$SETTINGS_PATH"
      echo "  Removed statusLine from settings.json"
    fi
  fi
  echo -e "${GREEN}Done! Restart Claude Code.${RESET}"; exit 0
fi

echo -e "${BOLD}${CYAN}claude-statusline${RESET} — install\n"
if ! command -v jq &>/dev/null; then
  echo -e "${RED}Error: jq not installed${RESET}\n"
  command -v apt &>/dev/null && echo -e "Install: ${BOLD}sudo apt install jq${RESET}"
  command -v brew &>/dev/null && echo -e "Install: ${BOLD}brew install jq${RESET}"
  command -v dnf &>/dev/null && echo -e "Install: ${BOLD}sudo dnf install jq${RESET}"
  exit 1
fi
echo -e "  ${GREEN}✓${RESET} jq found"
command -v git &>/dev/null && echo -e "  ${GREEN}✓${RESET} git found" || echo -e "  ${YELLOW}○${RESET} git not found"
HAS_TMUX=false
command -v tmux &>/dev/null && { echo -e "  ${GREEN}✓${RESET} tmux found"; HAS_TMUX=true; } || echo -e "  ${YELLOW}○${RESET} tmux not found"
echo ""

mkdir -p "$CLAUDE_DIR"
cp "$SCRIPT_DIR/statusline.sh" "$STATUSLINE_PATH"; chmod +x "$STATUSLINE_PATH"
echo -e "  ${GREEN}✓${RESET} Script: $STATUSLINE_PATH"

CONF_CONTENT="# claude-statusline config — generated $(date +%Y-%m-%d)\n"
if [[ "$OPT_MINIMAL" == "true" ]]; then
  CONF_CONTENT+="SHOW_MODEL=true\nSHOW_COST=false\nSHOW_CONTEXT=true\nSHOW_LINES=false\nSHOW_DURATION=false\nSHOW_GIT=false\nSHOW_TOKENS=false\nSHOW_VPS=false\n"
else
  CONF_CONTENT+="SHOW_MODEL=true\nSHOW_COST=true\nSHOW_CONTEXT=true\nSHOW_LINES=true\nSHOW_DURATION=true\nSHOW_GIT=true\n"
  [[ "$OPT_VPS" == "true" ]] && CONF_CONTENT+="SHOW_VPS=true\nSHOW_TOKENS=true\nVPS_WARN_RAM=80\nVPS_CRIT_RAM=90\n" || CONF_CONTENT+="SHOW_VPS=false\nSHOW_TOKENS=false\n"
fi
[[ "$OPT_RU" == "true" ]] && CONF_CONTENT+="\nLANG_RU=true\n"
CONF_CONTENT+="\nCONTEXT_WARN=50\nCONTEXT_CRIT=70\nCOST_MODEL=auto\nTMUX_BRIDGE=auto\n"

if [[ -f "$CONF_PATH" ]]; then
  echo -e "  ${YELLOW}○${RESET} Config exists: $CONF_PATH (not overwritten)"
  echo -e "$CONF_CONTENT" > "${CONF_PATH}.new"
else
  echo -e "$CONF_CONTENT" > "$CONF_PATH"
  echo -e "  ${GREEN}✓${RESET} Config: $CONF_PATH"
fi

# Windows can't execute .sh directly — need "bash" prefix (not full path!)
if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || -n "${APPDATA:-}" ]]; then
  STATUSLINE_CMD="bash $HOME/.claude/statusline.sh"
else
  STATUSLINE_CMD="$HOME/.claude/statusline.sh"
fi
if [[ -f "$SETTINGS_PATH" ]]; then
  if command -v jq &>/dev/null; then
    TMP=$(mktemp)
    jq --arg cmd "$STATUSLINE_CMD" '.statusLine={"type":"command","command":$cmd,"padding":0}' "$SETTINGS_PATH" > "$TMP"
    mv "$TMP" "$SETTINGS_PATH"; echo -e "  ${GREEN}✓${RESET} Updated: $SETTINGS_PATH"
  fi
else
  printf '{\n  "statusLine": {"type":"command","command":"%s","padding":0}\n}\n' "$STATUSLINE_CMD" > "$SETTINGS_PATH"
  echo -e "  ${GREEN}✓${RESET} Created: $SETTINGS_PATH"
fi

if [[ "$OPT_TMUX" == "true" ]] && [[ "$HAS_TMUX" == "true" ]]; then
  echo -e "\n${BOLD}Setting up tmux...${RESET}"
  TMUX_CONF="$HOME/.tmux.conf"
  if [[ -f "$TMUX_CONF" ]] && grep -q "claude-status" "$TMUX_CONF"; then
    echo -e "  ${YELLOW}○${RESET} tmux already configured"
  else
    cat >> "$TMUX_CONF" << TMUXEOF

# --- claude-statusline ---
set -g status-right "#[fg=cyan]#(cat /tmp/claude-status-$USER 2>/dev/null)#[fg=white] | %H:%M"
set -g status-interval 5
set -g status-right-length 120
bind -r y run-shell 'SESSION="claude-\$(tmux display-message -p "#{pane_current_path}" | md5sum | cut -c1-8)"; tmux has-session -t "\$SESSION" 2>/dev/null || tmux new-session -d -s "\$SESSION" -c "#{pane_current_path}" "claude"; tmux display-popup -w80% -h80% -E "tmux attach -t \$SESSION"'
# --- /claude-statusline ---
TMUXEOF
    echo -e "  ${GREEN}✓${RESET} Added tmux integration"
    echo -e "  ${CYAN}Tip:${RESET} Prefix + y → Claude Code popup"
  fi
fi

echo -e "\n${GREEN}${BOLD}Installation complete!${RESET}\n"
echo -e "Restart Claude Code and the status line will appear.\n"
echo -e "${BOLD}Config:${RESET} ${CYAN}$CONF_PATH${RESET}"
echo -e "${BOLD}Script:${RESET} ${CYAN}$STATUSLINE_PATH${RESET}"
