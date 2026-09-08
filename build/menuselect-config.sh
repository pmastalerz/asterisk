#!/bin/sh
# Goals for a modern, general-purpose Asterisk image:
#   - PJSIP stack (bundled pjproject from ./configure)
#   - SRTP / DTLS-SRTP
#   - HTTP WebSocket transport hooks
#   - portable binaries (no BUILD_NATIVE)
#   - no bundled sound packs (keeps builds fast / images smaller)
#   - no legacy chan_sip, no ODBC (keeps logs/deps clean)
#
# Optional modules are enabled only when present in this Asterisk version
# (unknown names are skipped so bumps of VERSION stay resilient).
#
# Usage (from Asterisk source tree after `make menuselect.makeopts`):
#   menuselect-config.sh menuselect.makeopts
set -eu

opts="${1:?menuselect.makeopts path required}"

if [ ! -x menuselect/menuselect ]; then
  echo "menuselect binary missing — run make menuselect.makeopts first" >&2
  exit 1
fi

ms() {
  menuselect/menuselect "$@" "${opts}"
}

try_enable() {
  name="$1"
  if ms --enable "${name}" >/dev/null 2>&1; then
    echo "menuselect: enable ${name}"
  else
    echo "menuselect: skip ${name} (not in this tree)"
  fi
}

try_disable() {
  name="$1"
  if ms --disable "${name}" >/dev/null 2>&1; then
    echo "menuselect: disable ${name}"
  else
    echo "menuselect: skip disable ${name}"
  fi
}

try_disable_category() {
  name="$1"
  if ms --disable-category "${name}" >/dev/null 2>&1; then
    echo "menuselect: disable-category ${name}"
  else
    echo "menuselect: skip disable-category ${name}"
  fi
}

# Required / strongly expected for this image profile.
ms --disable BUILD_NATIVE
ms --enable res_srtp

# Sound packs and MP3 add large downloads / build time; mount sounds at runtime if needed.
try_disable format_mp3
try_disable_category MENUSELECT_CORE_SOUNDS
try_disable_category MENUSELECT_MOH
try_disable_category MENUSELECT_EXTRA_SOUNDS

# Softphone / WebRTC-friendly (enable when available).
try_enable res_http_websocket
try_enable res_pjsip_transport_websocket
try_enable res_crypto
try_enable res_stun_monitor
try_enable codec_speex
try_enable codec_g722
try_enable format_ogg_vorbis
try_enable bridge_native_rtp
try_enable bridge_simple

# Keep the image PBX-focused; telephony hardware / desktop audio not needed in Docker.
try_disable chan_sip
try_disable chan_skinny
try_disable chan_mgcp
try_disable chan_unistim
try_disable chan_alsa
try_disable chan_oss
try_disable chan_console

# No ODBC in the default image — keeps runtime deps and logs clean.
try_disable res_odbc
try_disable res_odbc_transaction
try_disable res_config_odbc
try_disable cdr_odbc
try_disable cdr_adaptive_odbc
try_disable cel_odbc
try_disable func_odbc

echo "menuselect profile applied -> ${opts}"
