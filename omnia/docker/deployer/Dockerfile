FROM golang:1.18-alpine3.15 as go-builder
RUN apk --no-cache add git

ARG CGO_ENABLED=0

WORKDIR /go/src/dapptools
ARG ETHSIGN_REF="master"
RUN git clone https://github.com/dapphub/dapptools.git . \
  && git checkout --quiet ${ETHSIGN_REF}

WORKDIR /go/src/dapptools/src/ethsign
RUN go mod tidy && \
  go mod download && \
  go build .

# Building gofer & spire
WORKDIR /go/src/oracle-suite
ARG ORACLE_SUITE_REF="tags/v0.5.2"
RUN git clone https://github.com/chronicleprotocol/oracle-suite.git . \
  && git checkout --quiet ${ORACLE_SUITE_REF}

RUN go mod tidy && \
  go mod download && \
  go build ./cmd/spire && \
  go build ./cmd/gofer && \
  go build ./cmd/ssb-rpc-client


FROM python:3.9.9-alpine3.15

RUN apk add --update --no-cache \
  jq curl git make perl g++ ca-certificates tree \
  bash bash-doc bash-completion \
  util-linux pciutils usbutils coreutils binutils findutils grep iproute2 \
  nodejs \
  && apk add --no-cache -X https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  jshon agrep datamash

# Installing setzer
ARG SETZER_REF="tags/v0.4.2"
RUN git clone https://github.com/chronicleprotocol/setzer.git \
  && cd setzer \
  && git checkout --quiet ${SETZER_REF} \
  && mkdir /opt/setzer/ \
  && cp -R libexec/ /opt/setzer/libexec/ \
  && cp -R bin /opt/setzer/bin \
  && cd .. \
  && rm -rf setzer

COPY ./docker/geth/bin/hevm-0.48.1 /usr/local/bin/hevm
COPY ./docker/geth/bin/solc-0.5.12 /usr/local/bin/solc

COPY --from=go-builder /go/src/dapptools/src/dapp/ /opt/dapp/
COPY --from=go-builder /go/src/dapptools/src/seth/ /opt/seth/

COPY --from=go-builder \
  /go/src/dapptools/src/ethsign/ethsign \
  /go/src/oracle-suite/spire \
  /go/src/oracle-suite/gofer \
  /go/src/oracle-suite/ssb-rpc-client \
  /usr/local/bin/

ENV PATH="/opt/dapp/bin:/opt/seth/bin:/opt/setzer/bin:${PATH}"

# Deployment sources
COPY ./docker/geth/bin/median-deploy /usr/local/bin/median-deploy
COPY ./docker/keystore /root/keystore

WORKDIR /home/dapp

RUN git clone --recurse-submodules https://github.com/makerdao/testchain-medians.git . \
  && dapp build

ENV ETH_RPC_URL=http://geth.local:8545
ENV ETH_GAS=7000000
ENV ETH_KEYSTORE=/root/keystore
ENV ETH_PASSWORD=/root/keystore/password
ENV ETH_FROM=0x1bb90cde8a032cb4963813a5b4db4981afa5b9c6

ENTRYPOINT []
CMD ["median-deploy", "BATUSD", "BTCUSD", "ETHUSD", "KNCUSD", "MANAUSD", "0x1bb90cde8a032cb4963813a5b4db4981afa5b9c6", "0x3980aa37f838bec2e457445d943feb3af98ff036"]