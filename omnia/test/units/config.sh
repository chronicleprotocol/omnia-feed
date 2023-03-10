#!/bin/bash
test_path=$(cd "${BASH_SOURCE[0]%/*}"; pwd)
root_path=$(cd "$test_path/../.."; pwd)
lib_path="$root_path/lib"

. "$lib_path/log.sh"
. "$lib_path/util.sh"
. "$lib_path/config.sh"

. "$root_path/lib/tap.sh" 2>/dev/null || . "$root_path/test/tap.sh"

_validConfig="$(jq -c . "$test_path/configs/oracle-relay-test.conf")"

# Setting up clean vars
ETH_GAS_SOURCE=""
ETH_MAXPRICE_MULTIPLIER=""
ETH_TIP_MULTIPLIER=""
ETH_GAS_PRIORITY=""

# Testing default values
_json=$(jq -c '.ethereum' <<< "$_validConfig")
assert "importGasPrice should correctly parse values" run importGasPrice $_json

assert "ETH_GAS_SOURCE should have value: ethgasstation" match "^node" <<<$ETH_GAS_SOURCE
assert "ETH_MAXPRICE_MULTIPLIER should have value: 1" match "^1$" <<<$ETH_MAXPRICE_MULTIPLIER
assert "ETH_TIP_MULTIPLIER should have value: 1" match "^1$" <<<$ETH_TIP_MULTIPLIER
assert "ETH_GAS_PRIORITY should have value: slow" match "^fast" <<<$ETH_GAS_PRIORITY

# Testing changed values
_json="{\"gasPrice\":{\"source\":\"ethgasstation\",\"maxPriceMultiplier\":0.5,\"tipMultiplier\":1.0,\"priority\":\"slow\"}}"
assert "importGasPrice should correctly parse new values" run importGasPrice $_json

assert "ETH_GAS_SOURCE should have value: ethgasstation" match "^ethgasstation$" <<<$ETH_GAS_SOURCE
assert "ETH_MAXPRICE_MULTIPLIER should have value: 0.5" match "^0.5$" <<<$ETH_MAXPRICE_MULTIPLIER
assert "ETH_TIP_MULTIPLIER should have value: 1" match "^1$" <<<$ETH_TIP_MULTIPLIER
assert "ETH_GAS_PRIORITY should have value: slow" match "^slow$" <<<$ETH_GAS_PRIORITY

# Testing importNetwork() & Infura keys

# Mocking ETH-RPC request
getLatestBlock () {
  printf "1"
}
export -f getLatestBlock

_network_json='{"network":"http://geth.local:8545","infuraKey":"wrong-key"}'

errors=()
assert "importNetwork: infuraKey should fail if incorrect key configured" fail importNetwork $_network_json

errors=()
assert "importNetwork: infuraKey should give valid error message" match "Error - Invalid Infura Key" < <(capture importNetwork $_network_json)

# NOTE: We have to reset `errors` after failed run
errors=()
_network_json='{"network":"http://geth.local:8545"}'
assert "importNetwork: missing infuraKey should pass validation" run importNetwork $_network_json

_network_json='{"network":"http://geth.local:8545","infuraKey":""}'
assert "importNetwork: empty infuraKey should pass validation" run importNetwork $_network_json

INFURA_KEY=""
_network_json='{"network":"http://geth.local:8545","infuraKey":"305ac4ca797b6fa19d5e985b8269f6c5"}'\

assert "importNetwork: valid infuraKey should pass validation" run importNetwork $_network_json
assert "importNetwork: valid infuraKey should be set as ENV var" match "^305ac4ca797b6fa19d5e985b8269f6c5$" <<<$INFURA_KEY

assert "importNetwork: custom network should be set correctly" run importNetwork $_network_json
assert "importNetwork: custom network value should be set to ENV var ETH_RPC_URL" match "^http://geth.local:8545$" <<<$ETH_RPC_URL

