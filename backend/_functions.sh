#!/usr/bin/env bash
set -eu
[ "${DEBUG:-0}" = "1" ] && set -x

__error () { echo "$0: Error: $*" ; exit 1 ; } ;

### Description: Take a JSON string and create a bash associative array
### Usage: __load_json_to_aa JSON_STRING AA_NAME
__load_json_to_aa () {
    local jsonstring="$1" arrayname="$2"
    declare -n aaptr=$arrayname
    while IFS="=" read -r key value ; do
        #eval "${aaptr}[\"$key\"]=\"${value//\"/\\\"}\""
        echo "key '$key' value '$value'" 1>&2
        aaptr["$key"]="$value"
    done < <(jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' <<< "$jsonstring")
}

### Description: Take a Bash associative array $1 and dump it as a JSON document
### Usage: __dump_aa_to_json AA_NAME
__dump_aa_to_json () {
    declare -n aaptr="$1"
    local outstr="{" value
    for arg in ${!aaptr[@]} ; do
        echo "arg '$arg'" 1>&2
        value="${aaptr[$arg]}"
        echo "value '$value'" 1>&2
        outstr="$outstr\"$(__json_fmt_str "$arg")\": \"$(__json_fmt_str "$value")\", "
    done
    outstr="${outstr::-2}" # remove final comma-space
    outstr="$outstr""}"
    printf "%s\n" "$outstr"
}

### Description: Escape a string for use in a JSON document
### Usage: STRING=`__json_fmt_str STRING`
__json_fmt_str () {
    local str="$1"
    str=${str//\\/\\\\} # \ 
    str=${str//\//\\\/} # / 
    str=${str//\'/\\\'} # ' (not strictly needed ?)
    str=${str//\"/\\\"} # " 
    str=${str//   /\\t} # \t (tab)
    str=${str//
/\\\n} # \n (newline)
    str=${str//^M/\\\r} # \r (carriage return)
    str=${str//^L/\\\f} # \f (form feed)
    str=${str//^H/\\\b} # \b (backspace)
    printf "%s\n" "$str"
}

### Description: Check if a function exists called '_${PROGRAM}_$1, and if it does,
###              remove $1 and pass the rest of the arguments to the function,
###              or die with an error.
### Usage:       __run_subcommand "$@"
__run_subcommand () {
    local self cmd
    self="$1" cmd="$2"; shift 2
    "${self}_${cmd}" "${self}_${cmd}" "$@"
}

__state_save () {
    false
}

### Description: Make parent directories for a file
__mkdirp_f () {
    for file in "$@" ; do
        mkdir -p "$(dirname "$file")"
    done
}

### Usage: __state_save_aa_json ASSOCIATIVEARRAY PROGRAM PATH FILENAME 
__state_save_aa_json () {
    local program="$1" path="$2" file="$3" array_name="$4" ; shift 4
    local state_file
    if [ "$STATE_STORAGE" = "local" ] ; then
        state_file="$STATE_DIR/$program/$path/$file"
        __mkdirp_f "$state_file"
        __dump_aa_to_json "$array_name" > "$state_file"
    else
        __error "state_save_aa_json: Invalid STATE_STORAGE"
    fi
}

__state_load_json_aa () {
    local program="$1" path="$2" file="$3" ; shift 3
    local arrayname="$1" data ; shift
    if [ "$STATE_STORAGE" = "local" ] ; then
        data="$(cat "$STATE_DIR/$program/$path/$file")"
        __load_json_to_aa "$data" "$arrayname"
    else
        __error "state_load_json_aa: Invalid STATE_STORAGE"
    fi
}


### Description: Read a file into a variable
__readfile_var () {
    local file="$1" var="$2"; shift 2
    [ "$file" = "-" ] && file="/dev/stdin"
    set +e
    IFS='' read -r "${var?}" < "$file"
    set -e
}

