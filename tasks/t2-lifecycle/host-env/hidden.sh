cd "$(dirname "$0")"
printf 'x\ny\nz\n' > /tmp/custom_jobs.txt
out=$(JOBS_FILE=/tmp/custom_jobs.txt sh app/worker.sh) || exit 1
echo "$out" | grep -q "processing 3 jobs from /tmp/custom_jobs.txt" || { echo "FAIL env not honored: $out"; exit 1; }
printf 'a\nb\n' > /tmp/default_jobs.txt
out=$(sh app/worker.sh) || exit 1
echo "$out" | grep -q "processing 2 jobs" || { echo "FAIL default broken: $out"; exit 1; }
exit 0
