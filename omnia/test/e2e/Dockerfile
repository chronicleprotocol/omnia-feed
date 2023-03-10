FROM ghcr.io/chronicleprotocol/omnia:dev

USER root

# Installing go
RUN apk add --no-cache make musl-dev go
# Configure Go
ENV GOROOT="/usr/lib/go" \
    GOPATH="/go" \
    PATH="/go/bin:$PATH"

# TMP
ENV SMOCKER_HOST="http://smocker.local"
ENV SMOCKER="${SMOCKER_HOST}:8080"

# setting setzer configs
ENV SETZER_CACHE_EXPIRY=-1 \
    SETZER_MIN_MEDIAN=3

# updating all available configs
ENV ORIGIN_THEGRAPH_URL=$SMOCKER \
 ORIGIN_BINANCE_URL=$SMOCKER \
 ORIGIN_BINANCE_US_URL=$SMOCKER \
 ORIGIN_BITFINEX_URL=$SMOCKER \
 ORIGIN_BITSTAMP_URL=$SMOCKER \
 ORIGIN_BITTHUMB_URL=$SMOCKER \
 ORIGIN_BITTREX_URL=$SMOCKER \
 ORIGIN_CMC_URL=$SMOCKER \
 ORIGIN_COINBASE_URL=$SMOCKER \
 ORIGIN_CRYPTOCOMPARE_URL=$SMOCKER \
 ORIGIN_DDEX_URL=$SMOCKER \
 ORIGIN_FTX_URL=$SMOCKER \
 ORIGIN_FX_URL=$SMOCKER \
 ORIGIN_GATEIO_URL=$SMOCKER \
 ORIGIN_GEMINI_URL=$SMOCKER \
 ORIGIN_HITBTC_URL=$SMOCKER \
 ORIGIN_HUOBI_URL=$SMOCKER \
 ORIGIN_KRAKEN_URL=$SMOCKER \
 ORIGIN_KUCOIN_URL=$SMOCKER \
 ORIGIN_KYBER_URL=$SMOCKER \
 ORIGIN_OKEX_URL=$SMOCKER \
 ORIGIN_POLONIEX_URL=$SMOCKER \
 ORIGIN_UPBIT_URL=$SMOCKER

# Omnia configuration
ENV OMNIA_INTERVAL=1 \
    OMNIA_MODE="FEED" \
    OMNIA_CONFIG="/app/test/e2e/config/feed.conf" \
    OMNIA_TRANSPORT_E2E_FILE="/app/test/e2e/transport.log"

ENV GETH_RPC_URL="http://geth.local:8545"

COPY ./test/e2e/bin/transport-e2e /usr/local/bin/
COPY ./test/e2e/bin/sign-message /usr/local/bin/
# Copy sources
COPY . /app

WORKDIR /app/test/e2e
RUN go mod download

CMD ["go", "test", "-v", "-p", "1", "./..."]
