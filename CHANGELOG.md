# Changelog
Notable changes to this project will be documented below.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.13.2]

### Added

- Installer options
  - `--eth-gas` to set gas limit for relay blockchain transactions
  - `--eth-type` option to select blockchain group (`ethereum|optimism|arbitrum`, default: `ethereum`)
- Support for configurable external gas price sources for relays.

### Changed

- Upgraded dependencies
  - Omnia [`v1.13.3`](https://github.com/chronicleprotocol/omnia/releases/tag/v1.13.3)
  - Oracle Suite [`v0.7.2`](https://github.com/chronicleprotocol/oracle-suite/releases/tag/v0.7.2)
  - Setzer [`v0.6.1`](https://github.com/chronicleprotocol/setzer/releases/tag/v0.6.1)
- Updated Feed asset pairs
  - Removed `UNI/USD`
  - Added `RETH/USD` with [circuit breaker](https://github.com/chronicleprotocol/oracle-suite/blob/v0.7.2/pkg/price/provider/hooks.go#L77) capability
- New Maker Teleport parameters to account for config structure changes
- Updated Relay asset pairs
  - Added `RETH/USD` as a new target contract (median) for poke
- Updated Gofer price models
  - Removed `UNI/USD`
- Updated Spire (transport layer) accepted asset pairs leaving only
  <br>`["BTCUSD","ETHBTC","ETHUSD","LINKUSD","MANAUSD","MATICUSD","RETHUSD","WSTETHUSD","YFIUSD"]`

## [1.7.0] - 2021-07-28

### Added

- Introduce `--override-origin` option to enable for adding params to origins (e.g. API Key).
- MATIC/USD

### Changed

- Make sure `install-omnia` works with the new config structures of spire and gofer.

## [1.6.1] - 2021-07-07

### Fixed

- Fixed default configurations 

## [1.6.0] - 2021-06-15

### Added

- Introduced second transport method to allow for more resilient price updates.

[Unreleased]: https://github.com/chronicleprotocol/oracles/compare/v1.13.2...HEAD
[1.13.2]: https://github.com/chronicleprotocol/oracles/compare/v1.12.0...v1.13.2
[1.7.0]: https://github.com/chronicleprotocol/oracles/compare/v1.6.1...v1.7.0
[1.6.1]: https://github.com/chronicleprotocol/oracles/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/chronicleprotocol/oracles/releases/tag/v1.6.0
