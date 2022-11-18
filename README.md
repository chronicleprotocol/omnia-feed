# oracles

## Summary

Oracle client written in bash that utilizes secure scuttlebutt for offchain message passing along with signed price data to validate identity and authenticity on-chain.

## Design Goals

Goals of this new architecture are:

1. Scalability,
2. Reduce costs by minimizing number of ethereum transactions and operations performed on-chain,
3. Increase reliability during periods of network congestion,
4. Reduce latency to react to price changes,
5. Make it easy to on-board price feeds for new collateral types, and
6. Make it easy to on-board new Oracles.

## Architecture

There are currently two main modules:

### Feed

Each Feed runs a Feed client which pulls prices redundantly with [Setzer]() and [Oracle Suite/Gofer](https://github.com/chronicleprotocol/oracle-suite), signs them with an ethereum private key, and broadcasts them as a message to the redundant p2p networks (e.g. scuttlebutt and libp2p).

### Relay

Relays monitor the broadcast messages, check for liveness, and homogenize the pricing data and signatures into a single ethereum transaction to be posted to the on-chain oracles.

## [Live Goerli Oracles]

See [./omnia/config/relay-goerli.conf](./omnia/config/relay-goerli.conf)

| Pair         | Oracle    |
|--------------|-----------|
| AAVE/USD | 0x48d9b9B980EcB23601E4cE5D0f828Ad1F3c8673f |
| BAL/USD | 0x0f18931AF4BD88a77640E86977E41691A6773C81 |
| BAT/USD | 0x559492e2D2CB96da572aB35b551049f2414039DB |
| BTC/USD | 0x586409bb88cF89BBAB0e106b0620241a0e4005c9 |
| COMP/USD | 0x41Bd42D1f64489a85CB552a9C122546bF0986399 |
| ETH/USD | 0xD81834Aa83504F6614caE3592fb033e4b8130380 |
| LINK/USD | 0xe4919256D404968566cbdc5E5415c769D5EeBcb0 |
| LRC/USD | 0x9D86EC8d17AC9F27B67626710e70598198c53846 |
| MANA/USD | 0xCCce898497e139831523cc9D23c948138dDF67f6 |
| MATIC/USD | 0x4b4e2a0b7a560290280f083c8b5174fb706d7926 |
| RETH/USD | 0x7eEE7e44055B6ddB65c6C970B061EC03365FADB3 |
| UNI/USD | 0xF87BE13f2b081d8D555f31d6bd6590Fd817a99FA |
| USDT/USD | 0x44084f056e9405FB41343ACb4E2E49f75b75640f |
| YFI/USD | 0x38D27Ba21E1B2995d0ff9C1C070c5c93dd07cB31 |
| ZRX/USD | 0x5C964118cD17B6b7b8a15C5De93b2E23c24d5789 |

## [Live Mainnet Oracles]

See [./omnia/config/relay.conf](./omnia/config/relay.conf)

| Pair         | Oracle    |
|--------------|-----------|
| BTC/USD | 0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f |
| ETH/BTC | 0x81A679f98b63B3dDf2F17CB5619f4d6775b3c5ED |
| ETH/USD | 0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85 |
| LINK/USD | 0xbAd4212d73561B240f10C56F27e6D9608963f17b |
| MANA/USD | 0x681c4F8f69cF68852BAd092086ffEaB31F5B812c |
| MATIC/USD | 0xfe1e93840D286C83cF7401cB021B94b5bc1763d2 |
| RETH/USD | 0xf86360f0127f8a441cfca332c75992d1c692b3d1 |
| WSTETH/USD | 0x2F73b6567B866302e132273f67661fB89b5a66F2 |
| YFI/USD | 0x89AC26C0aFCB28EC55B6CD2F6b7DAD867Fa24639 |


## Query Oracle Contracts

Query Oracle price Offchain

```
rawStorage=$(cast storage <ORACLE_CONTRACT> 0x1)
cast --from-wei $(cast --to-dec ${rawStorage:34:32})
```

Query Oracle Price Onchain

```
cast --from-wei $(cast --to-dec $(cast call <ORACLE_CONTRACT> "read()(uint256)"))
```

This will require the address you are submitting the query from to be whitelisted in the Oracle smart contract.

To get whitelisted on a Goerli Oracle please send an email to nik@chroniclelabs.org.

To get whitelisted on a Mainnet Oracle please submit a proposal in the Oracle section of the Maker Forum forum.makerdao.com
Your proposal will need to be ratified by MKR Governance to be enacted. Details of the proposal format can be found inside the Forum.

## Install with Nix

First you need `nix`:

```sh
curl -L https://nixos.org/nix/install | sh
. /home/<USER>/.nix-profile/etc/profile.d/nix.sh
```

Add Maker build cache:

```sh
nix run -f https://cachix.org/api/v1/install cachix -c cachix use maker
```

Then run the following to make the `omnia`, `ssb-server` and `install-omnia`
commands available in your user environment:

```sh
nix-env -i -f https://github.com/chronicleprotocol/oracles/tarball/v1.13.3 # update this to the latest version
```

Get the Scuttlebot private network keys (caps) from an admin and put it in a file
(e.g. called `~/caps.json`). The file should have the JSON format:


```json
{
	"shs": "<BASE64>",
	"sign": "<BASE64>"
}
```

You can use the `install-omnia` command to install Omnia as a `systemd`
service, update your `/etc/omnia.conf`, `~/.ssb/config` and migrate a
Scuttlebot secret and gossip log.


### Configuring a feed

To install and configure Omnia as a feed running with `systemd`:

```
install-omnia feed \
	--ssb-caps ~/caps.json \
	--ssb-external <your external ip here> \
	--eth-rpc <https://node1[:port]/path> \
	--eth-rpc <https://node2[:port]/path> \
	--eth-rpc <https://node3[:port]/path>
```

For more information about the install CLI:

```
install-omnia help
```

The installed Scuttlebot config can be found in `~/.ssb.config`, more details
about the [Scuttlebot config](https://github.com/ssbc/ssb-config#configuration).

## Relay Gas Price configuration

Adding a new configuration parameter to `ethereum` relay config section: `gasPrice`.
It consist of 3 available options: 

`source` - source of gas price. Default value: `node`

**There is currently only a single value available.** 

 - `node` - Getting Gas Price from node (using `cast gas-price`).

`multiplier` - A number the gas pice will be multiplied by after fetching. **Default value: 1**

**Example configuration:**

```json
{
  "mode": "relay",
  "ethereum": {
    "from": "0x",
    "keystore": "",
    "password": "",
    "network": "goerli",
    "gasPrice": {
      "source": "node",
      "multiplier": 1
		}
  },
  "transports":["ssb"],
  "feeds": [
    "0xdeadbeef123"
  ],
  ...
}
```

## Development

To build from inside this repo, clone and run:

```sh
nix-build
```

You can then run `omnia` from `./result/bin/omnia`.

To get a development environment with all dependencies run:

```sh
nix-shell
cd omnia
./omnia.sh
```

Now you can start editing the `omnia` scripts and run them directly.

### Update dependencies

To update dependencies like `setzer` use `niv` e.g.:

```sh
nix-shell
niv show
niv update setzer
```

To update NodeJS dependencies edit the `nix/node-packages.json` file and run:

```sh
nix-shell
updateNodePackages
```

### Staging and release process

To create a release candidate (RC) for staging, typically after a PR has
passed its smoke and regression tests and is merged into `master`, checkout
`master` and run:

```sh
nix-shell --run "release minor"
```

This should bump the version of `omnia` by Semver version level `minor`
and create a new release branch with the resulting version
(e.g. `release/1.1`) and a tag with the suffix `-rc` which indicates a
release candidate that is ready for staging.

When a release candidate has been tested in staging and is deemed stable you can
run the same command in the release branch but without the Semver version level:

```sh
nix-shell --run release
```

This should add a Git tag to the current commit with its current version
(without suffix) and move the `stable` tag there also.
