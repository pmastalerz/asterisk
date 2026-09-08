#!/bin/sh
# Container entrypoint.
#
# Order matters:
#   1. Render *.conf.template → *.conf via envsubst (before seeding, so a
#      rendered file counts as "already there" for the seed step).
#   2. Seed missing /etc/asterisk and /var/lib/asterisk files from defaults.
#   3. Reconcile UID/GID with PUID/PGID and chown mutable dirs.
#   4. Swap the `-W` placeholder in CMD args for ASTERISK_TERMINAL_OPTS if set.
#   5. exec asterisk.
set -eu

/app/render-templates.sh
/app/seed-config.sh
/app/seed-varlib.sh

uid="${PUID:-1000}"
gid="${PGID:-1000}"

if id asterisk >/dev/null 2>&1; then
  groupmod -o -g "$gid" asterisk 2>/dev/null || true
  usermod -o -u "$uid" asterisk 2>/dev/null || true
fi

mkdir -p \
  /etc/asterisk \
  /var/lib/asterisk \
  /var/lib/asterisk/db \
  /var/lib/asterisk/keys \
  /var/lib/asterisk/sounds \
  /var/log/asterisk \
  /var/spool/asterisk/monitor \
  /var/run/asterisk

chown -R "${uid}:${gid}" \
  /etc/asterisk \
  /var/lib/asterisk \
  /var/log/asterisk \
  /var/spool/asterisk \
  /var/run/asterisk \
  2>/dev/null || true

# Optional extra CLI flags without rebuilding, e.g. ASTERISK_ARGS="-g"
if [ "${1:-}" = "asterisk" ] && [ -n "${ASTERISK_ARGS:-}" ]; then
  cmd="$1"
  shift
  # Intentional word-splitting for CLI flags.
  # shellcheck disable=SC2086
  set -- "$cmd" $ASTERISK_ARGS "$@"
fi

# ASTERISK_TERMINAL_OPTS: swap the `-W` placeholder token in CMD for whatever
# the user asked for (may be empty to drop -W entirely, "-B" for dark bg, "-n"
# for no color, or arbitrary flags).
if [ "${1:-}" = "asterisk" ] && [ "${ASTERISK_TERMINAL_OPTS+set}" = "set" ]; then
  cmd="$1"
  shift
  new=""
  swapped=0
  for arg in "$@"; do
    if [ "$arg" = "-W" ] && [ "$swapped" = "0" ]; then
      # word-split ASTERISK_TERMINAL_OPTS
      for tok in $ASTERISK_TERMINAL_OPTS; do
        new="$new $tok"
      done
      swapped=1
    else
      new="$new $arg"
    fi
  done
  # shellcheck disable=SC2086
  set -- "$cmd" $new
fi

echo "Starting Asterisk ${ASTERISK_VERSION:-unknown} (image ${VERSION:-dev})..."
exec "$@"
