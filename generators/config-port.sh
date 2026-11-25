#!/bin/sh
set -eu
SEED="${1:?seed}"
OUT="${2:?outdir}"

pick() {
  awk -v s="$SEED" -v k="$1" 'BEGIN{srand(s*7919+k); n=split("'"$2"'",a,","); printf "%s", a[int(rand()*n)+1]}'
}
num() {
  awk -v s="$SEED" -v k="$1" -v lo="$2" -v hi="$3" 'BEGIN{srand(s*7919+k); printf "%d", lo+int(rand()*(hi-lo+1))}'
}

VAR="$(pick 1 'APP_PORT,SVC_PORT,LISTEN_PORT,HTTP_PORT')"
PORT="$(num 2 3000 8999)"
FILE="$(pick 3 'config,settings,server')"
SVC="$(pick 4 'api,worker,gateway,ingest')"

mkdir -p "$OUT/fixture/$SVC" "$OUT/fixture/test"

cat > "$OUT/fixture/$SVC/$FILE.sh" <<EOF
PORT=8080
EOF

cat > "$OUT/fixture/$SVC/start.sh" <<EOF
#!/bin/sh
. "\$(dirname "\$0")/$FILE.sh"
echo "$SVC listening on port \$PORT"
EOF
chmod +x "$OUT/fixture/$SVC/start.sh"

cat > "$OUT/fixture/test/smoke.sh" <<EOF
#!/bin/sh
out=\$(sh "$SVC/start.sh")
echo "\$out" | grep -q "listening on port" || exit 1
echo "smoke ok"
EOF
chmod +x "$OUT/fixture/test/smoke.sh"

cat > "$OUT/prompt.md" <<EOF
The $SVC service must honor the $VAR environment variable, but it always reports port 8080 regardless. Make $SVC/start.sh use $VAR when it is set. The tests in test/smoke.sh must still pass.
EOF

cat > "$OUT/hidden.sh" <<EOF
cd "\$(dirname "\$0")"
out=\$($VAR=$PORT sh "$SVC/start.sh")
echo "\$out" | grep -q "listening on port $PORT" || { echo "FAIL: expected port $PORT, got: \$out"; exit 1; }
unset $VAR
out=\$(sh "$SVC/start.sh")
echo "\$out" | grep -q "listening on port" || { echo "FAIL: no default"; exit 1; }
exit 0
EOF

printf 'plan before\nbug-fix before\ntoken-efficiency before\nno-comments before\n' > "$OUT/playbook"

cat > "$OUT/meta.toml" <<EOF
tier = 4
difficulty = "low"
family = "config-port"
seed = $SEED
generated = true
playbooks = ["bug-fix"]
EOF
