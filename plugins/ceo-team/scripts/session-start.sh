#!/usr/bin/env bash
# SessionStart hook for the ceo-team plugin.
# Deploys the working folders on first run, then either replays the session
# config (cheap) or asks Claude to run the survey (only when config is stale).
set -uo pipefail

# "quiet" — фоновый прогон (UserPromptSubmit / ConfigChange): молчит, если всё на месте.
QUIET=0
[ "${1:-}" = "quiet" ] && QUIET=1

# stdin хука: JSON с полем prompt. Терминал не читаем, иначе повиснем.
PAYLOAD=""; PROMPT=""
if [ ! -t 0 ]; then PAYLOAD="$(cat 2>/dev/null || true)"; fi
if [ -n "$PAYLOAD" ]; then
  PROMPT="$(printf '%s' "$PAYLOAD" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("prompt",""))' 2>/dev/null || true)"
fi

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
AG="$ROOT/claude-agents"
MEDIA="$ROOT/claude-media-agents"
SESSION="$AG/SESSION.md"
TPL="${CLAUDE_PLUGIN_ROOT:-}/template"
TODAY="$(date +%F)"
FRESH=0

# --- deployment: every item checked on its own -------------------------------
# Never gate this on "does claude-agents/ exist" — /start creates that folder for
# SESSION.md alone, and a coarse gate would then skip the rest of the structure.
[ -d "$AG/memory" ]   || FRESH=1
[ -d "$MEDIA" ]       || FRESH=1
mkdir -p "$AG/memory" "$AG/RECOVERY" "$MEDIA"
for a in ceo manager frontend backend design researcher server security business memory; do
  mkdir -p "$AG/memory/$a-agent"
  [ -f "$AG/memory/$a-agent/INDEX.md" ] || \
    printf '# INDEX — %s-agent\n# one line per block: [tags] YYYY-MM-DD Title -> file\n' "$a" \
    > "$AG/memory/$a-agent/INDEX.md"
done
if [ -d "$TPL" ]; then
  for f in TO-DO-LIST.md READY-LIST.md; do
    [ -f "$TPL/$f" ] && [ ! -f "$AG/$f" ] && cp "$TPL/$f" "$AG/$f"
  done
  [ -f "$TPL/RECOVERY/MASTER.md" ] && [ ! -f "$AG/RECOVERY/MASTER.md" ] && \
    cp "$TPL/RECOVERY/MASTER.md" "$AG/RECOVERY/MASTER.md"
fi
[ -f "$MEDIA/README.md" ] || printf '%s\n' \
  '# Материалы для агентов' '' \
  'Кладите сюда что угодно: скриншоты, выгрузки, тексты, черновики.' \
  'ceo-agent берёт отсюда исходники по вашей просьбе, агенты складывают сюда' \
  'любые .md, не относящиеся к их работе.' > "$MEDIA/README.md"

# --- self-ignoring folders: layer 1, independent of the project .gitignore ---
# "*" inside the folder hides the folder's whole content from git even if the
# root .gitignore is rewritten, or the folder is copied into another repo.
[ -f "$AG/.gitignore" ]    || printf '*\n' > "$AG/.gitignore"
[ -f "$MEDIA/.gitignore" ] || printf '*\n' > "$MEDIA/.gitignore"

# --- gitignore: layer 2, the project root (idempotent) ----------------------
GI="$ROOT/.gitignore"
if ! grep -qs '^claude-agents/$' "$GI" 2>/dev/null; then
  { [ -s "$GI" ] && [ -n "$(tail -c1 "$GI")" ] && echo; } >> "$GI" 2>/dev/null
  {
    echo "# ceo-team agents: memory and scratch never leave the machine"
    echo "claude-agents/"
    echo "claude-media-agents/"
    grep -qs '^\.claude/$' "$GI" || echo ".claude/"
  } >> "$GI"
fi

# --- decide: survey or replay ----------------------------------------------
NEED_SURVEY=1
if [ -f "$SESSION" ]; then
  grep -q "^DATE: $TODAY\$" "$SESSION" && NEED_SURVEY=0
fi

if [ "$QUIET" = 1 ]; then
  # Разворачивание уже произошло выше. Говорим, только если есть о чём.
  [ "$FRESH" = 1 ] && echo "[ceo-team] Рабочие папки развёрнуты: claude-agents/, claude-media-agents/."
  # Пользователь зовёт руководителя, а конфигурации сессии нет. Субагент не может
  # показать опрос сам — AskUserQuestion ему недоступен, поэтому просим об этом
  # основную сессию, пока задача ещё не ушла агенту.
  if [ "$NEED_SURVEY" = 1 ] && printf '%s' "$PROMPT" | grep -qi 'ceo'; then
    echo "[ceo-team] Конфигурация сессии не задана (claude-agents/SESSION.md отсутствует или от другой даты)."
    echo "[ceo-team] Выполните /start до передачи задачи агенту: три вопроса — многозадачность, состав команды, модели."
    echo "[ceo-team] Затем повторите обращение к ceo-agent. Если пользователь отказывается — ceo-agent возьмёт значения по умолчанию."
  fi
  exit 0
fi

# Status line only. This hook reports state; it does not direct the session.
echo "[ceo-team] Плагин активен. Работа ведётся через @ceo-agent."
[ "$FRESH" = 1 ] && echo "[ceo-team] Созданы claude-agents/ и claude-media-agents/, .gitignore дополнен."

if [ "$NEED_SURVEY" = 1 ]; then
  echo "[ceo-team] Конфигурация сессии не задана. Настроить составом команды и моделями: /start"
else
  echo -n "[ceo-team] Конфигурация: "
  grep -E '^(MULTITASK|AGENTS|MODEL|EFFORT):' "$SESSION" 2>/dev/null | tr '\n' ' '
  echo
fi
exit 0
