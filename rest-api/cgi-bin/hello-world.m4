#!/usr/bin/env bash
# vim: syntax=bash
set -eu

echo "Content-Type: text/plain"
echo ""
echo "Hello World!"
echo ""
echo "args:" "$@"
echo ""
set
echo "--- data ---"
cat
