#!/usr/bin/env bash

### Local State functions

### Outputs state file to STDOUT.
__state_local_read () {
    [ $# -ne 3 ] && _f_error "Usage: $0 read NAMESPACE PATH FILENAME"
    local statepath="$STATE_DIR/$1/$2/$3"
    cat "$statepath"
}

### Takes STDIN and writes it to state.
__state_local_write () {
    [ $# -ne 3 ] && _f_error "Usage: $0 write NAMESPACE PATH FILENAME"
    local statepath="$STATE_DIR/$1/$2/$3"
    [ -d "$statepath" ] && _f_error "__state_local_write: '$statepath' is a directory, not a file"
    if [ ! -e "$statepath" ] ; then
        _f_mkdirp_f "$statepath"
    fi
    cat > "$statepath.tmp"
    if ! mv -f "$statepath.tmp" "$statepath" ; then
        rm -f "$statepath.tmp"
        _f_error "Could not link $statepath.tmp to $statepath"
    fi
    rm -f "$statepath.tmp"
}

### Get stats about a state file
__state_local_stat () {
    local statepath="$STATE_DIR" stat_quiet=0
    while getopts "q" opt ; do
        case "$opt" in
            q)      stat_quiet=1 ;;
            *)      _f_error "$0: Wrong option to __state_local_stat: '$opt'" ;;
        esac
    done
    shift $((OPTIND-1))
    [ $# -lt 1 -o $# -gt 3 ] && _f_error "Usage: $0 stat [-q] NAMESPACE [PATH [FILENAME]]"

    [ -n "${1:-}" ] && statepath="$statepath/$1"
    [ -n "${2:-}" ] && statepath="$statepath/$2"
    [ -n "${3:-}" ] && statepath="$statepath/$3"

    if __state_local_list "${1:-}" "${2:-}" "${3:-}" >/dev/null 2>&1 ; then
        if [ $stat_quiet -eq 1 ] ; then
            stat -t "$statepath" >/dev/null
        else
            stat -t "$statepath"
        fi
    else
        if [ $stat_quiet -ne 1 ] ; then
            echo "$0: state '${1:-}' '${2:-}' '${3:-}' does not exist"
        fi
        return 1
    fi

}

### Usage: __state lock NAMESPACE PATH FILENAME
__state_local_lock () {
    [ $# -ne 3 ] && _f_error "Usage: $0 NAMESPACE PATH FILENAME"
    local statepath="$STATE_DIR/$1/$2/$3"
    # If the link works, only our process has access to this file.
    if ! ln -T "$statepath" "$statepath.lock" ; then
        _f_error "Could not get lock on $statepath"
    fi
    # Even if the old file was being accessed by another program, we already created
    # the .lock lock file above, so an attempt to create it by any other process will
    # fail. So we effectively have a rudimentary lock on both the old and current file.
    # 
    # Now we remove the old file (which is safe) so no more processes will attempt to lock the file.
    # 
    # FIXME: This does not account for if our program dies after acquiring a lock.
    # TODO:  Handle stale locks. Add something about who initiated the lock?
    #rm -f "$state_file"
    printf "%s\n" "$statepath.lock"
}

### Usage: _state unlock NAMESPACE PATH FILE
__state_local_unlock () {
    [ $# -ne 3 ] && _f_error "Usage: $0 unlock NAMESPACE PATH FILE"
    __state_local_remove "$1" "$2" "$3.lock"
}

### Usage: _state remove NAMESPACE PATH FILE
__state_local_remove () {
    [ $# -ne 3 ] && _f_error "Usage: $0 remove NAMESPACE PATH FILE"
    local statepath="$STATE_DIR/$1/$2/$3"
    if [ ! -e "$statepath" ] ; then
        _f_error "Could not find state file '$statepath'"
    fi
    if ! rm "$statepath" ; then
        _f_error "Could not remove state file '$statepath'"
    fi
}


### Description: List the available state
### Usage: __state list NAMESPACE PATH [FILENAME]
__state_local_list () {
    [ "${1:-}" = "-h" -o $# -gt 3 ] && _f_error "Usage: $0 list [NAMESPACE [PATH [FILENAME]]]"
    local namespace="${1:-}" path="${2:-}" file="${3:-}"
    local statepath="$STATE_DIR"
    [ -n "${1:-}" ] && statepath="$statepath/$1"
    [ -n "${2:-}" ] && statepath="$statepath/$2"
    [ -n "${3:-}" ] && statepath="$statepath/$3"
    ls "$STATE_DIR/$namespace/$path/$file" | grep -v -e "^.*\.tmp$|^.*\.lock$"
}

