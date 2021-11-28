#!/usr/bin/env bash
# vim: syntax=bash
set -eu
[ "${DEBUG:-0}" = "1" ] && set -x

# Notes:
#  - Where you see 'declare -n', it's using a 'nameref', which is like a pointer.

# shellcheck disable=SC2059
_f_error () { printf "$0: Error: $*\n" ; exit 1 ; } ;

### Description: Take a JSON string and create a bash associative array
_f_load_json_to_aa () {
    [ $# -ne 2 ] && _f_error "Usage: $0 _f_load_json_to_aa ASSOCIATIVEARRAY JSON_STRING"
    local arrayname="$1" jsonstring="$2"
    declare -n aaptr=$arrayname
    while IFS="=" read -r key value ; do
        aaptr["$key"]="$value"
    done < <(jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' <<< "$jsonstring")
}

### Description: Take a Bash associative array $1 and dump it as a JSON document
### Usage: _f_dump_aa_to_json AA_NAME
_f_dump_aa_to_json () {
    # FIXME: apparently the following should not work, because arrays can't be
    #        used with pointers? find out if this is working or not?
    # shellcheck disable=SC2178
    declare -n aaptr="$1"
    local outstr="{" value
    for arg in "${!aaptr[@]}" ; do
        value="${aaptr[$arg]}"
        outstr="$outstr\"$(_f_json_fmt_str "$arg")\": \"$(_f_json_fmt_str "$value")\", "
    done
    outstr="${outstr::-2}""}" # remove final comma-space, add closing bracket
    printf "%s\n" "$outstr"
}

### Save an associative array to a JSON document in state.
_f_state_save_aa_json () {
    [ $# -ne 4 ] && _f_error "Usage: $0 save_aa_json ASSOCIATIVEARRAY NAMESPACE PATH FILENAME"
    local array_name="$1" namespace="$2" path="$3" file="$4" ; shift 4
    _f_dump_aa_to_json "$array_name" | _BIN_STATE_ write "$namespace" "$path" "$file"
    # FIXME: check for pipe status return
}

### Load a JSON document from state into an associative array.
_f_state_load_json_aa () {
    [ $# -ne 4 ] && _f_error "Usage: $0 load_json_aa ASSOCIATIVEARRAY NAMESPACE PATH FILENAME"
    local arrayname="$1" namespace="$2" path="$3" file="$4" data ; shift 4
    if ! _BIN_STATE_ stat -q "$namespace" "$path" "$file" ; then
        echo "$0: _f_state_load_json_aa: state file '$namespace' '$path' '$file'  does not exist"
        return 1
    fi
    # FIXME: make sure we check the status of this command call
    data="$(_BIN_STATE_ read "$namespace" "$path" "$file")"
    _f_load_json_to_aa "$arrayname" "$data"
}

### Load environment variables from json file (read from STDIN).
### Usage: _f_load_env_from_json <<< "${JSON_DOCUMENT}"
_f_load_env_from_json () {
    eval "$(jq -e -r ".environment | to_entries|map(\"\(.key)='\(.value|tostring)'\")|.[]")"
}


### Escape a string for use in a JSON document.
### Usage: STRING=`_f_json_fmt_str STRING`
_f_json_fmt_str () {
    local str="$1"
    str=${str//\\/\\\\} # \ 
    str=${str//\//\\\/} # / 
    str=${str//\'/\\\'} # ' (not strictly needed ?)
    str=${str//\"/\\\"} # " 
    str=${str//	/\\t} # \t (tab)
    str=${str//
/\\\n} # \n (newline)
    str=${str//^M/\\\r} # \r (carriage return)
    str=${str//^L/\\\f} # \f (form feed)
    str=${str//^H/\\\b} # \b (backspace)
    printf "%s\n" "$str"
}

### Un-escape a string intended for use in a JSON document.
### Usage: STRING=`_f_json_unfmt_str STRING`
_f_json_unfmt_str () {
    local str="$1"
    str=${str//\\\b/^H} # \b (backspace)
    str=${str//\\\f/^L} # \f (form feed)
    str=${str//\\\r/^M} # \r (carriage return)
    str=${str//\\\n/
} # \n (newline)
    str=${str//	/\\t} # \t (tab)
    str=${str//\\\"/\"} # " 
    str=${str//\\\'/\'} # ' (not strictly needed ?)
    str=${str//\\\//\/} # / 
    str=${str//\\\\/\\} # \ 
    printf "%s\n" "$str"
}

### Description: Call function '${1}_${2}' and pass it the name of that new
###              function as well as the rest of the arguments. Enables automatic
###              calling of child functions.
_f_run_subcommand () {
    local self="$PARENT_CMD" cmd="$1"; shift
    PARENT_CMD="${self}_${cmd}"
    "${self}_${cmd}" "$@"
}

### Description: Make parent directories for a file
_f_mkdirp_f () {
    for file in "$@" ; do
        mkdir -p "$(dirname "$file")"
    done
}

### Description: Read a file into a variable
_f_readfile_var () {
    local file="$1" var="$2"; shift 2
    [ "$file" = "-" ] && file="/dev/stdin"
    set +e # FIXME: I don't know why it's dying without this
    IFS='' read -r "${var?}" < "$file"
    set -e
}

_f_usage () {
    echo "Usage: $0 COMMAND [..]"
    echo ""
    echo "Commands:"
    grep "$0" -e "^_${PROGRAM}_" | cut -d _ -f 3- | cut -d ' ' -f 1 | tr '_' ' ' | sort | sed -e 's/^/    /g'
    exit 1
}

# load functions in subdirectories
scriptdir="$(dirname "${BASH_SOURCE[0]}")"
for dir in "$scriptdir"/* ; do
    [ ! -d "$dir" ] && continue
    for file in "$dir"/*.sh ; do . "$file" ; done
done
