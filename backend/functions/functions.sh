#!/usr/bin/env bash
set -eu
[ "${DEBUG:-0}" = "1" ] && set -x

# Notes:
#  - Where you see 'declare -n', it's using a 'nameref', which is like a pointer.

__error () { echo "$0: Error: $*" ; exit 1 ; } ;

### Description: Take a JSON string and create a bash associative array
### Usage: __load_json_to_aa JSON_STRING AA_NAME
__load_json_to_aa () {
    local jsonstring="$1" arrayname="$2"
    declare -n aaptr=$arrayname
    while IFS="=" read -r key value ; do
        aaptr["$key"]="$value"
    done < <(jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' <<< "$jsonstring")
}

### Description: Take a Bash associative array $1 and dump it as a JSON document
### Usage: __dump_aa_to_json AA_NAME
__dump_aa_to_json () {
    declare -n aaptr="$1"
    local outstr="{" value
    for arg in ${!aaptr[@]} ; do
        value="${aaptr[$arg]}"
        outstr="$outstr\"$(__json_fmt_str "$arg")\": \"$(__json_fmt_str "$value")\", "
    done
    outstr="${outstr::-2}""}" # remove final comma-space, add closing bracket
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

### Description: Call function '${1}_${2}' and pass it the name of that new
###              function as well as the rest of the arguments. Enables automatic
###              calling of child functions.
__run_subcommand () {
    local self cmd
    self="$1" cmd="$2"; shift 2
    "${self}_${cmd}" "${self}_${cmd}" "$@"
}

### Description: Make parent directories for a file
__mkdirp_f () {
    for file in "$@" ; do
        mkdir -p "$(dirname "$file")"
    done
}

### Description: Read a file into a variable
__readfile_var () {
    local file="$1" var="$2"; shift 2
    [ "$file" = "-" ] && file="/dev/stdin"
    set +e # FIXME: I don't know why it's dying without this
    IFS='' read -r "${var?}" < "$file"
    set -e
}

__usage () {
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