assert "importNetwork: ethlive netork shouldn't crash" run importNetwork '{"network":"ethlive"}'
assert "importNetwork: ethlive network should expand to full url" match "^https://mainnet.infura.io" <<<$ETH_RPC_URL

assert "importNetwork: mainnet netork shouldn't crash" run importNetwork '{"network":"mainnet"}'
assert "importNetwork: mainnet network should expand to full url" match "^https://mainnet.infura.io" <<<$ETH_RPC_URL

assert "importNetwork: ropsten netork shouldn't crash" run importNetwork '{"network":"ropsten"}'
assert "importNetwork: ropsten network should expand to full url" match "^https://ropsten.infura.io" <<<$ETH_RPC_URL

assert "importNetwork: kovan netork shouldn't crash" run importNetwork '{"network":"kovan"}'
assert "importNetwork: kovan network should expand to full url" match "^https://kovan.infura.io" <<<$ETH_RPC_URL

assert "importNetwork: rinkeby netork shouldn't crash" run importNetwork '{"network":"rinkeby"}'
assert "importNetwork: rinkeby network should expand to full url" match "^https://rinkeby.infura.io" <<<$ETH_RPC_URL

assert "importNetwork: goerli netork shouldn't crash" run importNetwork '{"network":"goerli"}'
assert "importNetwork: goerli network should expand to full url" match "^https://goerli.infura.io" <<<$ETH_RPC_URL

getLatestBlock () {
  printf "some error message"
}
export -f getLatestBlock
assert "importNetwork: invalid block number should fail execution" fail importNetwork '{"network":"goerli"}'

getLatestBlock () {
  printf ""
}
export -f getLatestBlock
assert "importNetwork: empty block number should fail execution" fail importNetwork '{"network":"goerli"}'

# importMode tests
errors=()
assert "importMode: fails on invalid mode" fail importMode '{"mode":"blahblah"}'

errors=()
assert "importMode: works correctly on feed" run importMode '{"mode":"feed"}'
assert "importMode: fails on relay" fail importMode '{"mode":"relay"}'

export OMNIA_MODE=""
assert "importMode: works correctly" run importMode '{"mode":"feed"}'
assert "importMode: actualy sets ENV var in upper case" match "^FEED$" <<<$OMNIA_MODE

# importSources tests
assert "importSources: sets custom sources" run importSources '{"sources":["blah", "another"]}'
assert "importSources: set source in array" match "^blah$" <<<${OMNIA_FEED_SOURCES[0]}
assert "importSources: set source in array" match "^another$" <<<${OMNIA_FEED_SOURCES[1]}

export OMNIA_FEED_SOURCES=()
assert "importSources: sets default values if nothing given" run importSources '{}'
assert "importSources: set gofer as first element in array" match "^gofer$" <<<${OMNIA_FEED_SOURCES[0]}
assert "importSources: set setzer as second element in array" match "^setzer$" <<<${OMNIA_FEED_SOURCES[1]}

# importGasPrice function
export ETH_GAS_SOURCE=""
export ETH_MAXPRICE_MULTIPLIER=""
export ETH_TIP_MULTIPLIER=""
export ETH_GAS_PRIORITY=""
# executing importGasPrice
importGasPrice '{}'
assert "importGasPrice: set default source to 'node'" match "^node$" <<<$ETH_GAS_SOURCE
assert "importGasPrice: set default maxPriceMultiplier to '1'" match "^1$" <<<$ETH_MAXPRICE_MULTIPLIER
assert "importGasPrice: set default tipMultiplier to '1'" match "^1$" <<<$ETH_TIP_MULTIPLIER
assert "importGasPrice: set default priority to 'fast'" match "^fast$" <<<$ETH_GAS_PRIORITY

