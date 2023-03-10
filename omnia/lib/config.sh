importEnv () {
	local _here;_here=$(cd "${BASH_SOURCE[0]%/*}" && pwd)
	local config
	if [[ -f "$OMNIA_CONFIG" ]]; then
		config="$OMNIA_CONFIG"
	elif [[ -f /etc/omnia.conf ]]; then
		config="/etc/omnia.conf"
	elif [[ -f "$_here/../config/omnia.conf" ]]; then
		config="$_here/../config/omnia.conf"
	else
		error "Error Could not find omnia.conf config file to load parameters."
		error "Please create /etc/omnia.conf or put it in the config directory."
		return 1
	fi
	echo "Importing configuration from $config..."

	#check if config file is valid json
	jq -e . "$config" >/dev/null 2>&1 || { error "Error - Config is not valid JSON"; return 1; }
	_json=$(jq -ce . < "$config")

	importMode "$_json" || return 1
	importSources "$_json" || return 1
	importTransports "$_json" || return 1
	importEthereumEnv "$_json" || return 1
	importAssetPairsEnv "$_json" || return 1
	importOptionsEnv "$_json" || return 1
}

importMode () {
	local _json="$1"
	OMNIA_MODE="$(jq -r '.mode' <<<"$_json" | tr '[:lower:]' '[:upper:]')"
	[[ "$OMNIA_MODE" == "FEED" ]] || { error "Error - Invalid Mode param, valid value is 'FEED'"; return 1; }
	export OMNIA_MODE
}

importSources () {
	local _json="$1"
	readarray -t OMNIA_FEED_SOURCES < <(jq -c '.sources // []' <<<"$_json" | jq -r '.[]')
	[[ "${#OMNIA_FEED_SOURCES[@]}" -gt 0 ]] || OMNIA_FEED_SOURCES=("gofer" "setzer")
}

importTransports () {
	local _json="$1"
	readarray -t OMNIA_TRANSPORTS < <(jq -r '.transports[]' <<<"$_json")
	[[ "${#OMNIA_TRANSPORTS[@]}" -gt 0 ]] || OMNIA_TRANSPORTS=("spire" "ssb")
}

# Actual call to eth-rpc was moved to separate function because it helps to mock it in unit tests.
getLatestBlock () {
	ethereum block latest number --rpc-url "$1"
}

importNetwork () {
	local _json="$1"

	INFURA_KEY="$(echo "$_json" | jq -r '.infuraKey // ""')"
	[[ -z "$INFURA_KEY" ]] || [[ "$INFURA_KEY" =~ ^[0-9a-f]{32}$ ]] || errors+=("Error - Invalid Infura Key")
	export INFURA_KEY

	local _network
	_network="$(echo "$_json" | jq -r '.network')"
	_network="${_network,,}"
	case "${_network}" in
		ethlive|mainnet)
			ETH_RPC_URL="https://mainnet.infura.io/v3/$INFURA_KEY"
			;;
		ropsten|kovan|rinkeby|goerli)
			ETH_RPC_URL="https://${_network}.infura.io/v3/$INFURA_KEY"
			;;
		*)
			ETH_RPC_URL="$_network"
			;;
	esac
	export ETH_RPC_URL

	local _chainType
	_chainType="$(echo "$_json" | jq -r '.type')"
	_chainType="${_chainType,,}"

	[[ -n "$_chainType" ]] || ETH_TX_TYPE=2

	case "${_chainType}" in
		ethereum)
			ETH_TX_TYPE=2
			;;
		optimism|arbitrum)
			ETH_TX_TYPE=0
			;;
		*)
			error "Chain type must be one of [ethereum|optimism|arbitrum]"
			;;
	esac
	export ETH_TX_TYPE

	[[ $(getLatestBlock "$ETH_RPC_URL") =~ ^[1-9]{1,}[0-9]*$ ]] || errors+=("Error - Unable to connect to Ethereum _network.\nValid options are: ethlive, mainnet, ropsten, kovan, rinkeby, goerli, or a custom endpoint")
	[[ -z ${errors[*]} ]] || { printf '%s\n' "${errors[@]}"; return 1; }
}

