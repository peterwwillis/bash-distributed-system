#!/usr/bin/env bash

### Local State functions

### Save an associative array to a JSON document in state.
__state_local_save_aa_json () {
    [ $# -ne 4 ] && __error "Usage: $0 save_aa_json ASSOCIATIVEARRAY NAMESPACE PATH FILENAME"
    local array_name="$1" namespace="$2" path="$3" file="$4" ; shift 4
    local state_file="$STATE_DIR/$namespace/$path/$file"
    #__state_lock "$namespace" "$path" "$file"
    # Write to a temp file and then move to a regular state file.
    # This avoids reads of a file during write, regardless of lock status
    __mkdirp_f "$state_file" # Make sure all the dirs exist
    __dump_aa_to_json "$array_name" > "$state_file.tmp"
    if ! mv -f "$state_file.tmp" "$state_file" ; then
        rm -f "$state_file.tmp"
        __error "Could not link $state_file.tmp to $state_file"
    fi
    rm -f "$state_file.tmp"
    #__state_unlock "$namespace" "$path" "$file"
}

### Load a JSON document from state into an associative array.
__state_local_load_json_aa () {
    [ $# -ne 4 ] && __error "Usage: $0 load_json_aa ASSOCIATIVEARRAY NAMESPACE PATH FILENAME"
    local arrayname="$1" namespace="$2" path="$3" file="$4" data ; shift 4
    if ! __state stat "$namespace" "$path" "$file" >/dev/null 2>&1 ; then
        echo "$0: __state_local_load_json_aa: state file '$namespace' '$path' '$file'  does not exist"
        return 1
    fi
    data="$(cat "$STATE_DIR/$namespace/$path/$file")"
    __load_json_to_aa "$arrayname" "$data"
}

### Outputs state file to STDOUT.
__state_local_read () {
    [ $# -ne 3 ] && __error "Usage: $0 read NAMESPACE PATH FILENAME"
    local statepath="$STATE_DIR/$1/$2/$3"
    cat "$statepath"
}

### Takes STDIN and writes it to state.
__state_local_write () {
    [ $# -ne 3 ] && __error "Usage: $0 write NAMESPACE PATH FILENAME"
    local statepath="$STATE_DIR/$1/$2/$3"
    [ -d "$statepath" ] && __error "__state_local_write: '$statepath' is a directory, not a file"
    if [ ! -e "$statepath" ] ; then
        __mkdirp_f "$statepath"
    fi
    cat > "$statepath"
}

### Get stats about a state file
__state_local_stat () {
    [ $# -lt 1 -o $# -gt 3 ] && __error "Usage: $0 stat NAMESPACE [PATH [FILENAME]]"
    local statepath="$STATE_DIR"
    [ -n "${1:-}" ] && statepath="$statepath/$1"
    [ -n "${2:-}" ] && statepath="$statepath/$2"
    [ -n "${3:-}" ] && statepath="$statepath/$3"
    stat -t "$statepath"
}

### Usage: __state lock NAMESPACE PATH FILENAME
__state_local_lock () {
    [ $# -ne 3 ] && __error "Usage: $0 NAMESPACE PATH FILENAME"
    local statepath="$STATE_DIR/$1/$2/$3"
    # If the link works, only our process has access to this file.
    if ! ln -T "$statepath" "$statepath.lock" ; then
        __error "Could not get lock on $statepath"
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
    [ $# -ne 3 ] && __error "Usage: $0 unlock NAMESPACE PATH FILE"
    __state_local_remove "$1" "$2" "$3.lock"
}

### Usage: _state remove NAMESPACE PATH FILE
__state_local_remove () {
    [ $# -ne 3 ] && __error "Usage: $0 remove NAMESPACE PATH FILE"
    local statepath="$STATE_DIR/$1/$2/$3"
    if [ ! -e "$statepath" ] ; then
        __error "Could not find state file '$statepath'"
    fi
    if ! rm "$statepath" ; then
        __error "Could not remove state file '$statepath'"
    fi
}


### Description: List the available state
### Usage: __state list NAMESPACE PATH [FILENAME]
__state_local_list () {
    [ "${1:-}" = "-h" -o $# -gt 3 ] && __error "Usage: $0 list [NAMESPACE [PATH [FILENAME]]]"
    local namespace="${1:-}" path="${2:-}" file="${3:-}"
    local statepath="$STATE_DIR"
    [ -n "${1:-}" ] && statepath="$statepath/$1"
    [ -n "${2:-}" ] && statepath="$statepath/$2"
    [ -n "${3:-}" ] && statepath="$statepath/$3"
    ls "$STATE_DIR/$namespace/$path/$file" | grep -v -e "^.*\.tmp$|^.*\.lock$"
}

