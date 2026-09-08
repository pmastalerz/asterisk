#!/bin/sh
set -eu

/app/seed-config.sh

uid="${PUID:-1000}"
gid="${PGID:-1000}"

if id asterisk >/dev/null 2>&1; then
  groupmod -o -g "$gid" asterisk 2>/dev/null || true
  usermod -o -u "$uid" asterisk 2>/dev/null || true
fi

mkdir -p \
  /etc/asterisk \
  /var/lib/asterisk \
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

echo "Starting Asterisk ${ASTERISK_VERSION:-unknown} (image ${VERSION:-dev})..."
exec "$@"
