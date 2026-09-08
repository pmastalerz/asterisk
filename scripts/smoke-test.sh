#!/usr/bin/env bash
# Smoke-test a built Asterisk image: start, wait for health, verify version + PJSIP.
set -euo pipefail

IMAGE="${1:?usage: smoke-test.sh <image>}"
NAME="asterisk-smoke-$$"
ASTERISK_VERSION="$(tr -d '[:space:]' < "$(dirname "$0")/../VERSION")"

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Starting $IMAGE as $NAME"
docker run -d --name "$NAME" \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=UTC \
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
if docker exec "$NAME" test -x /healthcheck.sh; then
  docker exec "$NAME" /healthcheck.sh
else
  echo "(image has no /healthcheck.sh yet — CLI readiness already verified)"
fi

echo "OK: smoke tests passed for $IMAGE"
