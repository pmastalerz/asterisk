#!/usr/bin/env bash
# Smoke-test a built Asterisk image:
#   - start, wait for CLI
#   - version + PJSIP + SRTP present
#   - healthcheck script runs
#   - documentation seed works on empty /var/lib/asterisk bind
#   - envsubst renders *.conf.template
#   - ASTERISK_TERMINAL_OPTS is honored (swaps `-W` in CMD)
#   - Asterisk process dropped privileges to the asterisk user
set -euo pipefail

IMAGE="${1:?usage: smoke-test.sh <image>}"
NAME="asterisk-smoke-$$"
ASTERISK_VERSION="$(tr -d '[:space:]' < "$(dirname "$0")/../VERSION")"
TMPLIB=""
TMPCFG=""

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  [ -n "$TMPLIB" ] && rm -rf "$TMPLIB" >/dev/null 2>&1 || true
  [ -n "$TMPCFG" ] && rm -rf "$TMPCFG" >/dev/null 2>&1 || true
}
trap cleanup EXIT

MOUNTS=()

# Images with seed-varlib must start on an empty /var/lib/asterisk bind (Unraid case).
if docker run --rm --entrypoint test "$IMAGE" -x /app/seed-varlib.sh 2>/dev/null; then
  TMPLIB="$(mktemp -d)"
  MOUNTS+=(-v "${TMPLIB}:/var/lib/asterisk")
  echo "==> Using empty /var/lib/asterisk volume (documentation seed check)"
fi

# Drop a *.conf.template into /etc/asterisk to exercise the envsubst renderer.
if docker run --rm --entrypoint test "$IMAGE" -x /app/render-templates.sh 2>/dev/null; then
  TMPCFG="$(mktemp -d)"
  cat > "${TMPCFG}/smoke.conf.template" <<'TPL'
[general]
; rendered by smoke test
external_media_address=${SMOKE_EXTERNAL_IP}
TPL
  MOUNTS+=(-v "${TMPCFG}:/etc/asterisk")
  echo "==> Mounting template config dir (envsubst render check)"
fi

echo "==> Starting $IMAGE as $NAME"
docker run -d --name "$NAME" \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=UTC \
  -e SMOKE_EXTERNAL_IP=203.0.113.99 \
  -e ASTERISK_TERMINAL_OPTS="-n" \
  "${MOUNTS[@]}" \
  "$IMAGE" >/dev/null

echo "==> Waiting for Asterisk CLI"
ok=0
for _ in $(seq 1 60); do
  if docker exec "$NAME" asterisk -rx "core show version" >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 2
done

if [ "$ok" != "1" ]; then
  echo "ERROR: Asterisk did not become ready in time" >&2
  docker logs "$NAME" >&2 || true
  exit 1
fi

echo "==> core show version"
version_out="$(docker exec "$NAME" asterisk -rx "core show version")"
echo "$version_out"
echo "$version_out" | grep -F "Asterisk ${ASTERISK_VERSION}" >/dev/null

echo "==> module show like res_pjsip"
pjsip_out="$(docker exec "$NAME" asterisk -rx "module show like res_pjsip")"
echo "$pjsip_out"
echo "$pjsip_out" | grep -E 'res_pjsip(\.so)?[[:space:]]' >/dev/null

echo "==> module show like res_srtp"
srtp_out="$(docker exec "$NAME" asterisk -rx "module show like res_srtp")"
echo "$srtp_out"
echo "$srtp_out" | grep -E 'res_srtp(\.so)?[[:space:]]' >/dev/null

echo "==> healthcheck script"
docker exec "$NAME" test -x /healthcheck.sh
docker exec "$NAME" /healthcheck.sh

if [ -n "$TMPLIB" ]; then
  echo "==> seeded documentation present"
  docker exec "$NAME" test -f /var/lib/asterisk/documentation/core-en_US.xml
fi

if [ -n "$TMPCFG" ]; then
  echo "==> envsubst rendered smoke.conf"
  rendered="$(docker exec "$NAME" cat /etc/asterisk/smoke.conf 2>/dev/null || true)"
  echo "$rendered"
  echo "$rendered" | grep -F "external_media_address=203.0.113.99" >/dev/null
fi

echo "==> ASTERISK_TERMINAL_OPTS swapped -W (checking ps for -n, no -W)"
ps_out="$(docker exec "$NAME" ps -o args= -C asterisk 2>/dev/null || true)"
echo "$ps_out"
echo "$ps_out" | grep -Fv -- "-W" >/dev/null
echo "$ps_out" | grep -F -- "-n" >/dev/null

echo "==> Asterisk process is running as user 'asterisk' (privilege drop)"
whoami_out="$(docker exec "$NAME" sh -c "ps -o user= -C asterisk | head -n1 | tr -d ' '")"
echo "user: $whoami_out"
[ "$whoami_out" = "asterisk" ]

echo "OK: smoke tests passed for $IMAGE"
