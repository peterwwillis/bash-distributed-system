#!/usr/bin/env bash
# vim: syntax=bash
set -eu
DEBUG=1
[ "${DEBUG:-0}" = "1" ] && set -x

# CGI variables:
#   - SCRIPT_NAME
#   - PATH_INFO
PROGRAM="$( basename "$SCRIPT_NAME" | tr -C -d 'a-zA-Z0-9_-' )" # sanitize CGI var
BACKEND="_BINPREFIX_$PROGRAM"

# Load CGI variables and functions
. "_RESTAPIDIR_/bash-cgi.sh"
declare -A cgi_get cgi_post
__cgi_getvars

# If PATH_INFO is '/jobs/add', run function '_cgi_${PROGRAM}_jobs_add $@'
path_info_func="$( printf "${PATH_INFO//\//_}" | tr -C -d 'a-zA-Z0-9_-' )" # sanitize CGI var
if [ "$(type -t _cgi_${PROGRAM}$path_info_func)" = "function" ] ; then
    _cgi_${PROGRAM}$path_info_func "$@"
else
    __httperror 404 "Not Found"
fi
