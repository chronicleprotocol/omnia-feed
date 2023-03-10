# Returns the estimated gas price and tip value as two numbers separated
# by a space. It requires three environmental variables to work:
# ETH_MAXPRICE_MULTIPLIER - float number
# ETH_TIP_MULTIPLIER - float number
# ETH_GAS_SOURCE - node or ethgasstation
getGasPrice() {
	[[ $ETH_MAXPRICE_MULTIPLIER =~ ^[0-9\.]+$  ]] || return 1
	[[ $ETH_TIP_MULTIPLIER =~ ^[0-9\.]+$  ]] || return 1

	# Getting price from a source

	local _fees
	_fees=($(getGasPriceFromNode))

	verbose "Sourced gas price" "source=$ETH_GAS_SOURCE" "maxPrice#=${_fees[0]}" "tip#=${_fees[1]}"

	# Handle issues with cast
	if  [[ ! ${_fees[0]} =~ ^[0-9\.]+$ ]]; then
		error "Error - Invalid GAS price received: ${_fees[0]}"
		return 1
	fi

	local _maxPrice
	_maxPrice=$(echo "(${_fees[0]} * $ETH_MAXPRICE_MULTIPLIER) / 1" | bc)
	local _tip
	if  [[ ${_fees[1]} =~ ^[0-9\.]+$ ]]; then
		_tip=$(echo "(${_fees[1]} * $ETH_TIP_MULTIPLIER) / 1" | bc)
	fi

  echo "$_maxPrice $_tip"
}

getGasPriceFromNode() {
	local _tip
	if [[ $ETH_TX_TYPE -eq 2 ]]
	then
		_tip=$(ethereum rpc eth_maxPriorityFeePerGas)
		if [[ ! $_tip =~ ^[0-9\.]+$ ]]; then
			echo 0
			return
		fi
	else
		_tip=0
	fi

  local _maxPrice
  _maxPrice=$(ethereum rpc eth_gasPrice)
  if [[ ! $_maxPrice =~ ^[0-9\.]+$ ]]; then
    echo 0
    return
  fi

  echo "$_maxPrice $_tip"
}
