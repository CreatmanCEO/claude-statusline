# claude-statusline — CLAUDE.md (Level 1)

## Status: ACTIVE
Public Claude Code statusline tool. Pure bash + jq. No Node.js. Cross-platform via Git Bash / WSL on Windows.

## Architecture

Three artefacts and one cache:

- `vps-poller.sh` — background daemon. Runs `ssh root@host 'free / loadavg / df / uptime'` for each VPS every `VPS_POLL_INTERVAL` seconds (default 30 s). Writes one JSON file per VPS atomically via `mktemp + mv`. SSH timeout `VPS_SSH_TIMEOUT` seconds (default 5 s) → DOWN status.
- `/tmp/vps-<name>.json` — cache. One file per VPS. Statusline reads these instead of blocking on SSH.
- `statusline.sh` — runs on every Claude Code prompt. Reads cache (~0 ms latency), parses transcript for active-VPS auto-focus, applies colour thresholds, prints one bash line.
- `~/.claude/projects/*.jsonl` — Claude Code transcript. Last 20 KB scanned for `ssh` / `scp` / `sftp` invocations to drive auto-focus.

## Key Files

- `statusline.sh` — main script (343 lines). Functions: `color_by_threshold`, `calc_api_cost` (model-specific token pricing), `get_usage_limits` (OAuth → 5h/weekly quota), `format_tokens`, `format_duration`, `get_vps_status`, `detect_active_vps`.
- `vps-poller.sh` — daemon (94 lines). Functions: `log`, `poll_server`, `poll_all`. Controls: `start` / `stop` / `restart` / `status`.
- `install.sh` — installer (108 lines). Flags: `--vps` `--ru` `--tmux` `--minimal` `--uninstall`. Idempotent — re-run safely.
- `statusline.conf` — config schema. All knobs commented with defaults. Gets copied to `~/.claude/statusline.conf` on install.

## CRITICAL RULES — when editing this repo

- **NEVER** break backward compatibility on `statusline.conf` keys without a `CHANGELOG.md` entry under "Breaking changes". Users have hand-edited configs in production.
- **ALWAYS** keep `statusline.sh` portable across `bash 4+ / 5+`, macOS BSD utilities, and Linux GNU utilities. No `awk` features specific to GNU awk only. No bash 5-only constructs (`${var//pattern/}` is fine; `wait -n -p` is not).
- **ALWAYS** maintain `set -euo pipefail` discipline in scripts. `source ~/.claude/statusline.conf` must not crash the line on a typo — wrap in `set +u; source; set -u` or guard with `|| true`.
- **NEVER** introduce a network call from `statusline.sh` itself. The whole design assumes statusline rendering is non-blocking (cache-only). All slow IO lives in `vps-poller.sh`.
- **ALWAYS** mirror `README.md` and `README.ru.md` when changing user-facing surface area.
- **ALWAYS** update `CHANGELOG.md` for any change visible to users (new config key, glyph change, behaviour change, breaking change).

## Commands

- `bash install.sh` — install to `~/.claude/`
- `bash install.sh --uninstall` — clean removal
- `~/claude-statusline/vps-poller.sh start | stop | status` — daemon control
- `tail -f /tmp/vps-poller.log` — watch poller
- `bash -n statusline.sh && bash -n vps-poller.sh && bash -n install.sh` — syntax check (CI runs this)
- `shellcheck statusline.sh vps-poller.sh install.sh` — lint (CI runs this with `-S warning`)

## Key Patterns

1. **Cache decoupling.** Slow side (SSH) writes; fast side (statusline) reads. The decoupling is what makes a statusline running every prompt feasible.
2. **Atomic writes.** `vps-poller.sh` writes via `mktemp` + `mv`. Statusline never reads a half-written cache.
3. **Auto-focus from transcript.** Parses last 20 KB of `~/.claude/projects/*.jsonl`. Two-strategy: `ssh`/`scp`/`sftp` IPs first, then `VPS_MCP_MAP` for MCP-only setups.
4. **Threshold colouring.** `color_by_threshold` is the single function that maps a numeric % to ANSI green/yellow/red based on warn/crit thresholds. Used for context, RAM, CPU, disk, quota.

## Companion content

- [Habr article](https://habr.com/ru/articles/1013414/) — 9.3K reads, describes design rationale and the auto-focus heuristic.

## External validation

- [@AndyShaman/claude-statusline](https://github.com/AndyShaman/claude-statusline) — original inspiration for the H/W limits feature. Credit kept in README and in this file.

## Recent Changes

See [CHANGELOG.md](CHANGELOG.md).
