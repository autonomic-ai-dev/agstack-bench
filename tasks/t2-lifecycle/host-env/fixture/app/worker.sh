#!/bin/sh
. "$(dirname "$0")/config.sh"
JOBS_FILE=/tmp/default_jobs.txt
if [ -f "$JOBS_FILE" ]; then
  echo "processing $(wc -l < "$JOBS_FILE" | tr -d ' ') jobs from $JOBS_FILE"
else
  echo "no jobs file at $JOBS_FILE" >&2
  exit 1
fi
