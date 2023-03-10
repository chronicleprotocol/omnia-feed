transportPublish() {
	local _assetPair="$1"
	local _message="$2"
	local _succ=0
	for _publisher in "${OMNIA_TRANSPORTS[@]}"; do
		log "Publishing $_assetPair price message with $_publisher"
		if "transport-$_publisher" push "$_message"; then
			((_succ++))
		else
			error "Failed publishing message" "asset=$_assetPair" "transport=$_publisher"
		fi
	done

	[[ $_succ -gt 0 ]]
}

transportPull() {
	local _feed="$1"
	local _assetPair="$2"
	_assetPair=${_assetPair/\/}
	_assetPair=${_assetPair^^}
	local _puller
	local _msg
	local -A _msgs

	for _puller in "${OMNIA_TRANSPORTS[@]}"; do
		log "Pulling $_assetPair price message with $_puller"
		if _msg=$("transport-$_puller" pull "$_feed" "$_assetPair" | jq -c)
		then
			if [[ -n "$_msg" ]]
			then
				_msgs["$_puller"]="$_msg"
				verbose "Received message" "transport=$_puller" "asset=$_assetPair" "feed=$_feed"
			else
				warning "No message received" "transport=$_puller" "asset=$_assetPair" "feed=$_feed"
			fi
		else
			error "Failed pulling $_assetPair price from feed $_feed with $_puller"
		fi
	done

	# Return the latest of the messages pulled.
	jq -sec 'max_by(.time)' <<<"${_msgs[@]}"
}