#!/bin/sh
# Container healthcheck — used by Docker HEALTHCHECK and Unraid.
set -eu
asterisk -rx "core show version" >/dev/null 2>&1
