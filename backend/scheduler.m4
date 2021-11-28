#!/usr/bin/env bash
set -e -u
[ "${DEBUG:-0}" = "1" ] && set -x

### This function will take a function name, state name, a postfix for a state
### filename, and JSON_FILE_DATA json data. It will generate a uuid, and save
### this uuid along with the json data to the state, then print it out to
### verify all went well.
__generic_request_add () {
    local func="$1" statename="$2" statepostfix="$3"
    local id
    if [ -z "${JSON_FILE_DATA:-}" ] ; then
        __error "Need JSON file data for function '$func'"
    fi

    declare -A json_data
    __load_json_to_aa json_data "$JSON_FILE_DATA"
    id="$(uuidgen)"
    json_data["id"]="$id"

    # Save the state
    __state save_aa_json json_data "$PROGRAM" "$statename" "$id$statepostfix"

    # Load the state data back in, to make sure it was saved
    json_data=()
    __state load_json_aa "$PROGRAM" queue "$id$statepostfix" json_data 

    # Output array to stdout as json
    __dump_aa_to_json json_data
}

### Create a new job. Should also receive some data (arbitrary? json?)
### which is used to create the new job request.
### 
### Steps:
###  1. Create a new Request ID
###  2. Add the request data to the job queue in the scheduler state
###  3. Return the new request ID
_scheduler_jobs_add () {
    __generic_request_add "_scheduler_jobs_add" "queue" ".job"
}

### Query a node processor for a particular job's status
_scheduler_jobs_status () {
    false
}

### Poll a specific job and update its status in scheduler state.
_scheduler_jobs_update_job () {
    false
}

_scheduler_jobs_list () {
    false
}

### Look at scheduler state for registered jobs and return them
_scheduler_jobs () {
    if    [ $# -gt 0 ] ; then
        PARENT_CMD="_scheduler_jobs" __run_subcommand "$@"
    else
        _scheduler_jobs_list "$@"
    fi
}

### Poll the job queue for new jobs and schedule them on a node
_scheduler_poll_queue () {
    false
    while read -r newjob ; do
        # Create a lock on the new job by renaming it
        curstate="$(__state lock "$PROGRAM" queue "$newjob")"

    done < <(__state list "$PROGRAM" queue)
    false
}

### List the nodes. Note the ones that are currently available to run a job.
### Sample output:
###   { [ "name": "node01", 
###       "ipv4": [ "192.168.0.1" ], 
###       "hostname": "node01.internal", 
###       "uri": "http://node01.internal:5678",
###       "available": "true"
###   ] }
_scheduler_nodes_list () {
    false
}

### Add a node.
_scheduler_nodes_add () {
    __generic_request_add "_scheduler_nodes_add" "nodes" ".node"
}

### Update a node.
_scheduler_nodes_update () {
    false
}

### Remove a node.
_scheduler_nodes_remove () {
    false
}

# Run main program handler
scriptdir="$(dirname "${BASH_SOURCE[0]}")"
functionsdir="_FUNCTIONSDIR_"
. "$functionsdir/functions/main.sh"
