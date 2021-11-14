#!/usr/bin/env bash
set -eu

__processor_run_logger_pipe () {
    # Run the command! and pipe output to a program
    "$@" < /dev/null 2>&1 | "${PROCESSOR_LOGGER_CMD[@]}" 2>/dev/null 1>/dev/null &
    backgroundpid="$!"
    wait -f "$backgroundpid"
    result=$?
    if [ ${PIPESTATUS[0]} -ne 0 ] || [ $result -ne 0 ] ; then
        echo "$0: Command returned non-zero status ${PIPESTATUS[0]}, $result"
        exit $result
    fi
    # Record the exit status
    _processor_jobs_status_update \
        -s "pending" \
        -S "ok" \
        -n "$NODE_NAME" \
        -c "$(date +%s)" \
        -m "$metadata" \
        "${PROCESSOR_REQUEST_ID}"
}

