FROM ethereum/client-go:stable

WORKDIR /home/geth

COPY ./docker/geth/data /home/geth/data
COPY ./docker/geth/config /home/geth/config
COPY ./docker/keystore /home/geth/keystore

EXPOSE 8545
EXPOSE 30303

# docker image has entrypoint and that's why we don't use CMD in here