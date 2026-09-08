#!/bin/sh
# Seed /var/lib/asterisk from the image copy when bind mounts are empty.
# Empty Unraid/Docker volumes hide image content — without documentation/
# Asterisk fails Stasis init ("no existing documentation").
set -eu

SRC=/var/lib/asterisk.default
DST=/var/lib/asterisk

[ -d "$SRC" ] || exit 0
mkdir -p "$DST"

# Always ensure core XML docs exist (required to start).
if [ ! -f "$DST/documentation/core-en_US.xml" ]; then
  echo "[seed] documentation/ <- $SRC (required for Stasis)"
  rm -rf "$DST/documentation"
  cp -a "$SRC/documentation" "$DST/documentation"
fi

# Copy other missing top-level items (agi-bin, keys dir, etc.) without clobbering user data.
for item in "$SRC"/*; do
  [ -e "$item" ] || continue
  base=$(basename "$item")
  [ "$base" = "documentation" ] && continue
  if [ ! -e "$DST/$base" ]; then
    echo "[seed] /var/lib/asterisk/$base <- default"
    cp -a "$item" "$DST/$base"
  fi
done