importGasPrice () {
	local _json="$1"

	# Getting Gas price details
	ETH_GAS_SOURCE="$(echo "$_json" | jq -r '.gasPrice.source // "node"')"
	export ETH_GAS_SOURCE

	ETH_MAXPRICE_MULTIPLIER="$(echo "$_json" | jq '.gasPrice.maxPriceMultiplier // 1')"
	[[ $ETH_MAXPRICE_MULTIPLIER =~ ^[0-9\.]+$ ]] || errors+=("Error - Ethereum Gas max price multiplier is invalid, should be a number.")
	export ETH_MAXPRICE_MULTIPLIER

  ETH_TIP_MULTIPLIER="$(echo "$_json" | jq '.gasPrice.tipMultiplier // 1')"
  [[ $ETH_TIP_MULTIPLIER =~ ^[0-9\.]+$ ]] || errors+=("Error - Ethereum Gas price tip multiplier is invalid, should be a number.")
  export ETH_TIP_MULTIPLIER

	ETH_GAS_PRIORITY="$(echo "$_json" | jq -r '.gasPrice.priority // "fast"')"
	[[ $ETH_GAS_PRIORITY =~ ^(slow|standard|fast|fastest)$ ]] || errors+=("Error - Ethereum Gas price priority is invalid.\nValid options are: slow, standard, fast, fastest.")
	export ETH_GAS_PRIORITY

	[[ -z ${errors[*]} ]] || { printf '%s\n' "${errors[@]}"; return 1; }
}

importEthereumEnv () {
	local _config="$1"
	local _json

	_json=$(jq -S '.ethereum' <<<"$_config")

	[[ "$OMNIA_MODE" == "RELAY" ]] && { importNetwork "$_json" || return 1; }

	ETH_FROM="${ETH_FROM-$(jq -r '.from' <<<"$_json")}"
	#this just checks for valid chars and length, NOT checksum!
	[[ "$ETH_FROM" =~ ^(0x){1}[0-9a-fA-F]{40}$ ]] || errors+=("Error - Ethereum Address is invalid.")
	export ETH_FROM

	ETH_KEYSTORE="${ETH_KEYSTORE-$(jq -r '.keystore' <<<"$_json")}"
	#validate path exists
	[[ -d "$ETH_KEYSTORE" ]] || errors+=("Error - Ethereum Keystore Path is invalid, directory does not exist.")
	export ETH_KEYSTORE

	ETH_PASSWORD="${ETH_PASSWORD-$(jq -r '.password' <<<"$_json")}"
	#validate file exists
	[[ -f "$ETH_PASSWORD" ]] || errors+=("Error - Ethereum Password Path is invalid, file does not exist.")
	export ETH_PASSWORD

	# Importing Gas Price
	[[ "$OMNIA_MODE" == "RELAY" ]] && { importGasPrice "$_json" || return 1; }

	[[ -z ${errors[*]} ]] || { printf '%s\n' "${errors[@]}"; return 1; }
}

