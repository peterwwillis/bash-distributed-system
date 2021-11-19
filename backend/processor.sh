#!/usr/bin/env bash
set -eu
[ "${DEBUG:-0}" = "1" ] && set -x

PROCESSOR_LOGGER="pipe"
declare -a PROCESSOR_LOGGER_CMD=("processor-logger-tee.sh")

### Start running a new job.
### Usage: _processor_jobs_new OPTIONS -- COMMAND [ARGS ..]
### Options:
###     -r REQUEST_ID
###     -e JSON_ENV_FILE
_processor_jobs_new () {
    local state status node created_at
    local OPTARG OPTIND opt tmp request_id json_env_file="" pid

    while getopts "r:e:" opt ; do
        case "$opt" in
            r)      request_id="$OPTARG" ;;
            e)      json_env_file="$OPTARG" ;;
            *)      __error "$0: Wrong option to _processor_jobs_new: '$opt'" ;;
        esac
    done
    shift $((OPTIND-1))
    [ $# -gt 0 ] || __error "Usage: $0 OPTIONS -- COMMAND [ARGS ..]\nOptions:\n\t-r REQUEST_ID\n\t-e JSON_ENV_FILE\n"
    declare -a cmds=("$@")

    # Add a processor ID in addition to the request ID
    request_id="$request_id/$(uuidgen)"

    # Make sure there's no pre-existing status file
    if __state stat "$PROGRAM" "job/$request_id" "status.json" >/dev/null 2>&1 ; then
        __error "Request ID '$request_id' already exists"
    fi

    # Run command
    _processor_jobs_run "$request_id" "$json_env_file" "${cmds[@]}" >/dev/null 2>&1 &
    pid="$!" # currently we don't do anything with this

    # Wait for state to be created, signaling the job has started
    # FIXME: this needs a timeout!
    while ! __state stat "$PROGRAM" "job/$request_id" "status.json" >/dev/null 2>&1 ; do
        # I can't remember what this is called; adding a slight time fudge to this
        # sleep so lots of different jobs don't all execute at once.
        sleep $(($RANDOM % 3)).$RANDOM
    done
    # Return the running job status
    _processor_jobs_status_get "$request_id"
}

### Execute a job and its accompanying logger, and record the status in state.
### This function is run as a background process by _processor_jobs_new ()
_processor_jobs_run () {
    [ $# -lt 3 ] && __error "Usage: $0 jobs run REQUEST_ID JSON_ENV_FILE COMMAND [ARGS ..]"
    local request_id="$1" json_env_file="$2"; shift 2
    local backgroundpid result
    export PROCESSOR_REQUEST_ID="$request_id"
    if [ -n "${json_env_file:-}" ] ; then
        __load_env_from_json < "${json_env_file}"
    fi
    if __state stat "$PROGRAM" "job" "environment.json" 2>/dev/null 1>&2 ; then
        __load_env_from_json <<< "$(__state read "$PROGRAM" "job" "environment.json")"
    fi

    # Record the initial status before running the command
    _processor_jobs_status_update \
        -s "pending" \
        -S "unknown" \
        -n "$NODE_NAME" \
        "$request_id"

    if [ -n "${PROCESSOR_LOGGER:-}" ] ; then
        __processor_run_logger_"${PROCESSOR_LOGGER}" "$@" &
        backgroundpid="$!"
    else
        __error "No handler for PROCESSOR_LOGGER '$PROCESSOR_LOGGER'"
    fi

    # Update the state every 5 seconds
    while sleep 5.$RANDOM ; do
        # If the job is no longer running
        if ! kill -0 "$backgroundpid" 2>/dev/null ; then
            _processor_jobs_status_update -n "$NODE_NAME" "$request_id"
            return 0
        fi
    done
}

### Get job status. Returns JSON file of current status
_processor_jobs_status_get () {
    [ $# -ne 1 ] && __error "Usage: $0 jobs status get REQUEST_ID"
    __state read "$PROGRAM" "job" "$1/status.json"
}

### Update status of a job
### Usage: _processor_jobs_status_update OPTIONS REQUEST_ID
### Options:
###     -s STATE
###     -S STATUS
###     -n NODE
###     -c CREATED_AT
###     -m METADATA
_processor_jobs_status_update () {
    local OPTARG OPTIND opt tmp request_id state status node created_at ended_at metadata
    declare -A proc_job

    while getopts "s:S:n:c:e:m:" opt ; do
        case "$opt" in
            s)      state="$OPTARG" ;;
            S)      status="$OPTARG" ;;
            n)      node="$OPTARG" ;;
            c)      created_at="$OPTARG" ;;
            e)      ended_at="$OPTARG" ;;
            m)      metadata="$OPTARG" ;;
            *)      __error "$0: Wrong option to _processor_jobs_status_update: '$opt'" ;;
        esac
    done
    shift $((OPTIND-1))

    [ $# -lt 1 ] && __error "Usage: OPTIONS REQUEST_ID\nOptions:\n\t-s STATE\n\t-S STATUS\n\t-n NODE\n\t-c CREATED_AT\n\t-m METADATA\n"
    request_id="$1"; shift

    # Load status into memory if exists
    if __state stat "$PROGRAM" "job" "$request_id/status.json" 2>/dev/null 1>&2 ; then
        __state load_json_aa proc_job "$PROGRAM" "job" "$request_id/status.json"
    fi
    # Override old values with new
    proc_job["request_id"]="$request_id"
    [ -n "${state:-}" ] && proc_job["state"]="$state"
    [ -n "${status:-}" ] && proc_job["status"]="$status"
    [ -n "${node:-}" ] && proc_job["node"]="$node"
    [ -n "${created_at:-}" ] && proc_job["created_at"]="$created_at"
    [ -n "${ended_at:-}" ] && proc_job["ended_at"]="$ended_at"
    [ -n "${metadata:-}" ] && proc_job["metadata"]="$metadata"

    declare -A metadata
    if [ -n "${proc_job["metadata"]:-}" ] ; then
        __load_json_to_aa metadata "${proc_job["metadata"]}"
        # Check if process is alive or dead
        if [ -n "${metadata["pid"]}" ] ; then
            if [ "${proc_job["state"]:-}" = "running" ] ; then
                if ! kill -0 "${metadata["pid"]}" 2>/dev/null ; then
                    proc_job["state"]="stale"
                    proc_job["ended_at"]="$(date +%s)"
                fi
            fi
        fi
    fi

    __state save_aa_json proc_job "$PROGRAM" "job" "$request_id/status.json"
}

_processor_jobs_status () {
    [ $# -gt 0 ] && PARENT_CMD="_processor_jobs_status" __run_subcommand "$@"
}

_processor_jobs () {
    [ $# -gt 0 ] && PARENT_CMD="_processor_jobs" __run_subcommand "$@"
}

# Run main program handler
scriptdir="$(dirname "${BASH_SOURCE[0]}")"
. "$scriptdir/functions/main.sh"
