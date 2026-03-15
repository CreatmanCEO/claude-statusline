# claude-statusline

Smart status line for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with remote VPS monitoring, API cost estimation for Max/Pro/Team subscribers, and automatic tmux integration.

> **🇷🇺 Русскоязычный инструмент.** English docs below.

## Что это

bash + jq скрипт, показывающий полезную инфу в статус-баре Claude Code:

```
Opus │ main* │ +156/-23 │ ~$1.42(api) │ 12м │ 42% ctx
```

**Без Node.js. Без npm. Без плясок с бубном.**

## Фичи

- **Модель** — Opus / Sonnet / Haiku
- **Git** — ветка + dirty status
- **Строки кода** — добавлено/удалено за сессию
- **Стоимость API** — автоопределение: подписка → теоретическая `~$1.65(api)`, API → реальная `$0.14`
- **Контекстное окно** — цветовая индикация: 🟢 <50% 🟡 50-70% 🔴 >70% + `/compact!`
- **VPS-мониторинг** — удалённый через фоновый поллер:
  - `main● new● sec●` — всё ОК
  - `sec◉ RAM:87% Disk:93%` — проблема развёрнута
  - `new✗ DOWN` — сервер упал
  - `main↻` — перезагрузился
- **tmux** — bridge в статус-бар + popup по Prefix+y

## Платформы

| | Статус | Системные метрики | tmux |
|---|---|---|---|
| **Linux** | ✅ | RAM, CPU, Disk | ✅ |
| **macOS** | ✅ | vm_stat, sysctl | ✅ |
| **WSL** | ✅ | RAM, CPU, Disk | ✅ |
| **Git Bash** | ⚠️ | нет | нет |

## Быстрый старт

> **Windows (PowerShell/cmd):** команды ниже работают только в bash. Два варианта:
> 1. **Из Claude Code** (рекомендуется): запусти `claude` в PowerShell, затем прямо в нём выполни:
>    `git clone https://github.com/CreatmanCEO/claude-statusline.git ~/claude-statusline && bash ~/claude-statusline/install.sh --ru`
> 2. **Из Git Bash или WSL**: если установлены — выполни команды ниже напрямую

```bash
git clone https://github.com/CreatmanCEO/claude-statusline.git
cd claude-statusline
chmod +x install.sh
./install.sh                   # базовая
./install.sh --vps --tmux --ru # VPS + tmux + русский
./install.sh --minimal         # модель + контекст
./install.sh --uninstall       # удалить
```

## VPS-мониторинг

`SHOW_VPS` режимы: `false` (выкл) | `remote` (через поллер) | `local` (текущая машина)

```bash
# ~/.claude/statusline.conf
SHOW_VPS=remote
VPS_SERVERS=(
  "main|95.85.234.200|22|root|~/.ssh/claude_vps"
  "new|95.85.235.189|22|root|~/.ssh/claude_vps"
  "sec|178.17.50.45|22|root|~/.ssh/claude_vps_key"
)
```

```bash
./vps-poller.sh start   # запустить фоновый демон
./vps-poller.sh status  # проверить
./vps-poller.sh stop    # остановить
```

Статусы: 🟢● OK | 🟠◉ WARN (>80%) | 🔴◉ CRIT (>90%) | 🔴✗ DOWN | 🟣↻ BOOT (<5мин uptime)

## Зависимости

- `bash` 4+, `jq` (обязательно)
- `git`, `tmux`, `ssh` (опционально)

---

## English

Smart status line for Claude Code. Pure bash + jq, no Node.js required.

```
Opus │ main* │ +156/-23 │ ~$1.42(api) │ 12m │ 42% ctx
```

### Features
- Model, git branch, lines changed, context % with color coding
- API cost: theoretical for subscribers (Max/Pro/Team), real for API users
- Remote VPS monitoring via background SSH poller (compact dots when OK, expanded on problems)
- Auto tmux bridge + popup window (Prefix+y)

### Quick start
```bash
git clone https://github.com/CreatmanCEO/claude-statusline.git
cd claude-statusline && chmod +x install.sh
./install.sh              # basic
./install.sh --vps --tmux # VPS + tmux
```

### Platforms
Linux, macOS, Windows (WSL) — full support. Git Bash — basic (no system metrics).

## License

MIT — [Nick Podolyak](https://github.com/CreatmanCEO) / CREATMAN Studio
