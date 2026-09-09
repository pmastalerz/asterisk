#!/usr/bin/env bash
# Detect the latest Asterisk release in a given LTS/Standard branch (e.g. 22)
# and, if it differs from what this repo pins, rewrite VERSION,
# ASTERISK_SHA256, and the README badge in-place.
#
# Writes GitHub Actions outputs (`$GITHUB_OUTPUT`) when running in CI:
#   changed=true|false
#   version=<new>
#   previous=<old>
#   sha256=<new>
#
# Usage: check-upstream.sh <major-branch>
#   e.g. check-upstream.sh 22
set -euo pipefail

BRANCH="${1:?usage: check-upstream.sh <major-branch>  (e.g. 22)}"
INDEX_URL="https://downloads.asterisk.org/pub/telephony/asterisk/"

echo "==> Fetching upstream index for branch ${BRANCH}.x"
INDEX="$(curl -fsSL "$INDEX_URL")"

# Newest asterisk-BRANCH.x.y.tar.gz (skip .sha256/.md5/.asc siblings).
LATEST_FILE="$(printf '%s\n' "$INDEX" \
  | grep -oE "asterisk-${BRANCH}\.[0-9]+\.[0-9]+\.tar\.gz" \
  | grep -vE 'sha256|md5|asc' \
  | sort -uV \
  | tail -n1)"

if [ -z "$LATEST_FILE" ]; then
  echo "ERROR: no asterisk-${BRANCH}.x.y.tar.gz found in upstream index" >&2
  exit 1
fi

NEW_VERSION="$(echo "$LATEST_FILE" \
  | sed -E "s/asterisk-(${BRANCH}\.[0-9]+\.[0-9]+)\.tar\.gz/\1/")"

echo "==> Latest upstream: ${NEW_VERSION}"

# downloads.asterisk.org publishes checksum files without the ".tar.gz" segment,
# i.e. `asterisk-22.11.0.sha256` (not `asterisk-22.11.0.tar.gz.sha256`).
NEW_SHA="$(curl -fsSL "${INDEX_URL}${LATEST_FILE%.tar.gz}.sha256" | awk 'NR==1{print $1}')"

if [ -z "$NEW_SHA" ]; then
  echo "ERROR: could not read sha256 for ${LATEST_FILE}" >&2
  exit 1
fi

CURRENT_VERSION="$(tr -d '[:space:]' < VERSION)"
CURRENT_SHA="$(tr -d '[:space:]' < ASTERISK_SHA256)"

emit() {
  key="$1"
  value="$2"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "${key}=${value}" >> "$GITHUB_OUTPUT"
  fi
  echo "${key}=${value}"
}

if [ "$NEW_VERSION" = "$CURRENT_VERSION" ] && [ "$NEW_SHA" = "$CURRENT_SHA" ]; then
  echo "==> Already up to date at ${CURRENT_VERSION}"
  emit changed false
  emit version "$CURRENT_VERSION"
  emit previous "$CURRENT_VERSION"
  emit sha256 "$CURRENT_SHA"
  exit 0
fi

echo "==> Update: ${CURRENT_VERSION} -> ${NEW_VERSION}"
printf '%s\n' "$NEW_VERSION" > VERSION
printf '%s\n' "$NEW_SHA" > ASTERISK_SHA256

# README badge: `Asterisk-<version>-orange`
if [ -f README.md ]; then
  esc_current="$(printf '%s' "$CURRENT_VERSION" | sed 's/\./\\./g')"
  sed -i.bak -E "s|Asterisk-${esc_current}-orange|Asterisk-${NEW_VERSION}-orange|g" README.md \
    && rm -f README.md.bak
fi

emit changed true
emit version "$NEW_VERSION"
emit previous "$CURRENT_VERSION"
emit sha256 "$NEW_SHA"
