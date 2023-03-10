#!/bin/bash
test_path=$(cd "${BASH_SOURCE[0]%/*}"; pwd)
root_path=$(cd "$test_path/../.."; pwd)
lib_path="$root_path/lib"

. "$lib_path/log.sh"
. "$lib_path/transport.sh"

. "$root_path/tap.sh" 2>/dev/null || . "$root_path/test/tap.sh"

export test_path
transport-mock() {
	case "$1" in
		push|publish)
			echo "$2" >> $wdir/output
			;;
		pull)
			cat "$test_path/messages/transport-message.json"
			;;
		*) return 1;;
	esac
}
export -f transport-mock

transport-mock-other() {
	case "$1" in
		push|publish)
			jq '.time += 10' <<<"$2" >> $wdir/output
			;;
		*) return 1;;
	esac
}
export -f transport-mock-other

transport-mock-latest() {
	case "$1" in
		pull)
			jq '.time += 10' "$test_path/messages/transport-message.json"
			;;
		*) return 1;;
	esac
}
export -f transport-mock-latest

transport-mock-fail() {
	return 1
}
export -f transport-mock-fail

transport-mock-mallformed() {
	case "$1" in
		pull) printf %s '{';;
	esac
}
export -f transport-mock-mallformed

transport-mock-empty() {
	case "$1" in
		pull) printf %s '';;
	esac
}
export -f transport-mock-empty

OMNIA_SRC_TIMEOUT=60
transportMessage="$(jq -c . "$test_path/messages/transport-message.json")"

rm -f $wdir/output
OMNIA_TRANSPORTS=(mock)
assert "publish to transport" run transportPublish "BTC/USD" "$transportMessage"
assert "type should be BTCUSD" json '.type' <<<'"BTCUSD"'
assert "time should be set" json '.time' <<<"1607032851"

rm -f $wdir/output
OMNIA_TRANSPORTS=(mock mock-other)
assert "publish to two transports" run transportPublish "BTC/USD" "$transportMessage"
assert "type should be two BTCUSD" json -s '[.[].type]' <<<'["BTCUSD","BTCUSD"]'
assert "time should be separate times " json -s '[.[].time]' <<<"[1607032851,1607032861]"

OMNIA_TRANSPORTS=(mock-fail)
assert "should fail if transport exits non-zero" fail transportPublish "BTC/USD" "$transportMessage"
