# Omnia

[![Omnia Tests](https://github.com/chronicleprotocol/omnia/actions/workflows/test.yml/badge.svg)](https://github.com/chronicleprotocol/omnia/actions/workflows/test.yml)
[![Build & Push Docker Image](https://github.com/chronicleprotocol/omnia/actions/workflows/docker.yml/badge.svg)](https://github.com/chronicleprotocol/omnia/actions/workflows/docker.yml)

For more information on running oracles see: https://github.com/chronicleprotocol/oracles

## Quickstart

Some convenience targets for `make` are available. If you have Docker installed, you can do

```
make build          # build all the images
make run            # run images after they're built
make test           # build and run integration tests
```

## Working with Docker

We introduced Docker environment for local omnia development.

Please follow several steps to build and run it.

#### Building omnia image

NOTE: You have to build it from repo root.

```bash
$ docker build -t omnia -f docker/omnia/Dockerfile .
```

Running omnia with your local environment:

```bash
$ doc run -it --rm -v "$(pwd)"/lib:/home/omnia/lib -v "$(pwd)"/test:/home/omnia/test omnia /bin/bash
```

It will start bash session into docker comtainer with mounted `lib` and `test` folders.

To run `omnia` in container from prev command you can use `omnia` command:

```bash
$ omnia
Importing configuration from /home/omnia/config/feed.json...
```

## SSB Image requirements

`node:lts-alpine` has some major changes and now it does not include `python` and `make` anymore.
So we will have to rework SSB images.

For now it requires special Docker `node` base image.
So before building this image run command:

```bash
$ doc pull node:lts-alpine3.14@sha256:366c71eebb0da62a832729de2ffc974987b5b00ab25ed6a5bd8d707219b65de4
```

## Docker compose
For even more easy development we providing you with `docker-compose.yml` file that will help to set everything up for you.

Right now it contains `omnia_feed` container. 
It contains working feed configuration + spire integration.

And `spire` container with configured spire agent that will be called from `omnia_feed`.

**Where to take `chroniclelabs/spire:latest` image ?**
For now you have to build it manually from [Oracle Suite](https://github.com/makerdao/oracle-suite) repo.
Command for building image:

```bash
$ docker build -t chroniclelabs/spire:latest -f Dockerfile-spire .
```

Example of usage: 

1. Starting Spire Agent

```bash
$ docker-compose up -d spire
```

2. Running omnia with bash:

```bash
$ docker-compose run --rm omnia_feed /bin/bash
```

## Running Unit Tests

For simplicity we create unit tests runner inside docker container. 
So to run unit tests in fresh environment you can use this command: 

```bash
$ docker-compose -f .github/docker-compose-unit-tests.yml run --rm omnia_unit_tests
```

It will create fresh omnia container, mount all your local sources and run tests from `test/units` folder.
Example output: 

```bash
Creating github_omnia_unit_tests_run ... done
======================================
Running: /home/omnia/test/units/config.sh
======================================
TAP version 13
1..10
ok 1 - importGasPrice should correctly parse values > run importGasPrice {"from":"0x","keystore":"","password":"","network":"mainnet","gasPrice":{"source":"node","multiplier":1,"priority":"fast"}}
ok 2 - ETH_GAS_SOURCE should have value: ethgasstation > match ^node
ok 3 - ETH_MAXPRICE_MULTIPLIER should have value: 1 > match ^1$
ok 4 - ETH_TIP_MULTIPLIER should have value: 1 > match ^1$
ok 5 - ETH_GAS_PRIORITY should have value: slow > match ^fast
...
```

### Running E2E Tests

For E2E tests you need Docker to be installed and some basic predefined tools.
We use `smocker` for mocking Exchange API requests/responses and local `geth` for omnia relay tests.
To setup environment you can use this command:

```bash
$ docker-compose -f .github/docker-compose-e2e-tests.yml run omnia_e2e 
```

### E2E Tests for Development

First of all for E2E tests we are using special image `ghcr.io/chronicleprotocol/omnia:dev`.
And to use it with your locl omnia version - you have to build it by yourself.

```bash
$ docker build -t ghcr.io/chronicleprotocol/omnia:dev .
```

If you already have this image on your local machine - you have to rebuild it!

```bash
$ docker rmi ghcr.io/chronicleprotocol/omnia:dev
```

For tests development process we created additional image `omnia_e2e_dev` that will be built
from your current environment and will link local `lib`, `exec` and `transport-e2e` volumes.
**NOTE:** This image will be built on `ghcr.io/chronicleprotocol/omnia:dev`, see `test/e2e/Dockerfile`.

Run it:

```bash
$ docker-compose -f .github/docker-compose-e2e-tests.yml run --rm omnia_e2e_dev
```

It will start `bash` session inside omnia dev container with mounted folders.
From here you might run E2E tests using command: 

```bash
$ go test -v -p 1 -parallel 1 -cpu 1 ./...
```

#### Running omnia feed tests

```bash
$ go test -v -p 1 -parallel 1 -cpu 1 ./feed
```

#### Running omnia Relayer tests

```bash
$ go test -v -p 1 -parallel 1 -cpu 1 ./relay
```

**NB !!!**
If our machine wouldn't be able to build `omnia_e2e_dev` with error: 

```bash
Building omnia_e2e_dev
Step 1/16 : FROM ghcr.io/chronicleprotocol/omnia:dev
ERROR: Service 'omnia_e2e_dev' failed to build : Head "https://ghcr.io/v2/chronicleprotocol/omnia/manifests/dev": denied
```

It mean you have to pull `ghcr.io/chronicleprotocol/omnia:dev` or build it locally using command: 

```bash
$ docker build -t ghcr.io/chronicleprotocol/omnia:dev .
```

## Docker integration

#### Building Omnia with custom dependencies

For production use we building Omnia with predefined locked to tags dependencies:

| Dependency  | Version               | Argument name      | Repository                                        |
|-------------|-----------------------|--------------------|---------------------------------------------------|
| Eth Sign    | `tags/ethsign/0.17.0` | `ETHSIGN_REF`      | https://github.com/dapphub/dapptools              |
| Gofer       | `tags/v0.4.6`         | `ORACLE_SUITE_REF` | https://github.com/chronicleprotocol/oracle-suite |
| Spire       | `tags/v0.4.6`         | `ORACLE_SUITE_REF` | https://github.com/chronicleprotocol/oracle-suite |
| Setzer      | `tags/v0.4.2`         | `SETZER_REF`       | https://github.com/chronicleprotocol/setzer       |

We using git reference format to be able to use custom versions/commits for DEV builds.
If you need to build omnia with custom version you can use [Docker ARGs](https://docs.docker.com/engine/reference/builder/#arg) to do this.

Example: 

```bash
$ docker build --build-arg ETHSIGN_REF=tags/ethsign/0.16.0 --build-arg SETZER_REF=8819397c3ebd7cf48fac7a3f5ce29985404f9354 -t omnia_custom .
```

#### Omnia Configuration

Dockerized Omnia default configuration:

| Env Var        | Default value            | Description                        |
|----------------|--------------------------|------------------------------------|
| `OMNIA_CONFIG` | `/home/omnia/omnia.json` | Omnia configuration file           |
| `SPIRE_CONFIG` | `/home/omnia/spire.json` | Spire configuration file           |
| `GOFER_CONFIG` | `/home/omnia/gofer.json` | Gofer configuration file           |
| `ETH_RPC_URL`  | `http://geth.local:8545` | Setzer requirement for wstETH pair |
| `ETH_GAS`      | `7000000`                | Gofer configuration file           |


To set custom configuration values use [ENV (environment variables)](https://docs.docker.com/engine/reference/run/#env-environment-variables)

Example:

```bash
$ docker run -e "ETH_GAS=28282828282" -e "OMNIA_INTERVAL=15" ghcr.io/chronicleprotocol/omnia:latest
```

Configuration files might be provided by mounting it into Docker container. 

Example: 

Replacing existing file:

```bash
$ docker run -v $(pwd)/omnia_config.json:/home/omnia/omnia.json ghcr.io/chronicleprotocol/omnia:latest
```

Setting new configuration file:
You will have to rewrite `OMNIA_CONFIG` env var.

```bash
$ docker run -v $(pwd)/omnia_config.json:/home/omnia/omnia_config.json -e OMNIA_CONFIG=/home/omnia/omnia_config.json ghcr.io/chronicleprotocol/omnia:latest
```
