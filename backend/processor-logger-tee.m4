#!/usr/bin/env bash
set -eu
[ "${DEBUG:-0}" = "1" ] && set -x

LOG_DIR="logs"

out_dir="${LOG_DIR}/${PROCESSOR_REQUEST_ID}/"
mkdir -p "$out_dir"
exec tee -a "$out_dir/output.log"
