FROM golang:1.18-alpine3.16 as go-builder
RUN apk --no-cache add git

ARG CGO_ENABLED=0

WORKDIR /go/src/omnia
ARG ETHSIGN_REF="tags/v1.13.3"
RUN git clone https://github.com/chronicleprotocol/omnia.git . \
  && git checkout --quiet ${ETHSIGN_REF} \
  && cd ethsign \
  && go mod vendor \
  && go build .

# Building gofer & spire
WORKDIR /go/src/oracle-suite
ARG ORACLE_SUITE_REF="tags/v0.9.0"
RUN git clone https://github.com/chronicleprotocol/oracle-suite.git . \
  && git checkout --quiet ${ORACLE_SUITE_REF}

RUN go mod vendor \
    && go build ./cmd/spire \
    && go build ./cmd/gofer \
    && go build ./cmd/ssb-rpc-client

FROM ghcr.io/chronicleprotocol/omnia_base:latest

RUN apk add --update --no-cache \
  jq curl git make perl g++ ca-certificates tree \
  bash bash-doc bash-completion \
  util-linux pciutils usbutils coreutils binutils findutils grep iproute2 \
  && apk add --no-cache -X https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  jshon agrep datamash

COPY --from=go-builder \
  /go/src/omnia/ethsign/ethsign \
  /go/src/oracle-suite/spire \
  /go/src/oracle-suite/gofer \
  /go/src/oracle-suite/ssb-rpc-client \
  /usr/local/bin/

RUN pip install --no-cache-dir mpmath sympy ecdsa==0.16.0

COPY ./omnia/bin /opt/omnia/bin/
COPY ./omnia/exec /opt/omnia/exec/
COPY ./omnia/lib /opt/omnia/lib/
COPY ./version /opt/omnia/version

# Installing setzer
ARG SETZER_REF="tags/v0.7.0"
RUN git clone https://github.com/chronicleprotocol/setzer.git \
  && cd setzer \
  && git checkout --quiet ${SETZER_REF} \
  && mkdir /opt/setzer/ \
  && cp -R libexec/ /opt/setzer/libexec/ \
  && cp -R bin /opt/setzer/bin \
  && cd .. \
  && rm -rf setzer

ENV HOME=/home/omnia

ENV OMNIA_CONFIG=${HOME}/omnia.json \
  SPIRE_CONFIG=${HOME}/spire.json \
  GOFER_CONFIG=${HOME}/gofer.json \
  ETH_RPC_URL=http://geth.local:8545 \
  ETH_GAS=7000000

COPY ./omnia/config/feed.json ${OMNIA_CONFIG}
COPY ./omnia/docker/spire/config/client_feed.json ${SPIRE_CONFIG}
COPY ./omnia/docker/gofer/client.json ${GOFER_CONFIG}

WORKDIR ${HOME}
COPY ./omnia/docker/keystore/ .ethereum/keystore/
# COPY ./omnia/docker/ssb-server/config/manifest.json .ssb/manifest.json
# COPY ./omnia/docker/ssb-server/config/secret .ssb/secret
# COPY ./omnia/docker/ssb-server/config/config.json .ssb/config

ARG USER=1000
ARG GROUP=1000
RUN chown -R ${USER}:${GROUP} ${HOME}
USER ${USER}:${GROUP}

# Setting up PATH for setzer and omnia bin folder
# Here we have set of different pathes included:
# - /opt/setzer - For `setzer` executable
# - /opt/omnia/bin - Omnia executables
# - /opt/omnia/exec - Omnia transports executables
ENV PATH="/opt/setzer/bin:/opt/omnia/bin:/opt/omnia/exec:${PATH}"

CMD ["omnia"]
