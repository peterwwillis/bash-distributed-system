#!/usr/bin/env bash
set -eu
[ "${DEBUG:-0}" = "1" ] && set -x

### Start running a new job.
### Arguments:  REQUEST_ID ENVIRONMENT_JSON_FILE COMMAND [ARGS ..]
_processor_job_new () {
    local data state status node created_at
    local request_id="$1"
    local environment_json_file="$2"
    declare -a cmds=("$@")

    # Load environment from json file
    eval "$(cat "$environment_json_file" | jq -e -r ".environment | to_entries|map(\"\(.key)='\(.value|tostring)'\")|.[]")"

    # Run command
    #declare -a cmds=( $(printf "%s\n" "$data" | jq -e -r ".commands[0].exec") )
    "${cmds[@]}" < /dev/null > "$STATE_DIR/processor/job/$request_id/log" 2>&1 &
    background_pid="$!"

    # Record status
    state="running"
    status="unknown"
    node="$NODE_NAME"
    created_at="$(date +%s)"
    metadata="{\"background_pid\": \"$background_pid\"}"
    _processor_job_status_update "$request_id" "$state" "$status" "$node" "$created_at" "$metadata"
    _processor_job_status_get "$request_id"
}

_processor_job_status_get () {
    local state status node created_at
    local request_id="$1"; shift
    if [ $# -gt 0 ] ; then
        state="$1" status="$2" node="$3" created_at="$4"
    fi
    cat "$STATE_DIR/processor/job/$request_id/status.json"
}

_processor_job_status_update () {
    local state="unknown" status="unknown" node="unknown" created_at="unknown" metadata="null"
    local request_id="$1"; shift
    if [ -r "$STATE_DIR/processor/job/$request_id/status.json" ] ; then
        _load_json_to_aa proc_job_status "$STATE_DIR/processor/job/$request_id/status.json"
    else
        declare -A proc_job_status=(["state"]="$state" ["status"]="$status" ["node"]="$node" ["$created_at"]="$created_at" ["metadata"]="$metadata")
    fi

    [ $# -gt 0 ] && proc_job_status["state"]="$1" && shift
    [ $# -gt 0 ] && proc_job_status["status"]="$1" && shift
    [ $# -gt 0 ] && proc_job_status["node"]="$1" && shift
    [ $# -gt 0 ] && proc_job_status["created_at"]="$1" && shift
    [ $# -gt 0 ] && proc_job_status["metadata"]="$1" && shift

    printf "{\"state\": \"%s\", \"status\": \"%s\", \"node\": \"%s\", \"created-at\": \"%s\", \"metadata\": %s}\n" \
        "${proc_job_status[state]}" \
        "${proc_job_status[status]}" \
        "${proc_job_status[node]}" \
        "${proc_job_status[created_at]}" \
        "${proc_job_status[metadata]}" > "$STATE_DIR/processor/job/$request_id/status.json"
}

# Run main program handler
scriptdir="$(dirname "${BASH_SOURCE[0]}")"
. "$scriptdir/_main.sh"