importAssetPairsEnv () {
	local _config="$1"
	local _json

	_json="$(jq -S '.pairs' <<<"$_config")"

	#create array of asset pairs
	readarray -t assetPairs < <(echo "$_json" | jq -r 'keys | .[]')

	[[ ${#assetPairs[@]} -eq 0 ]] && { error "Error - Config must have at least 1 asset pair"; return 1; }

	[[ "$OMNIA_MODE" == "FEED" ]] && { importAssetPairsFeed || return 1; }
	[[ "$OMNIA_MODE" == "RELAY" ]] && { importAssetPairsRelay || return 1; }
	true
}

importAssetPairsFeed () {
	declare -gA assetInfo
	local _msgExpiration
	local _msgSpread

	#Write values as comma seperated list to associative array
	while IFS="=" read -r assetPair info; do
		assetPair="${assetPair^^}"
		assetPair="${assetPair/\/}"
		assetInfo[$assetPair]="$info"
	done < <(jq -r '.pairs | keys[] as $assetPair | "\($assetPair)=\(.[$assetPair] | .msgExpiration),\(.[$assetPair] | .msgSpread)"' <<<"$_config")

	#Verify values
	for assetPair in "${!assetInfo[@]}"; do
		_msgExpiration=$(getMsgExpiration "$assetPair")
		[[ "$_msgExpiration" =~ ^[1-9][0-9]*$ ]] || errors+=("Error - Asset Pair param $assetPair has invalid or missing msgExpiration field, must be positive integer.")

		_msgSpread=$(getMsgSpread "$assetPair")
		[[ "$_msgSpread" =~ ^([1-9][0-9]*([.][0-9]+)?|[0][.][0-9]*[1-9][0-9]*)$ ]] || errors+=("Error - Asset Pair param $assetPair has invalid or missing msgSpread field, must be positive integer or float.")
	done
	[[ -z ${errors[*]} ]] || { printf '%s\n' "${errors[@]}"; return 1; }
}

importAssetPairsRelay () {
	declare -gA assetInfo
	local _msgExpiration
	local _oracle
	local _oracleExpiration
	local _oracleSpread

	while IFS="=" read -r assetPair info; do
		assetPair="${assetPair^^}"
		assetPair="${assetPair/\/}"
		assetInfo[$assetPair]="$info"
	done < <(jq -r '.pairs | keys[] as $assetPair | "\($assetPair)=\(.[$assetPair] | .msgExpiration),\(.[$assetPair] | .oracle),\(.[$assetPair] | .oracleExpiration),\(.[$assetPair] | .oracleSpread)"' <<<"$_config")

	for assetPair in "${!assetInfo[@]}"; do
		_msgExpiration=$(getMsgExpiration "$assetPair")
		[[ "$_msgExpiration" =~ ^[1-9][0-9]*$ ]] || errors+=("Error - Asset Pair param $assetPair has invalid or missing msgExpiration field, must be positive integer.")

		_oracle=$(getOracleContract "$assetPair")
		[[ "$_oracle" =~ ^(0x){1}[0-9a-fA-F]{40}$ ]] || errors+=("Error - Asset Pair param $assetPair has invalid or missing oracle field, must be ethereum address prefixed with 0x.")

		_oracleExpiration=$(getOracleExpiration "$assetPair")
		[[ "$_oracleExpiration" =~ ^[1-9][0-9]*$ ]] || errors+=("Error - Asset Pair param $assetPair has invalid or missing oracleExpiration field, must be positive integer")

		_oracleSpread=$(getOracleSpread "$assetPair")
		[[ "$_oracleSpread" =~ ^([1-9][0-9]*([.][0-9]+)?|[0][.][0-9]*[1-9][0-9]*)$ ]] || errors+=("Error - Asset Pair param $assetPair has invalid or missing oracleSpread field, must be positive integer or float")
	done
	[[ -z ${errors[*]} ]] || { printf '%s\n' "${errors[@]}"; return 1; }
}

importFeeds () {
	local _config="$1"
	local _json

	readarray -t feeds < <(jq -r '.feeds[]' <<<"$_config")
	for feed in "${feeds[@]}"; do
		[[ $feed =~ ^@[a-zA-Z0-9+/]{43}=.ed25519$ \
		|| $feed =~ ^0x[0-9a-fA-F]{40}$ \
		]] || { error "Error - Invalid feed address: $feed"; return 1; }
	done
	[[ -z ${errors[*]} ]] || { printf '%s\n' "${errors[@]}"; return 1; }
}

importOptionsEnv () {
	local _config="$1"
	local _json

	_json=$(jq -S '.options' <<<"$_config")

	OMNIA_INTERVAL="$(echo "$_json" | jq -S '.interval')"
	[[ "$OMNIA_INTERVAL" =~ ^[1-9][0-9]*$ ]] || errors+=("Error - Interval param is invalid, must be positive integer.")
	export OMNIA_INTERVAL

	OMNIA_MSG_LIMIT="$(echo "$_json" | jq -S '.msgLimit')"
	[[ "$OMNIA_MSG_LIMIT" =~ ^[1-9][0-9]*$ ]] || errors+=("Error - Msg Limit param is invalid, must be positive integer.")
	export OMNIA_MSG_LIMIT

	OMNIA_VERBOSE="${OMNIA_VERBOSE:-$(echo "$_json" | jq -r '.verbose // false')}"
	OMNIA_VERBOSE="$(echo "$OMNIA_VERBOSE" | tr '[:upper:]' '[:lower:]')"
	[[ "$OMNIA_VERBOSE" =~ ^(true|false)$ ]] || errors+=("Error - Verbose param is invalid, must be true or false.")
	export OMNIA_VERBOSE

	OMNIA_LOG_FORMAT="${OMNIA_LOG_FORMAT:-$(echo "$_json" | jq -r '.logFormat // "text"')}"
	OMNIA_LOG_FORMAT="$(echo "$OMNIA_LOG_FORMAT" | tr '[:upper:]' '[:lower:]')"
	[[ "$OMNIA_LOG_FORMAT" =~ ^(text|json)$ ]] || errors+=("Error - LogFormat param is invalid, must be text or json.")
	export OMNIA_LOG_FORMAT

	if [[ "$OMNIA_MODE" == "FEED" ]]; then
		OMNIA_SRC_TIMEOUT="$(echo "$_json" | jq -S '.srcTimeout')"
		[[ "$OMNIA_SRC_TIMEOUT" =~ ^[1-9][0-9]*$ ]] || errors+=("Error - Src Timeout param is invalid, must be positive integer.")
		export OMNIA_SRC_TIMEOUT

		SETZER_TIMEOUT="$(echo "$_json" | jq -S '.setzerTimeout')"
		[[ "$SETZER_TIMEOUT" =~ ^[1-9][0-9]*$ ]] || errors+=("Error - Setzer Timeout param is invalid, must be positive integer.")
		export SETZER_TIMEOUT

		SETZER_CACHE_EXPIRY="$(echo "$_json" | jq -S '.setzerCacheExpiry')"
		[[ "$SETZER_CACHE_EXPIRY" =~ ^[1-9][0-9]*$ ]] || errors+=("Error - Setzer Cache Expiry param is invalid, must be positive integer.")
		export SETZER_CACHE_EXPIRY

		SETZER_MIN_MEDIAN="$(echo "$_json" | jq -S '.setzerMinMedian')"
		[[ "$SETZER_MIN_MEDIAN" =~ ^[1-9][0-9]*$ ]] || errors+=("Error - Setzer Minimum Median param is invalid, must be positive integer.")
		export SETZER_MIN_MEDIAN

		SETZER_ETH_RPC_URL="$(echo "$_json" | jq -r '.setzerEthRpcUrl')"
		[[ -n "$SETZER_ETH_RPC_URL" ]] || errors+=("Error - Setzer ethereum RPC address is not set.")
		export SETZER_ETH_RPC_URL
	elif [[ "$OMNIA_MODE" == "RELAY" ]]; then
		ETH_GAS=$(echo "$_json" | jq -r '.ethGas // ""')
		[[ -n "$ETH_GAS" ]] || ETH_GAS=200000
		export ETH_GAS
	fi

	[[ -z ${errors[*]} ]] || { printf '%s\n' "${errors[@]}"; return 1; }
}

