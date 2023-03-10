#!/bin/bash
test_path=$(cd "${BASH_SOURCE[0]%/*}"; pwd)
root_path=$(cd "$test_path/../.."; pwd)
lib_path="$root_path/lib"

. "$lib_path/log.sh"
. "$lib_path/gasprice.sh"

. "$root_path/tap.sh" 2>/dev/null || . "$root_path/test/tap.sh"

# GetGasPrice multipliers:
getGasPriceFromNode () {
  echo "20 10"
}
export -f getGasPriceFromNode

ETH_GAS_SOURCE="node"
ETH_MAXPRICE_MULTIPLIER="1"
ETH_TIP_MULTIPLIER="1"
assert "getGasPrice should return a base fee multiplied by $ETH_MAXPRICE_MULTIPLIER and tip multiplied by $ETH_TIP_MULTIPLIER" \
  match "^20 10$" < <(capture getGasPrice)

ETH_MAXPRICE_MULTIPLIER="3"
ETH_TIP_MULTIPLIER="2"
assert "getGasPrice should return a base fee multiplied by $ETH_MAXPRICE_MULTIPLIER and tip multiplied by $ETH_TIP_MULTIPLIER" \
  match "^60 20$" < <(capture getGasPrice)

ETH_MAXPRICE_MULTIPLIER="1.15"
ETH_TIP_MULTIPLIER="1.25"
assert "getGasPrice should return a base fee multiplied by $ETH_MAXPRICE_MULTIPLIER and tip multiplied by $ETH_TIP_MULTIPLIER" \
  match "^23 12$" < <(capture getGasPrice)

ETH_MAXPRICE_MULTIPLIER=""
ETH_TIP_MULTIPLIER="1"
assert "getGasPrice should fail if the ETH_MAXPRICE_MULTIPLIER is not set" fail getGasPrice

ETH_MAXPRICE_MULTIPLIER="1"
ETH_TIP_MULTIPLIER=""
assert "getGasPrice should fail if the ETH_TIP_MULTIPLIER is not set" fail getGasPrice
