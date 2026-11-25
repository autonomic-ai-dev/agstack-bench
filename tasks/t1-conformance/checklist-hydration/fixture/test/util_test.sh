#!/bin/sh
. "$(dirname "$0")/../lib/util.sh"
[ "$(greet world)" = "hello world" ] || { echo "FAIL"; exit 1; }
echo ok
