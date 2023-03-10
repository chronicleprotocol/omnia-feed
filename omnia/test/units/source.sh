#!/bin/bash
test_path=$(cd "${BASH_SOURCE[0]%/*}"; pwd)
root_path=$(cd "$test_path/../.."; pwd)
lib_path="$root_path/lib"

. "$lib_path/log.sh"
. "$lib_path/util.sh"
. "$lib_path/status.sh"

. "$root_path/tap.sh" 2>/dev/null || . "$root_path/test/tap.sh"

# Mock setzer
setzer() {
	case "$1-$2-$3" in
		sources-batusd-) echo -e "c\na\nb";;
		price-batusd-a) echo 0.2;;
		price-batusd-b) echo 0.3;;
		price-batusd-c) echo 0.4;;
		*) return 1;;
	esac
}
export -f setzer

# Mock gofer
export test_path
gofer() {
	case "$*" in
		*BAT/USD*)
			cat "$test_path/messages/gofer-batusd-resp.jsonl"
			;;
		*)
			return 1
			;;
	esac
}
export -f gofer

OMNIA_SRC_TIMEOUT=60

assert "read sources from setzer" run_json source-setzer BAT/USD
assert "setzer length of sources" json '.sources|length' <<<"3"
assert "setzer median" json '.median' <<<"0.3"

assert "read sources from gofer" run_json source-gofer BAT/USD
assert "gofer length of sources" json '.sources|length' <<<"5"
assert "gofer median" json '.median' <<<"0.2"
