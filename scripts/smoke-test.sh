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
  if [ -n "$TMPLIB" ]; then rm -rf "$TMPLIB" >/dev/null 2>&1 || true; fi
  if [ -n "$TMPCFG" ]; then rm -rf "$TMPCFG" >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT

MOUNTS=()

# --- Capability detection (skip forward-looking asserts on older images) ---
HAS_PS=false
if docker run --rm --entrypoint /bin/sh "$IMAGE" -c "command -v ps >/dev/null" 2>/dev/null; then
  HAS_PS=true
fi

HAS_TERMINAL_OPTS=false
HAS_PRIV_DROP=false
default_cmd="$(docker inspect --format '{{join .Config.Cmd " "}}' "$IMAGE" 2>/dev/null || true)"
if echo "$default_cmd" | grep -qE '(^| )-W( |$)'; then
  HAS_TERMINAL_OPTS=true
fi
if echo "$default_cmd" | grep -qF -- "-U asterisk"; then
  HAS_PRIV_DROP=true
fi
echo "==> capabilities: ps=$HAS_PS  terminal_opts=$HAS_TERMINAL_OPTS  priv_drop=$HAS_PRIV_DROP"

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

if $HAS_TERMINAL_OPTS && $HAS_PS; then
  echo "==> ASTERISK_TERMINAL_OPTS swapped -W (checking args for -n, no -W)"
  ps_out="$(docker exec "$NAME" ps -o args= -C asterisk 2>/dev/null || true)"
  echo "$ps_out"
  if echo "$ps_out" | grep -F -- "-W" >/dev/null; then
    echo "ERROR: '-W' still present in asterisk args (ASTERISK_TERMINAL_OPTS not honored)" >&2
    exit 1
  fi
  if ! echo "$ps_out" | grep -F -- "-n" >/dev/null; then
    echo "ERROR: '-n' missing from asterisk args (ASTERISK_TERMINAL_OPTS not applied)" >&2
    exit 1
  fi
else
  echo "==> skip terminal-opts check (image lacks -W placeholder in CMD or /bin/ps)"
fi

if $HAS_PRIV_DROP && $HAS_PS; then
  echo "==> Asterisk process is running as user 'asterisk' (privilege drop)"
  user_out="$(docker exec "$NAME" sh -c "ps -o user= -C asterisk | head -n1 | tr -d ' '")"
  echo "user: $user_out"
  if [ "$user_out" != "asterisk" ]; then
    echo "ERROR: expected asterisk user, got '$user_out'" >&2
    exit 1
  fi
else
  echo "==> skip priv-drop check (image lacks '-U asterisk' in CMD or /bin/ps)"
fi

echo "OK: smoke tests passed for $IMAGE"
