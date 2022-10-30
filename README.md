Alephium standalone
====

This repository builds a container image of [Alephium layer 1 blockchain](https://alephium.org) full node
based on the official `alephium/alephium`, wrapping the entrypoint with [snapshot-loader-entrypoint-wrapper.sh](./snapshot-loader-entrypoint-wrapper.sh)
in order to add the following features:

- Loads the latest snapshot from [https://archives.alephium.org](https://archives.alephium.org) to speed up the initial sync, if not already sync'ed
- Ships a default [mainet user.conf](./user-mainnet.conf) with the following config:
  - Runs on port *39973* (instead of the default 9973) to be compatible with platforms such as [Flux](https://www.runonflux.io/)
  - Without [API key](https://wiki.alephium.org/full-node/Full-Node-More/#api-key)
  - A [testnet user.conf](./user-testnet.conf) is also available for [testing](https://wiki.alephium.org/network/testnet-guide).

A basic [docker-compose.yml](./docker-compose.yml) show how to quickly run the container.

# Features and environment variable

| Environment variable           | Default                    | Description                                                                                                                                                                                                                     |
|--------------------------------|----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ALEPHIUM_HOME                  | `/alephium-home/.alephium` | Path, inside the official `alephium/alephium`, there the full node stores its data. See the official [Dockerfile.release](https://github.com/alephium/alephium/blob/master/docker/release/Dockerfile.release) for more details. |
| ALEPHIUM_NETWORK               | `mainnet`                  | Which network to load the snapshots for. Possible values are mainnet and testnet. !! If you set your own `user.conf`, this value should match `alephium.network.network-id` in `user.conf` !! (mainnet = 0, testnet = 1)        |
| ALEPHIUM_FORCE_RELOAD_SNAPSHOT | `0`                        | If set to `1`, the database will be dropped at every reboot. Useful for testing, not recommended in working setups.                                                                                                             |                                                                                                                                         |

# Wrapper script details

The [wrapper script](./snapshot-loader-entrypoint-wrapper.sh) contains lots of comments to make it understandable of what and how it is wrapping
the official [entrypoint.sh script](https://github.com/alephium/alephium/blob/master/docker/release/entrypoint.sh).
