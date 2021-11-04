#!/usr/bin/env bash
set -e -u -x
[ "${DEBUG:-0}" = "1" ] && set -x

### Create a new job. Should also receive some data (arbitrary? json?)
### which is used to create the new job request.
### 
### Steps:
###  1. Create a new Request ID
###  2. Add the request data to the incoming stack in the scheduler state
###  3. Return the new request ID
_scheduler_jobs_new () {
    local request_id
    if [ -z "${JSON_FILE_DATA:-}" ] ; then
        __error "Need JSON file data for _scheduler_jobs_new"
    fi

    __load_json_to_aa json_data "$JSON_FILE_DATA"
    request_id="$(md5sum <<< "$JSON_FILE_DATA" | awk '{print $1}')"
    __state_save "$PROGRAM" incoming "$request_id.job" <<< "$JSON_FILE_DATA"

    declare -A output=(["request_id"]="$request_id")
    dump_aa_to_json output
}

### Poll the incoming job stack for new jobs and schedule them on a node
_scheduler_poll_incoming () {
    false
}

__run_subcommand "new" "$@"

### Look at scheduler state for registered jobs and return them
_scheduler_jobs () {
    if [ $# -gt 0 ] ; then
        __run_subcommand "$@"
    fi
}

### Query a node processor for a particular job's status
_scheduler_jobs_status () {
    false
}

### Poll a specific job and update its status in scheduler state.
_scheduler_jobs_update_job () {
    false
}

### List the nodes that are currently available to run a job on using a job
### processor.
### Sample output:
###   { [ "name": "node01", "ipv4": [ "192.168.0.1" ], "hostname": "node01.internal", "uri": "http://node01.internal:5678" ] }

_scheduler_nodes_available () {
    true
}

. "./_functions.sh"
