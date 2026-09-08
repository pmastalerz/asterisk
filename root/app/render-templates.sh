#!/bin/sh
# Render /etc/asterisk/*.conf.template → /etc/asterisk/*.conf via envsubst.
#
# Only substitutes plain ${VAR} / $VAR references. Bash parameter expansions
# (${VAR:-default}, ${VAR%-*}, …) are NOT supported by envsubst.
#
# We regenerate on every container start. That means: if you ship a template,
# manual edits to the rendered .conf are overwritten. Edit the .template
# (or drop the template and ship the .conf directly).
set -eu

DIR=/etc/asterisk

command -v envsubst >/dev/null 2>&1 || exit 0
[ -d "$DIR" ] || exit 0

for tpl in "$DIR"/*.conf.template; do
  [ -e "$tpl" ] || continue
  dst="${tpl%.template}"
  echo "[template] $tpl -> $dst"
  envsubst < "$tpl" > "$dst"
done
