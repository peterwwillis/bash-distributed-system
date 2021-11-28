#!/usr/bin/env bash
set -eu

declare -a PROCESSOR_LOGGER_CMD=("processor-logger-tee.sh")

### Run the command and pipe output to a program, and wait for the command to
### exit so we can capture its unix exit code and update the job status.
__processor_run_logger_pipe () {
    local status

    _processor_jobs_status_update \
        -s "running" \
        -S "ok" \
        -n "$NODE_NAME" \
        -c "$(date +%s)" \
        -m "{\"pid\": \"$BASHPID\"}" \
        "${PROCESSOR_REQUEST_ID}"

    "$@" < /dev/null 2>&1 | "${PROCESSOR_LOGGER_CMD[@]}" >/dev/null 2>&1
    # Pipestatus only seems to be set properly if the command was *not* made a
    # background job; using 'wait' doesn't seem to help :(
    declare -a pipestatus=( "${PIPESTATUS[@]}" )
    result=${pipestatus[0]}
    if [ "$result" -ne 0 ] ; then
        status="error;$result"
    else
        status="ok;$result"
    fi

    # Record the exit status
    _processor_jobs_status_update \
        -s "stopped" \
        -S "$status" \
        -n "$NODE_NAME" \
        -e "$(date +%s)" \
        "${PROCESSOR_REQUEST_ID}"
}

