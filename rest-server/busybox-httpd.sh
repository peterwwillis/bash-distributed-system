#!/usr/bin/env sh
set -eux
HTTPD_PORT="${HTTPD_PORT:-8080}"
HTTPD_DOCDIR="${HTTPD_DOCDIR:-htdocs}"
env -i busybox httpd -p "$HTTPD_PORT" -v -f -h "$HTTPD_DOCDIR"
