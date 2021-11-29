#!/usr/bin/env bash
# vim: syntax=bash
DEFAULT_CONTENT_TYPE="text/plain"

# Credit for parts of this code goes to:
#  - Philippe Kehl <flipflip at oinkzwurgl dot org> and flipflip industries
#  - Parckwart <mail at parckwart dot de>

function __urldecode {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

function __cgi_getvars () {
    [ -n "${CONTENT_TYPE:-}" ] || return 0

    # Don't process JSON content
    if [ "$CONTENT_TYPE" = "application/json" ] ; then
        return 0

    elif [ ! "$CONTENT_TYPE" = "application/x-www-form-urlencoded" ] ; then
        echo "bash.cgi warning: you should probably use MIME type application/x-www-form-urlencoded!" 1>&2
    fi

    # convert multipart to urlencoded
    local handlemultipart=0 # enable to handle multipart/form-data (dangerous?)
    if [ "$handlemultipart" = "1" -a "${CONTENT_TYPE:0:19}" = "multipart/form-data" ]; then
        boundary=${CONTENT_TYPE:30}
        read -r -N "$CONTENT_LENGTH" RECEIVED_POST
        # FIXME: don't use awk, handle binary data (Content-Type: application/octet-stream)
        POST_STRING="$(echo "$RECEIVED_POST" | awk -v b="$boundary" 'BEGIN { RS=b"\r\n"; FS="\r\n"; ORS="&" }
           $1 ~ /^Content-Disposition/ {gsub(/Content-Disposition: form-data; name=/, "", $1); gsub("\"", "", $1); print $1"="$3 }')"
    else
        [ -z "${POST_STRING:-}" -a "$REQUEST_METHOD" = "POST" -a -n "${CONTENT_LENGTH:-}" ] && read -r -N "$CONTENT_LENGTH" POST_STRING
    fi

    OIFS="$IFS"
    #IFS='&=' # doesn't work?
    IFS='=&' # doesn't work?
    read -r -a parm_get <<<"$QUERY_STRING"
    read -r -a parm_post <<<"${POST_STRING:-}"
    #parm_get=($QUERY_STRING)
    #parm_post=(${POST_STRING:-})
    IFS="$OIFS"

    for ((i=0; i<${#parm_get[@]}; i+=2)); do
        cgi_get[${parm_get[i]}]="$(__urldecode "${parm_get[i+1]}")"
    done

    for ((i=0; i<${#parm_post[@]}; i+=2)); do
        cgi_post[${parm_post[i]}]="$(__urldecode "${parm_post[i+1]}")"
    done
}
__request_method_required () {
    if [ ! "${REQUEST_METHOD:-}" = "$1" ] ; then
        __httperror 400 "Bad request: Invalid method '$REQUEST_METHOD'"
    fi
}
__content_type_required () {
    if [ ! "${CONTENT_TYPE:-}" = "$1" ] ; then
        __httperror 400 "Bad Request: Invalid content type (required: '$1')"
    fi
}
# shellcheck disable=SC2120
__content_type () {
    local content_type="${1:-$DEFAULT_CONTENT_TYPE}"
    # shellcheck disable=SC2059
    printf "Content-Type: $content_type\n"
}
__httpstatus () {
    local error_code="$1" error_msg="$2"
    # shellcheck disable=SC2059
    printf "Status: $error_code $error_msg\n"
}
__httperror () {
    local error_code="$1" error_msg="$2"
    __httpstatus "$error_code" "$error_msg"
    # shellcheck disable=SC2119
    __content_type
    printf "\n"
    echo "Error $error_code: $error_msg"
    exit 0
}
__logerr () {
    printf "%s\n" "$*" 1>&2
}
__print_cgi_query () {
    echo "get:"
    for i in "${!cgi_get[@]}" ; do  echo "key $i val '${cgi_get[$i]}'"; done

    echo "post:"
    for i in "${!cgi_post[@]}" ; do  echo "key $i val '${cgi_post[$i]}'"; done
}

