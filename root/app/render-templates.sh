#!/bin/sh
# Render /etc/asterisk/*.conf.template → /etc/asterisk/*.conf via envsubst.
#
# Only substitutes plain ${VAR} / $VAR references. Bash parameter expansions
# (${VAR:-default}, ${VAR%-*}, …) are NOT supported by envsubst.
#
# Rendering is idempotent-ish: we regenerate on every start when the template
# is newer than the rendered file (or when the rendered file is missing).
set -eu

DIR=/etc/asterisk

command -v envsubst >/dev/null 2>&1 || exit 0
[ -d "$DIR" ] || exit 0

for tpl in "$DIR"/*.conf.template; do
  [ -e "$tpl" ] || continue
  dst="${tpl%.template}"
  if [ ! -e "$dst" ] || [ "$tpl" -nt "$dst" ]; then
    echo "[template] $tpl -> $dst"
    envsubst < "$tpl" > "$dst"
  fi
done
