# Contributing

Thanks for considering a contribution. This is a focused tool, not a framework — the bar for new content is "real use case, portable bash, doesn't break the cache decoupling."

## Priorities (highest impact first)

1. **Per-distribution package targets** — `apt`, `brew`, `dnf`, `pacman` install paths. Currently install is `git clone` + `bash install.sh`; package targets would let people `brew install claude-statusline`.
2. **Additional language locales** — current set is English (default) and Russian (`LANG_RU=true`). New locales should follow the same pattern: a `LANG_XX=true` flag and a label dictionary at the top of `statusline.sh`.
3. **Alternative VPS metric backends** — currently `vps-poller.sh` runs `free / loadavg / df / uptime` over SSH. Sister backends welcome:
   - **Netdata API** — local Netdata install on each VPS exposes `/api/v1/data?chart=…`. Faster, no SSH per poll.
   - **Prometheus push** — VPS pushes metrics to a local Prometheus, statusline reads from `/api/v1/query`.
   - **MCP `system_*` tools** — when MCP exposes a system-info tool, use it instead of SSH.
4. **Fish / Zsh shells** — `statusline.sh` works under bash. Sister scripts for fish (`statusline.fish`) and zsh (`statusline.zsh`) would let those users run natively without `bash` invocation.
5. **Per-glyph theming** — currently glyphs are hardcoded (`●` / `◉` / `✗` / `↻` / `▽`). A `GLYPH_*` config block would let users pick ASCII-only glyphs (`*` / `o` / `X` / `~` / `-`) for terminals without good Unicode rendering.
6. **systemd-user unit** — `vps-poller.sh start` is a detached process. A `systemd --user` unit file would survive reboots and integrate with `systemctl --user status vps-poller`.

## What we will not merge

- Changes that introduce a network call inside `statusline.sh`. The whole architecture rests on statusline being non-blocking; slow IO lives in the poller.
- Changes that break backward compatibility on `statusline.conf` keys without a `CHANGELOG.md` entry under "Breaking changes". Users have hand-edited configs in production.
- Changes that drop bash-portability (no `bash 5.1+`-only constructs, no GNU-only `awk`).
- New top-level scripts that duplicate `install.sh` / `statusline.sh` / `vps-poller.sh` responsibilities. Add an option to an existing script if possible.
- Pretty refactors with no user-visible benefit. This codebase fits in your head — keep it that way.

## Pull request checklist

- [ ] `bash -n` clean on every modified `.sh` file
- [ ] `shellcheck -S warning` clean (CI runs this)
- [ ] If `statusline.conf` schema changed: documented in README's `Configuration` table, listed in `CHANGELOG.md`, default kept backward-compatible
- [ ] If user-visible behaviour changed: `README.md` updated AND `README.ru.md` mirrored
- [ ] `CHANGELOG.md` entry under Unreleased or a new minor version
- [ ] `validate.yml` workflow passes locally

## Style

- Bash should look like bash, not Python. `[[` over `[`, `$()` over backticks, `local` for function variables, quoted variable expansions everywhere.
- Comment the *why*, never the *what*. `# poll every 30s — 5s SSH timeout × 3 servers must fit` is useful; `# loop 30 times` is not.
- Keep functions under 30 lines. If you need more, split.
- One feature per PR. Stack PRs if you have multiple.

## Author / maintainer

[@CreatmanCEO](https://github.com/CreatmanCEO) — Nick Podolyak. Open an issue first for anything larger than a config knob or a glyph.