assert "importGasPrice: fails on invalid maxPriceMultiplier" match "^Error - Ethereum Gas max price multiplier is invalid" < <(capture importGasPrice '{"gasPrice":{"maxPriceMultiplier":"asdf"}}')
assert "importGasPrice: fails on invalid tipMultiplier" match "^Error - Ethereum Gas price tip multiplier is invalid" < <(capture importGasPrice '{"gasPrice":{"maxPriceMultiplier":1,"tipMultiplier":"asdf"}}')
assert "importGasPrice: fails on invalid priority" match "^Error - Ethereum Gas price priority is invalid" < <(capture importGasPrice '{"gasPrice":{"maxPriceMultiplier":1,"tipMultiplier":1,"priority":"wrong"}}')

export ETH_GAS_SOURCE=""
export ETH_MAXPRICE_MULTIPLIER=""
export ETH_TIP_MULTIPLIER=""
export ETH_GAS_PRIORITY=""

_json='{"gasPrice":{"source":"other","maxPriceMultiplier":2,"tipMultiplier":2,"priority":"fastest"}}'
assert "importGasPrice: correctly works" run importGasPrice "$_json"
assert "importGasPrice: set given source to 'other'" match "^other$" <<<$ETH_GAS_SOURCE
assert "importGasPrice: set given maxPriceMultiplier to '2'" match "^2$" <<<$ETH_MAXPRICE_MULTIPLIER
assert "importGasPrice: set given tipMultiplier to '2'" match "^2$" <<<$ETH_TIP_MULTIPLIER
assert "importGasPrice: set given priority to 'fastest'" match "^fastest$" <<<$ETH_GAS_PRIORITY

# importFeeds function
assert "importFeeds: fails on invalid address" fail importFeeds '{"feeds":["asdfasd"]}'
assert "importFeeds: works with correct address" run importFeeds '{"feeds":["0xBb94f7C5f14fd29EE744b5A54f05f29aE488Fe77"]}'
assert "importFeeds: puled address" match "^0xBb94f7C5f14fd29EE744b5A54f05f29aE488Fe77$" <<<${feeds[0]}


errors=()
# importOptionsEnv function
# Needed to check all feed config parsing as well.
export OMNIA_MODE="FEED"

errors=()
assert "importOptionsEnv: fails on invalid interval" fail importOptionsEnv '{"options":{"interval":"asdf"}}'
assert "importOptionsEnv: shows correct error on invalid interval" match "^Error - Interval param is invalid" <<<${errors[0]}

errors=()
assert "importOptionsEnv: fails on invalid msgLimit" fail importOptionsEnv '{"options":{"interval":1,"msgLimit":"asdf"}}'
assert "importOptionsEnv: shows correct error on invalid msgLimit" match "^Error - Msg Limit param is invalid" <<<${errors[0]}

errors=()
export OMNIA_VERBOSE=""
assert "importOptionsEnv: fails on invalid verbose" fail importOptionsEnv '{"options":{"interval":1,"msgLimit":1,"verbose":"asdf"}}'
assert "importOptionsEnv: shows correct error on invalid verbose" match "^Error - Verbose param is invalid" <<<${errors[0]}
export OMNIA_VERBOSE="false"

errors=()
export OMNIA_LOG_FORMAT=""
assert "importOptionsEnv: fails on invalid logFormat" fail importOptionsEnv '{"options":{"interval":1,"msgLimit":1,"logFormat":"asdf"}}'
assert "importOptionsEnv: shows correct error on invalid logFormat" match "^Error - LogFormat param is invalid" <<<${errors[0]}
export OMNIA_LOG_FORMAT="text"

errors=()
assert "importOptionsEnv: fails on invalid srcTimeout" fail importOptionsEnv '{"options":{"interval":1,"msgLimit":1,"srcTimeout":"asdf"}}'
assert "importOptionsEnv: shows correct error on invalid srcTimeout" match "^Error - Src Timeout param is invalid" <<<${errors[0]}

