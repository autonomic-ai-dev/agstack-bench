#!/bin/sh
[ -f "$DATA_FILE" ] || { echo "FATAL: data file not found: '$DATA_FILE'" >&2; exit 1; }
echo "serving $(wc -l < "$DATA_FILE" | tr -d ' ') records"
