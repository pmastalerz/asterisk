# Prefer packaging overlays; fill remaining gaps from Asterisk sample tree.
set -eu

DST=/etc/asterisk
mkdir -p "$DST"

seed_from() {
  src="$1"
  [ -d "$src" ] || return 0
  for f in "$src"/*; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    if [ ! -e "$DST/$base" ]; then
      echo "[seed] $base <- $src"
      cp -a "$f" "$DST/$base"
    fi
  done
}

# Overlays first (asterisk.conf / logger / rtp / modules), then official samples.
seed_from /defaults/asterisk
seed_from /etc/asterisk.default
