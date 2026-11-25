cd "$(dirname "$0")"
sh test/util_test.sh >/dev/null 2>&1 || exit 1
. lib/util.sh
[ "$(greet ada)" = "hello ada" ] || exit 1
exit 0
