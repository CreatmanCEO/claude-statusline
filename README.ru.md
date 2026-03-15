<div align="center">

🌐 **Language / Язык**

[![English](https://img.shields.io/badge/English-blue?style=flat-square)](README.md) [![Русский](https://img.shields.io/badge/Русский-red?style=flat-square)](README.ru.md)

</div>

# claude-statusline

Умный status line для [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — модель, стоимость, контекст, лимиты, состояние VPS — всё перед глазами прямо во время работы.

![claude-statusline](screenshot.svg)

[![MIT](https://img.shields.io/github/license/CreatmanCEO/claude-statusline?style=flat-square&color=green)](LICENSE) [![bash](https://img.shields.io/badge/bash-script-4EAA25?style=flat-square&logo=gnubash&logoColor=white)]() [![platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-blue?style=flat-square)]()

**Без Node.js. Без npm. Чистый bash + jq.**

## Установка

Запусти Claude Code (`claude` в терминале) и скажи:

```
Клонируй https://github.com/CreatmanCEO/claude-statusline и установи через install.sh --ru
```

Или выполни прямо в Claude Code:

```bash
git clone https://github.com/CreatmanCEO/claude-statusline.git ~/claude-statusline && bash ~/claude-statusline/install.sh --ru
```

Перезапусти Claude Code. Статус-линия появится автоматически.

> **Windows (PowerShell/cmd):** Запускай из Claude Code, не из PowerShell напрямую (`.sh` файлы требуют bash).

## Что показывает

| Сегмент | Пример | Описание |
|---------|--------|----------|
| Модель | `Opus 4.6` | Текущая модель |
| Git | `main*` | Ветка + незакоммиченные изменения |
| Строки | `+47/-12 стр` | Добавлено/удалено за сессию |
| Стоимость | `~$3.85(api)` | Теоретическая для подписки; реальная для API |
| Лимиты | `H:82% 3h12m W:94%` | Остаток 5-часовой и 7-дневной квоты |
| Время | `45мин` | Длительность сессии |
| VPS | `main● sec●(R:45% D:48%)` | Состояние серверов с авто-фокусом |
| Контекст | `22% контекст` | Заполнение контекста (зелёный → жёлтый → красный) |

## VPS-мониторинг

Для разработчиков, работающих с серверами через MCP SSH — состояние VPS не отвлекаясь от кода.

### Шаг 1 — Добавить серверы

Скажи Claude Code:
```
Открой ~/.claude/statusline.conf и добавь:

SHOW_VPS=remote
VPS_SERVERS=(
  "main|95.85.234.200|22|root|~/.ssh/claude_vps"
  "new|95.85.235.189|22|root|~/.ssh/claude_vps"
  "sec|178.17.50.45|22|root|~/.ssh/claude_vps_key"
)
```

Замени IP, юзеров и пути к ключам на свои.

### Шаг 2 — Запустить поллер

Скажи Claude Code:
```
Запусти ~/claude-statusline/vps-poller.sh start
```

Поллер работает в фоне, опрашивает серверы каждые 30 секунд по SSH.

### Шаг 3 — Авто-фокус активного VPS

Когда работаешь с сервером через MCP SSH, его метрики разворачиваются автоматически.

Скажи Claude Code:
```
Добавь в ~/.claude/statusline.conf:

VPS_FOCUS=auto
VPS_MCP_MAP=(
  "main|vps-main"
  "new|vps-new"
  "sec|vps-secondary"
)
```

Левая часть — имя из `VPS_SERVERS`. Правая — имя MCP-подключения.

Результат: работаешь с `vps-main` → `main●(R:42% D:55%) new● sec●`. Переключился → метрики переключились.

**Статусы:** 🟢● ОК | 🟠◉ WARN (>80%) | 🔴✗ DOWN | 🟣↻ BOOT

## Лимиты использования (H/W)

Показывает остаток 5-часовой (`H:82% 3h12m`) и 7-дневной (`W:94%`) квоты для подписчиков Max/Pro/Team. Цвета: зелёный >50%, жёлтый 20-50%, красный <20%.

Требуется авторизация через `claude login`. Данные кэшируются на 2 минуты.

> Вдохновлено проектом [@AndyShaman/claude-statusline](https://github.com/AndyShaman/claude-statusline) — спасибо за идею и документацию OAuth API!

## Настройка

Все параметры в `~/.claude/statusline.conf`. Изменения подхватываются автоматически — перезапуск не нужен.

Скажи Claude Code: `Покажи мой ~/.claude/statusline.conf`

| Параметр | Значения | Что делает |
|----------|----------|------------|
| `SHOW_MODEL` | true/false | Имя модели |
| `SHOW_COST` | true/false | Стоимость |
| `SHOW_LIMITS` | true/false | Лимиты H/W |
| `SHOW_CONTEXT` | true/false | Процент контекста |
| `SHOW_LINES` | true/false | +/- строки |
| `SHOW_DURATION` | true/false | Время сессии |
| `SHOW_GIT` | true/false | Git branch |
| `SHOW_TOKENS` | true/false | Токены |
| `SHOW_VPS` | false/remote/local | VPS-мониторинг |
| `LANG_RU` | true/false | Русские подписи |
| `CONTEXT_WARN` | 50 | Жёлтый порог |
| `CONTEXT_CRIT` | 70 | Красный порог |

## Решение проблем

### Статуслайн пропал после установки (Windows)

На Windows `.sh` файлы не запускаются напрямую. Скажи Claude Code:
```
В ~/.claude/settings.json замени statusLine.command на: bash /c/Users/ТВОЁ_ИМЯ/.claude/statusline.sh
```

### Не отображаются лимиты H/W

1. Выполни `claude login` если ещё не делал
2. Скажи Claude Code: `Проверь есть ли файл ~/.claude/.credentials.json`
3. Если не найден — лимиты тихо пропускаются, остальное работает

## Варианты установки

В Claude Code:
```bash
bash ~/claude-statusline/install.sh --ru            # базовая + русский
bash ~/claude-statusline/install.sh --ru --tmux     # + tmux (popup по Prefix+y)
bash ~/claude-statusline/install.sh --minimal       # только модель + контекст
bash ~/claude-statusline/install.sh --uninstall     # удалить
```

## Полезные slash-команды Claude Code

- `/cost` — стоимость сессии и токены
- `/context` — детальная разбивка контекстного окна
- `/compact` — сжать контекст (когда статус-линия красная)
- `/model sonnet` — переключить модель

## Платформы

| | Статус | Метрики | tmux |
|---|---|---|---|
| **Linux** | ✅ | ✅ | ✅ |
| **macOS** | ✅ | ✅ | ✅ |
| **Windows** (через Claude Code) | ✅ | ✅ | — |

## Благодарности

Фича лимитов H/W вдохновлена проектом [@AndyShaman/claude-statusline](https://github.com/AndyShaman/claude-statusline) — спасибо за идею и документацию OAuth API! Если нужны только лимиты без VPS-мониторинга — рекомендуем его версию.

## Лицензия

MIT — [Nick Podolyak](https://github.com/CreatmanCEO) / CREATMAN Studio
