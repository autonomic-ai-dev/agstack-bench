#!/bin/sh
printf 'a\nb\n' > /tmp/default_jobs.txt
out=$(sh app/worker.sh)
echo "$out" | grep -q "processing 2 jobs" || { echo "FAIL"; exit 1; }
echo ok
