## Deployer image for test medianizer contract

Contains list of preinstalled tools required for building and running omnia Docker images.

List of preinstalled tools:
 - bash 
 - jq 
 - curl 
 - git 
 - nodejs 
 - npm
 - python3 
 - make 
 - jshon
 - hevm v0.48.1
 - solc v0.5.12
 - ethsign v0.17.0
 - cast 
 - setzer ref/b9ddabde9bba61d29a3694ba15b657e36c84b3e7
 - gofer v0.4.6
 - ssb

### Prebuilding image locally

```bash
$ docker build -t ghcr.io/chronicleprotocol/deployer -f ./docker/deployer/Dockerfile .
```

### Running deployment on testchain

First you need to start `geth` node. 

```
docker run -it --rm -e "ETH_RPC_URL=http://your_geth_url_or_ip:8545" ghcr.io/chronicleprotocol/deployer
```

**NB !!!**
If you start it using `docker-compose.yml` from this repo (using `docker-compose up -d geth`) 
It will create it's own network `omnia_network` and you will have to start `deployer` in same network ! 

Use this command:

```
docker run -it --rm --network="omnia_network" -e "ETH_RPC_URL=http://geth.local:8545" ghcr.io/chronicleprotocol/deployer
```
