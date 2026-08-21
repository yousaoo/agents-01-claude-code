#!/usr/bin/env bash
# Собирает agents/*.md из manifests/.
# Источник правды — manifests/. Файлы в agents/ генерируются, руками их не правят.
# Конституция кладётся в тело агента ЦЕЛИКОМ: во время работы агент ничего не читает,
# значит не зависит от прав доступа к папке плагина.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
M="$HERE/manifests"; A="$HERE/agents"
[ -f "$M/_core.md" ] || { echo "нет $M/_core.md" >&2; exit 1; }

mkdir -p "$A"
n=0
for f in "$M"/*.md; do
  name="$(basename "$f" .md)"
  [ "$name" = "_core" ] && continue
  head -1 "$f" | grep -q '^---$' || { echo "нет frontmatter: $f" >&2; exit 1; }
  {
    awk '{print} /^---$/{c++; if(c==2) exit}' "$f"   # frontmatter целиком
    echo
    cat "$M/_core.md"                                 # общая конституция
    echo
    awk '/^---$/{c++; next} c>=2{print}' "$f"         # роль без frontmatter
  } > "$A/$name.md"
  n=$((n+1))
done
echo "собрано агентов: $n"
