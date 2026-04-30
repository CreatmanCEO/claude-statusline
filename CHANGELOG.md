# Changelog

All notable changes to this project will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · [SemVer](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-04-30

### Added

- `docs/architecture.svg` — hand-rendered diagram of the cache-decoupling design (`vps-poller.sh` → `/tmp/vps-*.json` → `statusline.sh`, with the Claude Code transcript driving auto-focus). Renders inline in GitHub README.
- `docs/segments-annotated.svg` — explanatory diagram of every statusline segment with colour-coded labels above and below the rendered bar.
- `docs/screenshots/statusline-live.png` — embedded production screenshot from the [Habr article](https://habr.com/ru/articles/1013414/) (1560×256, 220 KB) showing a 100-hour Opus session with VPS auto-focus active.
- `CLAUDE.md` for this repository — a working Level 1 file documenting the architecture, key files, critical rules, commands, and patterns. Pairs with the [ai-context-hierarchy](https://github.com/CreatmanCEO/ai-context-hierarchy) sister repo.
- `CHANGELOG.md` (this file)
- `CONTRIBUTING.md` with a priority list for community submissions
- `.github/workflows/validate.yml` — CI checking `bash -n` syntax on all `.sh` files, `shellcheck -S warning` lint, internal Markdown link resolution, presence of `LICENSE` and `CHANGELOG.md`, and that every diagram referenced from README actually exists in `docs/`
- `Limitations` section in both READMEs covering the transcript-window heuristic, OS credential storage assumption, bash + jq requirement, global SSH timeout behaviour, lack of metric history, Windows-tmux unsupported, daemon being best-effort
- `Related` section cross-linking to [Claude Code Anti-Regression Setup](https://github.com/CreatmanCEO/claude-code-antiregression-setup) and [ai-context-hierarchy](https://github.com/CreatmanCEO/ai-context-hierarchy) (sister repos, same author)
- "Stars", "Validate", "Featured on Habr 9.3K reads", "Claude Code Opus 4.7" badges

### Changed

- README hero rewritten to lead with two social-proof signals (Habr article + 9.3K reads, Anthropic compatibility) and the one-line value proposition (`pure bash + jq, no Node.js`) — previously the value proposition was below the fold
- `What it shows` table renamed to `What every segment tells you` and is now anchored by the new annotated SVG diagram
- New `Architecture` section with the cache-decoupling diagram and a component-role table (was implicit in the configuration knobs only)
- `Configuration` table extended to include the previously undocumented `VPS_POLL_INTERVAL`, `VPS_SSH_TIMEOUT`, `VPS_STALE_SEC`, `COST_MODEL`, `TMUX_BRIDGE` knobs
- `Troubleshooting` section gained `VPS shows DOWN but server is fine` and `Auto-focus picks the wrong VPS` entries
- Author signature expanded with Habr / dev.to profile links

### Notes

- `screenshot.svg` (the original placeholder) is retained for backward-compat URLs; the README now references the live `statusline-live.png` and the annotated `segments-annotated.svg` instead.
- Topics on GitHub applied separately via `gh api` after merge.

## [0.1.0] — 2026-03-22

### Added

- Initial release accompanying the [Habr article](https://habr.com/ru/articles/1013414/) (9.3K reads as of writing)
- `statusline.sh` — model · git · lines · cost · usage limits · session duration · VPS health · context %
- `vps-poller.sh` — background SSH poller with atomic JSON cache writes
- `install.sh` — installer with `--vps` `--ru` `--tmux` `--minimal` `--uninstall` flags
- `statusline.conf` — full configuration schema with sensible defaults
- Auto-focus VPS detection via Claude Code transcript parsing (`ssh` / `scp` / `sftp` IP matching, with `VPS_MCP_MAP` fallback for MCP-only setups)
- 5-hour and weekly quota tracking via OAuth credential read from `~/.claude/.credentials.json` (inspired by [@AndyShaman/claude-statusline](https://github.com/AndyShaman/claude-statusline))
- Automatic API-vs-subscription cost detection (cost = 0 → theoretical pricing; cost > 0 → real)
- tmux integration (`Prefix+y` popup) when running inside a tmux session
- Russian language pack (`LANG_RU=true`) — labels render as `стр / контекст / мин / etc.`
- Cross-platform support — Linux, macOS, Windows (via Git Bash / WSL)
- `LICENSE` (MIT)
