#!/usr/bin/env bash
set -e -u
[ "${DEBUG:-0}" = "1" ] && set -x


_state_read () {
    __state read "$@"
}
_state_write () {
    __state write "$@"
}
_state_stat () {
    __state stat "$@"
}
_state_lock () {
    __state lock "$@"
}
_state_unlock () {
    __state unlock "$@"
}
_state_remove () {
    __state remove "$@"
}
_state_list () {
    __state list "$@"
}

# Run main program handler
scriptdir="$(dirname "${BASH_SOURCE[0]}")"
. "$scriptdir/functions/main.sh"
