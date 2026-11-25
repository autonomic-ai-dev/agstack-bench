#!/bin/sh
. "$(dirname "$0")/../etc/app.env"
LOG="$(dirname "$0")/../logs/app.log"
i=0
while [ "$i" -lt "${1:-5}" ]; do
  sh "$(dirname "$0")/app.sh" >> "$LOG" 2>&1 && exit 0
  i=$((i + 1))
done
exit 1