errors=()
_json='{"options":{"interval":1,"msgLimit":1,"srcTimeout":1,"setzerTimeout":"asdf"}}'
assert "importOptionsEnv: fails on invalid setzerTimeout" fail importOptionsEnv "$_json"
assert "importOptionsEnv: shows correct error on invalid setzerTimeout" match "^Error - Setzer Timeout param is invalid" <<<${errors[0]}

errors=()
_json='{"options":{"interval":1,"msgLimit":1,"srcTimeout":1,"setzerTimeout":1,"setzerCacheExpiry":"asdf"}}'
assert "importOptionsEnv: fails on invalid setzerCacheExpiry" fail importOptionsEnv "$_json"
assert "importOptionsEnv: shows correct error on invalid setzerCacheExpiry" match "^Error - Setzer Cache Expiry param is invalid" <<<${errors[0]}

errors=()
_json='{"options":{"interval":1,"msgLimit":1,"srcTimeout":1,"setzerTimeout":1,"setzerCacheExpiry":10,"setzerMinMedian":"asdf"}}'
assert "importOptionsEnv: fails on invalid setzerMinMedian" fail importOptionsEnv "$_json"
assert "importOptionsEnv: shows correct error on invalid setzerMinMedian" match "^Error - Setzer Minimum Median param is invalid" <<<${errors[0]}

errors=()
export SETZER_ETH_RPC_URL=""
_json='{"options":{"interval":1,"msgLimit":1,"srcTimeout":1,"setzerTimeout":1,"setzerCacheExpiry":10,"setzerMinMedian":3,"setzerEthRpcUrl":""}}'
assert "importOptionsEnv: fails on missing setzerEthRpcUrl" fail importOptionsEnv "$_json"
assert "importOptionsEnv: shows correct error on invalid setzerEthRpcUrl" match "^Error - Setzer ethereum RPC address is not set" <<<${errors[0]}


errors=()
export OMNIA_INTERVAL=""
export OMNIA_MSG_LIMIT=""
export OMNIA_VERBOSE=""
export OMNIA_LOG_FORMAT=""
export OMNIA_SRC_TIMEOUT=""
export SETZER_TIMEOUT=""
export SETZER_CACHE_EXPIRY=""
export SETZER_MIN_MEDIAN=""
export SETZER_ETH_RPC_URL=""
_json='{"options":{"interval":1,"msgLimit":2,"verbose":"true","logFormat":"json","srcTimeout":3,"setzerTimeout":4,"setzerCacheExpiry":10,"setzerMinMedian":3,"setzerEthRpcUrl":"http://localhost:4040"}}'
assert "importOptionsEnv: runs on correct with valid options" run importOptionsEnv $_json
assert "importOptionsEnv: set correct value to OMNIA_INTERVAL" match "^1$" <<<$OMNIA_INTERVAL
assert "importOptionsEnv: set correct value to OMNIA_MSG_LIMIT" match "^2$" <<<$OMNIA_MSG_LIMIT
assert "importOptionsEnv: set correct value to OMNIA_VERBOSE" match "^true$" <<<$OMNIA_VERBOSE
assert "importOptionsEnv: set correct value to OMNIA_LOG_FORMAT" match "^json$" <<<$OMNIA_LOG_FORMAT
assert "importOptionsEnv: set correct value to OMNIA_SRC_TIMEOUT" match "^3$" <<<$OMNIA_SRC_TIMEOUT
assert "importOptionsEnv: set correct value to SETZER_TIMEOUT" match "^4$" <<<$SETZER_TIMEOUT
assert "importOptionsEnv: set correct value to SETZER_CACHE_EXPIRY" match "^10$" <<<$SETZER_CACHE_EXPIRY
assert "importOptionsEnv: set correct value to SETZER_MIN_MEDIAN" match "^3$" <<<$SETZER_MIN_MEDIAN
assert "importOptionsEnv: set correct value to SETZER_ETH_RPC_URL" match "^http://localhost:4040$" <<<$SETZER_ETH_RPC_URL