#!/usr/bin/env sh
# vim: syntax=sh
[ "${DEBUG:-0}" = "1" ] && set -x
set -u

_t_processor_sh_jobs_new_1234 () {
    cd "$tmpdir"
    processor.sh jobs new -r 1234 -- ls -la
}


ext_tests="processor_sh_jobs_new_1234"
