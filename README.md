<div align="center">

🌐 **Language / Язык**

[![English](https://img.shields.io/badge/English-blue?style=flat-square)](README.md) [![Русский](https://img.shields.io/badge/Русский-red?style=flat-square)](README.ru.md)

</div>

# claude-statusline

Smart status line for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — model, cost, context, usage limits, VPS health — all at a glance while you code.

![claude-statusline](screenshot.svg)

[![MIT](https://img.shields.io/github/license/CreatmanCEO/claude-statusline?style=flat-square&color=green)](LICENSE) [![bash](https://img.shields.io/badge/bash-script-4EAA25?style=flat-square&logo=gnubash&logoColor=white)]() [![platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-blue?style=flat-square)]()

**No Node.js. No npm. Pure bash + jq.**

## Installation

Open Claude Code (`claude` in your terminal) and say:

```
Clone https://github.com/CreatmanCEO/claude-statusline and install via install.sh
```

Or run directly in Claude Code:

```bash
git clone https://github.com/CreatmanCEO/claude-statusline.git ~/claude-statusline && bash ~/claude-statusline/install.sh
```

Restart Claude Code. The status line appears automatically.

> **Windows:** Run from inside Claude Code, not from PowerShell/cmd directly (`.sh` files need bash).

## What it shows

| Segment | Example | Description |
|---------|---------|-------------|
| Model | `Opus 4.6` | Current model |
| Git | `main*` | Branch + dirty indicator |
| Lines | `+47/-12` | Lines added/removed this session |
| Cost | `~$3.85(api)` | Theoretical API cost for subscribers; real cost for API users |
| Limits | `H:82% 3h12m W:94%` | 5-hour and 7-day quota remaining |
| Duration | `45m` | Session time |
| VPS | `main● sec●(R:45% D:48%)` | Server health with auto-focus |
| Context | `22% ctx` | Context window usage (green → yellow → red) |

## VPS Monitoring

For developers working with remote servers via MCP SSH — see your VPS health without switching context.

### Step 1 — Add servers

Tell Claude Code:
```
Open ~/.claude/statusline.conf and add:

SHOW_VPS=remote
VPS_SERVERS=(
  "prod|1.2.3.4|22|root|~/.ssh/my_key"
  "staging|5.6.7.8|22|root|~/.ssh/my_key"
)
```

### Step 2 — Start the poller

Tell Claude Code:
```
Run ~/claude-statusline/vps-poller.sh start
```

The poller runs in background, polling servers every 30s via SSH.

### Step 3 — Auto-focus active server

When you work with a server via MCP SSH, its metrics expand automatically.

Tell Claude Code:
```
Add to ~/.claude/statusline.conf:

VPS_FOCUS=auto
VPS_MCP_MAP=(
  "prod|my-mcp-prod"
  "staging|my-mcp-staging"
)
```

**Statuses:** 🟢● OK | 🟠◉ WARN (>80%) | 🔴✗ DOWN | 🟣↻ BOOT

## Usage Limits (H/W)

Shows remaining 5-hour (`H:82% 3h12m`) and 7-day (`W:94%`) quotas for Max/Pro/Team subscribers. Color-coded: green >50%, yellow 20-50%, red <20%.

Requires `claude login` authentication. Data cached for 2 minutes.

> Inspired by [@AndyShaman/claude-statusline](https://github.com/AndyShaman/claude-statusline) — thanks for the OAuth API documentation!

## Configuration

All settings in `~/.claude/statusline.conf`. Changes apply automatically — no restart needed.

Tell Claude Code: `Show my ~/.claude/statusline.conf`

| Parameter | Values | Description |
|-----------|--------|-------------|
| `SHOW_MODEL` | true/false | Model name |
| `SHOW_COST` | true/false | API cost |
| `SHOW_LIMITS` | true/false | H/W quotas |
| `SHOW_CONTEXT` | true/false | Context % |
| `SHOW_LINES` | true/false | Lines changed |
| `SHOW_DURATION` | true/false | Session time |
| `SHOW_GIT` | true/false | Git branch |
| `SHOW_TOKENS` | true/false | Token counts |
| `SHOW_VPS` | false/remote/local | VPS monitoring |
| `LANG_RU` | true/false | Russian labels |
| `CONTEXT_WARN` | 50 | Yellow threshold |
| `CONTEXT_CRIT` | 70 | Red threshold |

## Troubleshooting

### Status line disappeared after install (Windows)

On Windows, `.sh` files don't execute directly. Tell Claude Code:
```
In ~/.claude/settings.json set statusLine.command to: bash /c/Users/YOUR_NAME/.claude/statusline.sh
```

### H/W limits not showing

1. Run `claude login` if not authenticated
2. Tell Claude Code: `Check if ~/.claude/.credentials.json exists`
3. If not found — limits are silently skipped, everything else works

## Install options

```bash
bash ~/claude-statusline/install.sh            # basic
bash ~/claude-statusline/install.sh --ru       # Russian labels
bash ~/claude-statusline/install.sh --tmux     # tmux integration (Prefix+y popup)
bash ~/claude-statusline/install.sh --minimal  # model + context only
bash ~/claude-statusline/install.sh --uninstall
```

## Useful Claude Code commands

- `/cost` — session cost and tokens
- `/context` — detailed context window breakdown
- `/compact` — compress context (when status line turns red)
- `/model sonnet` — switch model

## Platforms

| | Status | Metrics | tmux |
|---|---|---|---|
| **Linux** | ✅ | ✅ | ✅ |
| **macOS** | ✅ | ✅ | ✅ |
| **Windows** (via Claude Code) | ✅ | ✅ | — |

## Credits

H/W usage limits feature inspired by [@AndyShaman/claude-statusline](https://github.com/AndyShaman/claude-statusline) — thank you for the idea and OAuth API documentation! If you only need limits without VPS monitoring, check out his version.

## License

MIT — [Nick Podolyak](https://github.com/CreatmanCEO) / CREATMAN Studio
