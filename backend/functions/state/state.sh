#!/usr/bin/env bash

### State functions

STATE_STORAGE="local"
STATE_DIR="${STATE_DIR:-state}"

# Run '_state_local_$1 "$@"' if $STATE_STORAGE = "local"
__state () {
    run_subcommand "_state_$STATE_STORAGE" "$@"
}
__state_save () {
    false
}

