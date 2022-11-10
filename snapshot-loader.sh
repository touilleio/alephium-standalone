#!/usr/bin/env sh

ALEPHIUM_HOME=${ALEPHIUM_HOME:-/alephium-home/.alephium}
ALEPHIUM_NETWORK=${ALEPHIUM_NETWORK:-mainnet}
ALEPHIUM_FORCE_RELOAD_SNAPSHOT=${ALEPHIUM_FORCE_RELOAD_SNAPSHOT:-0}

# If tee-hash (https://github.com/touilleio/tee-hash) is available, validates the checksum of the downloaded file.
# Do not validate the checksum otherwise
TEE_HASH_CMD=$(which cat)
VALIDATE_CHECKSUM=0
CHECKSUM_FILE=${CHECKSUM_FILE:-/var/tmp/sha256sum}
if which tee-hash >/dev/null
then
  TEE_HASH_CMD="tee-hash --output ${CHECKSUM_FILE}"
  VALIDATE_CHECKSUM=1
fi

# Checking for ALEPHIUM_HOME folder is writable
if [ ! -w "$ALEPHIUM_HOME" ]
then
    echo "Error: Data folder $ALEPHIUM_HOME is not writable by $(whoami). Please change ownership and/or permissions to $ALEPHIUM_HOME or its mount so $(whoami) can write on it, then relaunch"
    exit 1
fi

# Check ALEPHIUM_NETWORK environment variable value
if [ "$ALEPHIUM_NETWORK" != "mainnet" ] && [ "$ALEPHIUM_NETWORK" != "testnet" ]
then
    echo "Error: Network $ALEPHIUM_NETWORK is unsupported. Possible values are mainnet and testnet. Please fix the ALEPHIUM_NETWORK environment variable and relaunch"
    exit 1
fi

# Cleanup from previous run, if needed
rm -fr "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot" || true

if [ "${ALEPHIUM_FORCE_RELOAD_SNAPSHOT}" != "0" ]
then
    echo "Removing ${ALEPHIUM_NETWORK} network data"
    rm -rf "${ALEPHIUM_HOME:?}/$ALEPHIUM_NETWORK"
fi

# If the full node network data storage folder does not exist (i.e. first run of the full node), loading the snapshot
if [ ! -d "$ALEPHIUM_HOME/$ALEPHIUM_NETWORK" ]
then
    echo "Loading $ALEPHIUM_NETWORK snapshot from official https://archives.alephium.org"
    # Creating a temp folder (on the same volume) where snapshot will be loaded
    mkdir "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot"
    curl -L "$(curl -s https://s3.eu-central-1.amazonaws.com/archives.alephium.org/archives/$ALEPHIUM_NETWORK/full-node-data/_latest.txt)" | $TEE_HASH_CMD | tar xf - -C "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot"
    res=$?
    if [ "$res" != "0" ]; # If curl or tar command failed, stopping the load of the snapshot.
    then
      echo "Error: Loading and untar'ing the snapshot failed."
      exit 1
    fi
    if [ "${VALIDATE_CHECKSUM}" = "1" ]
    then
      # Check sha256 of what has been downloaded
      remote_sha256sum="$(curl -s https://s3.eu-central-1.amazonaws.com/archives.alephium.org/archives/$ALEPHIUM_NETWORK/full-node-data/_latest.txt.sha256sum)"
      local_sha256sum=$(cat "${CHECKSUM_FILE}")
      if [ "$remote_sha256sum" != "$local_sha256sum" ]
      then
        echo "Error: Checksum is not good."
        exit 1
      fi
    fi
    # If the loading of the snapshot went well on the temp folder, move it to its final location
    mv "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot/$ALEPHIUM_NETWORK" "$ALEPHIUM_HOME"
    # Cleanup to keep every thing nice and shiny
    rmdir "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot"
    echo "Loading $ALEPHIUM_NETWORK snapshot completed successfully in $ALEPHIUM_HOME/${ALEPHIUM_NETWORK}."
else
    echo "Folder $ALEPHIUM_HOME/$ALEPHIUM_NETWORK already exists, not loading the snapshot. If this is not expected, please manually remove the folder $ALEPHIUM_HOME/$ALEPHIUM_NETWORK or set ALEPHIUM_FORCE_RELOAD_SNAPSHOT=1 and restart"
fi
