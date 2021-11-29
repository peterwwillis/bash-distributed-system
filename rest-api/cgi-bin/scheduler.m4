#!/usr/bin/env bash
# vim: syntax=bash

### Description: Send a scheduler/jobs/new request to the scheduler backend.
### Usage: POST /scheduler/jobs/new
###        Content-Type: application/json
###        <payload should be a JSON document>
_cgi_scheduler_jobs_add () {
    __request_method_required "POST"
    __content_type_required "application/json"
    set +e
    output="$($BACKEND -j - "${PATH_INFO//\// }")"
    # shellcheck disable=SC2181
    if [ $? -ne 0 ] ; then
        __httperror 400 "The backend application failed to process your request"
    fi
    set -e
    __content_type "application/json"
    printf "\n"
    printf "%s\n" "$output"
}

. "_RESTAPIDIR_/cgi-svc-wrapper.sh"
