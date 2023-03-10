#!/bin/bash
test_path=$(cd "${BASH_SOURCE[0]%/*}"; pwd)
export test_path
root_path=$(cd "$test_path/../.."; pwd)
lib_path="$root_path/lib"

. "$lib_path/log.sh"
. "$lib_path/transport.sh"

. "$root_path/tap.sh" 2>/dev/null || . "$root_path/test/tap.sh"

export TEST_SET_NON_STALE_MESSAGES

timestamp() {
	echo $(($(date +%s)+$1))
}
export -f timestamp

ssb-server() {
	case "$1" in
		whoami)
			echo '{"id":"@i40pt/QgqhjIUOvq2166WZr5bXMGt/8/Zr5GD8yQRvA=.ed25519"}'
			;;
		publish)
			cat | tee $wdir/output
			;;
		createUserStream)
			if [[ $TEST_SET_NON_STALE_MESSAGES ]]; then
				jq ".[].value.content *= {time:$(timestamp -1000),price:0.223} | .[]" "$test_path/messages/ssb-messages.json"
			else
				jq ".[].value.content.time=$(timestamp -2000) | .[]" "$test_path/messages/ssb-messages.json"
			fi
			;;
	esac
}
export -f ssb-server

export OMNIA_VERSION="dev-test"
export OMNIA_CONFIG="$test_path/configs/oracle-transport-ssb-test.conf"
export ETH_FROM="0x1f8fbe73820765677e68eb6e933dcb3c94c9b708"
export ETH_KEYSTORE="$test_path/tests/resources/keys"
export ETH_PASSWORD="$test_path/tests/resources/password"

currentTime=$(timestamp 0)

export PATH="${0%/*/*}/exec:${PATH}"

echo '{}' > $wdir/output
assert "broadcast price message" run transport-ssb push '{"hash":"AB","price":0.222,"priceHex":"ABC","signature":"CD","sources":{"s1":"0.1","s2":"0.2","s3":"0.3"},"time":'$currentTime',"timeHex":"DEF","type":"BTCUSD","version":"dev-test"}'
assert "verify the broadcast message" json . <<<'{"price":0.222,"hash":"AB","priceHex":"ABC","signature":"CD","sources":{"s1":"0.1","s2":"0.2","s3":"0.3"},"time":'$currentTime',"timeHex":"DEF","type":"BTCUSD","version":"dev-test"}'

TEST_SET_NON_STALE_MESSAGES=1
echo '{}' > $wdir/output
assert "broadcast message with non-stale latest message" run transport-ssb push '{"hash":"AB","price":0.222,"priceHex":"ABC","signature":"CD","sources":{"s1":"0.1","s2":"0.2","s3":"0.3"},"time":'$currentTime',"timeHex":"DEF","type":"BTCUSD","version":"dev-test"}'
assert "no broadcast should have been done" json '.' <<<'{}'
