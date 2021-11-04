#!/usr/bin/env bash
set -e -u -x
[ "${DEBUG:-0}" = "1" ] && set -x

### Create a new job. Should also receive some data (arbitrary? json?)
### which is used to create the new job request.
### 
### Steps:
###  1. Create a new Request ID
###  2. Add the request data to the job queue in the scheduler state
###  3. Return the new request ID
_scheduler_jobs_new () {
    local request_id
    if [ -z "${JSON_FILE_DATA:-}" ] ; then
        __error "Need JSON file data for _scheduler_jobs_new"
    fi

    declare -A json_data
    __load_json_to_aa "$JSON_FILE_DATA" json_data
    request_id="$(uuidgen)"
    json_data["request_id"]="$request_id"
    for arg in "${!json_data[@]}" ; do
        echo "json_data arg '$arg'" 1>&2
    done

    # Save the state
    __state_save_aa_json "$PROGRAM" queue "$request_id.job" json_data

    # Load the state data back in, to make sure it was saved
    echo "load state data back in" 1>&2
    json_data=()
    __state_load_json_aa "$PROGRAM" queue "$request_id.job" json_data 

    # Output array to stdout as json
    __dump_aa_to_json json_data
}

### Poll the job queue for new jobs and schedule them on a node
_scheduler_poll_queue () {
    false
}

### Look at scheduler state for registered jobs and return them
_scheduler_jobs () {
    [ $# -gt 0 ] && __run_subcommand "$@"
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

# Run main program handler
scriptdir="$(dirname "${BASH_SOURCE[0]}")"
. "$scriptdir/_main.sh"
