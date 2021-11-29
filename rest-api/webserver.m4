#!/usr/bin/env bash
# vim: syntax=bash
set -eux
SCRIPTPATH="$(dirname "${BASH_SOURCE[0]}")"
HTTPD_PORT="${HTTPD_PORT:-8080}"
HTTPD_DOCDIR="${HTTPD_DOCDIR:-${SCRIPTPATH}}"

env -i busybox httpd -p "$HTTPD_PORT" -v -f -h "$HTTPD_DOCDIR"
