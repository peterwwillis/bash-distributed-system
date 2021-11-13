#!/usr/bin/env bash

### State functions

STATE_STORAGE="local"
STATE_DIR="${STATE_DIR:-state}"

### Runs '_state_local_$1 "$@"' if $STATE_STORAGE = "local"
### Example:
###    _state list "scheduler" "queue"
###       -> _state_local_list "scheduler" "queue"
__state () {
    run_subcommand "_state_${STATE_STORAGE}" "$@"
}
#__state_save () {
#    false
#}

