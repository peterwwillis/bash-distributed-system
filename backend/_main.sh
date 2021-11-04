#!/usr/bin/env bash
set -eu
[ "${DEBUG:-0}" = "1" ] && set -x

STATE_DIR="${STATE_DIR:-state}"
NODE_NAME="${NODE_NAME:-localhost}"
PROGRAM="$( basename "$0" | tr -C -d 'a-zA-Z0-9_-' )" # sanitize CGI var

__error () { echo "$0: Error: $*" ; exit 1 ; }

# Take a JSON file and create a bash associative array
__load_json_to_aa () {
    local arrayname="$1" jsonfile="$2"
    declare -A $arrayname
    while IFS="=" read -r key value
    do
        $arrayname[$key]="$value"
    done < <(jq -r 'to_entries|map("(.key)=(.value)")|.[]' "$jsonfile")
}

# Take a Bash associative array $1 and dump it as a JSON document
__dump_aa_to_json () {
    local arrayname="$1"
    local outstr
    for arg in "${!$arrayname[@]}" ; do
        outstr="\"$(__json_fmt_str "$arg")\": \"$(__json_fmt_str "${arrayname[$arg]}")\","
    done
    outstr="${outstr::-1}" # remove final comma
    outstr="$outstr""}"
}
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

__run_subcommand () {
    local cmd="$1"; shift # the current command, not the next one
    if    [ $# -gt 0 ] && [ "$(type -t "_${PROGRAM}_${1}")" = "function" ]
    then  
          _${PROGRAM}_${arg} "$@"
    else
          __error "No subcommand '${1:-}' exists"
          __usage
    fi
}

__state_save () {
    


##### main program ######
while getopts "j:hv" args ; do
    case $args in
        j)  IFS='' read -r JSON_FILE_DATA < "$OPTARG" ;; # Load JSON file
        h)  SHOW_HELP=1 ;;
        v)  export DEBUG=1 ;;
        *)  echo "$0: Error: unknown option $args" ;
            exit 1 ;;
    esac
done
shift $(($OPTIND-1))
[ $SHOW_HELP -eq 1 ] && _usage
__run_subcommand "$@"
