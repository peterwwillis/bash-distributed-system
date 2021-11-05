#!/usr/bin/env bash

### Local State functions

### Usage: __state_save_aa_json PROGRAM PATH FILENAME ASSOCIATIVEARRAY
__state_local_save_aa_json () {
    local program="$1" path="$2" file="$3" array_name="$4" ; shift 4
    local state_file
    state_file="$STATE_DIR/$program/$path/$file"
    #__state_lock "$program" "$path" "$file"
    # Write to a temp file and then move to a regular state file.
    # This avoids reads of a file during write, regardless of lock status
    __mkdirp_f "$state_file" # Make sure all the dirs exist
    __dump_aa_to_json "$array_name" > "$state_file.tmp"
    if ! ln "$state_file.tmp" "$state_file" ; then
        rm -f "$state_file.tmp"
        __error "Could not move $state_file.tmp to $state_file"
    fi
    rm -f "$state_file.tmp"
    #__state_unlock "$program" "$path" "$file"
}

### Usage: __state_load_json_aa PROGRAM PATH FILENAME ASSOCIATIVEARRAY
__state_local_load_json_aa () {
    local program="$1" path="$2" file="$3" ; shift 3
    local arrayname="$1" data ; shift
    data="$(cat "$STATE_DIR/$program/$path/$file")"
    __load_json_to_aa "$data" "$arrayname"
}

### Usage: __state_acquire PROGRAM PATH FILENAME
__state_local_acquire () {
    local program="$1" path="$2" file="$3" ; shift 3
    local state_file="$STATE_DIR/$program/$path/$file"
    # If the link works, only our process has access to this file.
    if ! ln "$state_file" "$state_file.cur" ; then
        __error "Could not get lock on $state_file"
    fi
    # Even if the old file was being accessed by another program, we already created the .cur
    # lock file above, so an attempt to create it by any other process will fail.
    # So we effectively have a rudimentary lock on both the old and current file.
    # 
    # Now we remove the old file (which is safe) so no more processes will attempt to lock the file.
    # 
    # FIXME: This does not account for if our program dies after acquiring a lock.
    # TODO:  Handle stale locks.
    rm -f "$state_file"
    printf "%s\n" "$state_file.cur"
}

### Description: List the available state
### Usage: __state_list PROGRAM PATH [FILENAME]
__state_local_list () {
    local program="$1" path="$2" file="${3:-}" ; shift 3
    # Remove any .tmp or .cur files that are used as part of file locking.
    # bash glob negation magic happening here...
    compgen -G "$STATE_DIR/$program/$path/${file:-}!(*.tmp|*.cur)"
}

