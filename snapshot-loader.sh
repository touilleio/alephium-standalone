#!/usr/bin/env sh

ALEPHIUM_HOME=${ALEPHIUM_HOME:-/alephium-home/.alephium}
ALEPHIUM_NETWORK=${ALEPHIUM_NETWORK:-mainnet}
ALEPHIUM_FORCE_RELOAD_SNAPSHOT=${ALEPHIUM_FORCE_RELOAD_SNAPSHOT:-0}
# Node type: full or pruned. Any other value might cause unexpected behaviour
NODE_TYPE=${NODE_TYPE:-pruned}
INDEXES_TYPE=${INDEXES_TYPE:-with}

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

# Check if ALEPHIUM_HOME folder is writable
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

    # Check if enough disk space available
    availableSpace=$(df -B1 "$ALEPHIUM_HOME" | tail -n 1 | awk '{print $4}' | head -n 1)
    neededSpace=$(curl -s -I -L "$(curl -sL https://archives.alephium.org/archives/$ALEPHIUM_NETWORK/${NODE_TYPE}-node-data/_latest_${INDEXES_TYPE}-indexes.txt)" | grep -i 'Content-Length:' | awk '{print $2}' | tr -d '\r')
    neededSpaceWithMargin=$(echo "${neededSpace} * 1.2 / 1" | bc)
    neededSpaceInGB=$(echo "${neededSpaceWithMargin} / 1000 / 1000 / 1000 / 1" | bc)
    availableSpaceInGB=$(echo "${availableSpace} / 1000 / 1000 / 1000 / 1" | bc)
    if [ "$neededSpaceWithMargin" -gt "$availableSpace" ]; then
        echo "Error: Not enough available storage space in ${ALEPHIUM_HOME}. Only ${availableSpaceInGB} GB (${availableSpace} bytes) available but at least ${neededSpaceInGB} GB (${neededSpaceWithMargin} bytes) are needed."
        echo "Please add more storage to ${ALEPHIUM_HOME}."
        exit 1
    fi

    echo "Loading $ALEPHIUM_NETWORK snapshot from official https://archives.alephium.org"
    # Creating a temp folder (on the same volume) where snapshot will be loaded
    mkdir "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot"
    curl -L "$(curl -sL https://archives.alephium.org/archives/$ALEPHIUM_NETWORK/${NODE_TYPE}-node-data/_latest_${INDEXES_TYPE}-indexes.txt)" | $TEE_HASH_CMD | tar xf - -C "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot"
    res=$?
    if [ "$res" != "0" ]; # If curl or tar command failed, stopping the load of the snapshot.
    then
      echo "Error: Loading and untar'ing the snapshot failed."
      exit 1
    fi
    if [ "${VALIDATE_CHECKSUM}" = "1" ]
    then
      # Check sha256 of what has been downloaded
      remote_sha256sum="$(curl -sL https://archives.alephium.org/archives/$ALEPHIUM_NETWORK/${NODE_TYPE}-node-data/_latest_${INDEXES_TYPE}-indexes.txt.sha256sum)"
      local_sha256sum=$(cat "${CHECKSUM_FILE}")
      if [ "$remote_sha256sum" != "$local_sha256sum" ]
      then
        echo "Error: Checksum is not good. expected ${remote_sha256sum}, got ${local_sha256sum}"
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
