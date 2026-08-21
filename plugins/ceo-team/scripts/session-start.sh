#!/usr/bin/env bash
# SessionStart hook for the ceo-team plugin.
# Deploys the working folders on first run, then either replays the session
# config (cheap) or asks Claude to run the survey (only when config is stale).
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
AG="$ROOT/claude-agents"
MEDIA="$ROOT/claude-media-agents"
SESSION="$AG/SESSION.md"
TPL="${CLAUDE_PLUGIN_ROOT:-}/template"
TODAY="$(date +%F)"
FRESH=0

# --- first deployment -------------------------------------------------------
if [ ! -d "$AG" ]; then
  FRESH=1
  mkdir -p "$AG/memory" "$AG/RECOVERY" "$MEDIA"
  for a in ceo manager frontend backend design researcher server security business memory; do
    mkdir -p "$AG/memory/$a-agent"
    [ -f "$AG/memory/$a-agent/INDEX.md" ] || \
      printf '# INDEX — %s-agent\n# one line per block: [tags] YYYY-MM-DD Title -> file\n' "$a" \
      > "$AG/memory/$a-agent/INDEX.md"
  done
  [ -d "$TPL" ] && for f in TO-DO-LIST.md READY-LIST.md; do
    [ -f "$TPL/$f" ] && [ ! -f "$AG/$f" ] && cp "$TPL/$f" "$AG/$f"
  done
  [ -f "$TPL/RECOVERY/MASTER.md" ] && [ ! -f "$AG/RECOVERY/MASTER.md" ] && \
    cp "$TPL/RECOVERY/MASTER.md" "$AG/RECOVERY/MASTER.md"
  printf '# media dump for agents — never committed\n' > "$MEDIA/.gitkeep"
fi

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
  } >> "$GI"
fi

# --- decide: survey or replay ----------------------------------------------
NEED_SURVEY=1
if [ -f "$SESSION" ]; then
  grep -q "^DATE: $TODAY\$" "$SESSION" && NEED_SURVEY=0
fi

echo "<ceo-team>"
[ "$FRESH" = 1 ] && echo "Развёрнуто: claude-agents/, claude-media-agents/, .gitignore обновлён."

if [ "$NEED_SURVEY" = 1 ]; then
  cat <<'MSG'
Конфигурация сессии отсутствует или устарела.
ACTION for Claude: before doing any work, run the /start survey (AskUserQuestion,
questions in Russian), then write the answers to claude-agents/SESSION.md.
Do not dispatch any agent until SESSION.md carries today's DATE.
MSG
else
  echo "Конфигурация сессии (claude-agents/SESSION.md):"
  grep -E '^(DATE|MULTITASK|AGENTS|MODEL|EFFORT):' "$SESSION" 2>/dev/null
  echo "Опрос не нужен. Работай через @ceo-agent."
fi
echo "</ceo-team>"
exit 0
