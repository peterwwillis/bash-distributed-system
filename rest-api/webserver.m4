#!/usr/bin/env bash
# vim: syntax=bash
set -eux
SCRIPTPATH="$(dirname "${BASH_SOURCE[0]}")"
HTTPD_PORT="${HTTPD_PORT:-8080}"
HTTPD_DOCDIR="${HTTPD_DOCDIR:-${SCRIPTPATH}}"

# Clear the environment, but add BINDIR to the PATH so CGI scripts can easily find our
# executables even if they're in a custom path
env -i PATH="_BINDIR_:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    busybox httpd -p "$HTTPD_PORT" -v -f -h "$HTTPD_DOCDIR"
