Alephium standalone
====

This repository builds a container image of [Alephium layer 1 blockchain](https://alephium.org) full node
based on the official [`alephium/alephium`](https://hub.docker.com/r/alephium/alephium/tags), wrapping the original entrypoint with [entrypoint-wrapper.sh](./entrypoint-wrapper.sh)
in order to add the features described below. The final images are available in [Docker Hub](https://hub.docker.com/r/touilleio/alephium-standalone/tags) under the
name `touilleio/alephium-standalone`.

# Features

- Provides a standalone script [snapshot-loader.sh](snapshot-loader.sh) to load the latest snapshot from [https://archives.alephium.org](https://archives.alephium.org) to speed up the initial sync, if not already sync'ed
- Ships a default [mainet user.conf](./user-mainnet.conf) with the following config:
  - Runs on port *39973* (instead of the default 9973) to be compatible with platforms such as [Flux](https://www.runonflux.io/)
  - Without [API key](https://wiki.alephium.org/full-node/Full-Node-More/#api-key)
  - A [testnet user.conf](./user-testnet.conf) is also available for [testing](https://wiki.alephium.org/network/testnet-guide).
- Check the sha256sum of the downloaded snapshot (using [tee-hash](https://github.com/touilleio/tee-hash) to do it all in one stream)

A basic [docker-compose.yml](./docker-compose.yml) show how to quickly run the container.

# Environment variables

| Environment variable           | Default                    | Description                                                                                                                                                                                                                     |
|--------------------------------|----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ALEPHIUM_HOME                  | `/alephium-home/.alephium` | Path, inside the official `alephium/alephium`, there the full node stores its data. See the official [Dockerfile.release](https://github.com/alephium/alephium/blob/master/docker/release/Dockerfile.release) for more details. |
| ALEPHIUM_NETWORK               | `mainnet`                  | Which network to load the snapshots for. Possible values are mainnet and testnet. !! If you set your own `user.conf`, this value should match `alephium.network.network-id` in `user.conf` !! (mainnet = 0, testnet = 1)        |
| ALEPHIUM_FORCE_RELOAD_SNAPSHOT | `0`                        | If set to `1`, the database will be dropped at every reboot. Useful for testing, not recommended in working setups.                                                                                                             |
| NODE_TYPE                      | `pruned`                   | Define which snapshot to load between the pruned or the full snapshots. Pruned snapshot decrease the resources rquirement to ~50GB of disk storage.                                                                      |

# Using the standalone script

Loading the snapshot in a dedicated folder `$ALEPHIUM_HOME` can be done manually using the script [snapshot-loader.sh](snapshot-loader.sh) as given below. Mind configuring `ALEPHIUM_HOME` and `ALEPHIUM_NETWORK` accordingly, and make sure `ALEPHIUM_HOME` is writable.

```
ALEPHIUM_HOME=/tmp
ALEPHIUM_NETWORK=testnet
curl -L https://github.com/touilleio/alephium-standalone/raw/main/snapshot-loader.sh | env ALEPHIUM_HOME=${ALEPHIUM_HOME} ALEPHIUM_NETWORK=${ALEPHIUM_NETWORK} sh
```

If the script completes, the snapshot has been successfully downloaded and is available in `${ALEPHIUM_HOME}/${ALEPHIUM_NETWORK}`.
You might need to change ownership of the files depending on what you'll do next.

```
chown nobody:nogroup -R "${ALEPHIUM_HOME}/${ALEPHIUM_NETWORK}"
```

For more details about [Alephium Archives](https://archives.alephium.org) and snapshot loading, go to the [official snapshot loading documentation](https://docs.alephium.org/full-node/loading-snapshot)

# One liner to launch the container

Mostly given as a reference, this *one liner* allows launching an Alephium full node in one line (if `docker` is installed):

```
ALEPHIUM_HOME=/tmp
ALEPHIUM_NETWORK=testnet
docker run -p 39973:39973 -p 127.0.0.1:12973:12973 \
  -v ${ALEPHIUM_HOME}:/alephium-home/.alephium \
  -e ALEPHIUM_NETWORK=${ALEPHIUM_NETWORK} touilleio/alephium-standalone:latest
```

This command is not production ready and extra care must be taken for running a productive full node.

# Wrapper script details

The [wrapper script](./entrypoint-wrapper.sh) contains lots of comments to make it understandable of what and how it is wrapping
the official [entrypoint.sh script](https://github.com/alephium/alephium/blob/master/docker/release/entrypoint.sh).

# Troubleshooting

## Restarting from scratch

If you want to restart from scratch and re-download the database, delete all what is inside your alephium data folder,
i.e. if you're using the provided [docker-compose.yml](./docker-compose.yml):

```
rm -r alephium-data/*
```

# Terraform setup

A terraform setup is provided for your convenience in the [terraform](./terraform) folder. Launch an AWS instance sync'ed
to the chain withing ~30 minutes by simply doing:

```
terraform apply
```

Please refer to the official [terraform doc](https://developer.hashicorp.com/terraform/tutorials) if needed.
