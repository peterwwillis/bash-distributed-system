#!/usr/bin/env bash

STATE_STORAGE="local"
STATE_DIR="${STATE_DIR:-state}"
NODE_NAME="${NODE_NAME:-localhost}"
PROGRAM="$( basename "$0" .sh | tr -C -d 'a-zA-Z0-9_-' )" # sanitize CGI var

# load _functions.sh
scriptdir="$(dirname "${BASH_SOURCE[0]}")"
. "$scriptdir/_functions.sh"

##### main program ######
SHOW_HELP=0
while getopts "j:hv" args ; do
    case $args in
        j)  __readfile_var "$OPTARG" JSON_FILE_DATA ;; # Load JSON data
        h)  SHOW_HELP=1 ;;
        v)  export DEBUG=1 ;;
        *)  echo "$0: Error: unknown option $args" ;
            exit 1 ;;
    esac
done
shift $(($OPTIND-1))

if [ $SHOW_HELP -eq 1 ] || [ $# -lt 1 ] ; then
    _usage
fi
__run_subcommand "_${PROGRAM}" "$@"
