---
description: Настроить сессию агентов - многозадачность, состав команды, модели. Пишет claude-agents/SESSION.md.
---

Run the session survey. Ask in Russian via AskUserQuestion, in ONE call, three questions.
Do not read any other file first. Do not spawn any agent until SESSION.md is written.

**Q1 — header "Многозадачность"**
"Включить режим многозадачности?"
- "Нет, по одной задаче (Рекомендую)" — ceo-agent раздаёт задачи сам, по одной за раз. Дешевле по токенам, меньше путаницы, правки не наезжают друг на друга.
- "Да, параллельно" — ceo сможет поднимать несколько manager-agent, каждый ведёт свою задачу. Нужно только когда задачи реально не пересекаются по файлам.

**Q2 — header "Команда", multiSelect: true**
"Какие агенты участвуют в этом проекте?"
Options (по умолчанию имеет смысл взять все): "Разработка (frontend, backend, design)",
"Инфраструктура (server)", "Ресёрч и аналитика (researcher, business)",
"Память и аудит (memory, security)".
ceo-agent и manager-agent включены всегда, про них не спрашивай.
Скажи в описании: выключенный агент не грузит свой манифест — это и есть экономия.

**Q3 — header "Модель"**
"Какую модель дать агентам?"
- "Как в чате (Рекомендую)" — все агенты наследуют модель текущей сессии Claude Code.
- "Настроить отдельно" — задать модель и effort по ролям.

If the user picks "Настроить отдельно", ask ONE follow-up AskUserQuestion offering presets:
- "Экономный" — руки sonnet/medium, ceo и business opus/high, memory haiku/low.
- "Стандартный" — все inherit, effort как в манифестах агентов.
- "Максимум" — все opus, effort high, memory low.

Then write `claude-agents/SESSION.md`, keeping these five keys EXACTLY in this format —
the SessionStart hook greps them and will re-trigger the survey if they drift:

```
# SESSION — конфигурация текущей сессии

DATE: <YYYY-MM-DD, сегодня>
MULTITASK: on | off
AGENTS: ceo,manager,<остальные выбранные, через запятую, суффикс -agent не писать>
MODEL: inherit | <пресет>
EFFORT: default | <пресет>
```

Below those lines add a short Russian note on what was chosen and why, for the user's own eyes.

Finally tell the user, in Russian and in two lines: конфигурация записана, и что дальше
работать через `@ceo-agent`. Ничего больше не делай — задачу от пользователя ещё не получал.
