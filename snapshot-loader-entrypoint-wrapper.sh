#!/usr/bin/env sh

ALEPHIUM_HOME=${ALEPHIUM_HOME:-/alephium-home/.alephium}
ALEPHIUM_NETWORK=${ALEPHIUM_NETWORK:-mainnet}
ALEPHIUM_FORCE_RELOAD_SNAPSHOT=${ALEPHIUM_FORCE_RELOAD_SNAPSHOT:-0}

# Checking for ALEPHIUM_HOME folder permissions
if [ ! -w "$ALEPHIUM_HOME" ]
then
    echo "Data folder $ALEPHIUM_HOME is not writable. Please chmod/chown it so $(whoami) can write on it and relaunch"
    exit 1
fi

# Check ALEPHIUM_NETWORK environment variable
if [ ! -f "/user-$ALEPHIUM_NETWORK.conf" ]
then
    echo "Network $ALEPHIUM_NETWORK is unsupported. Possible values are mainnet or testnet. Please fix the ALEPHIUM_NETWORK environment variable and relaunch"
    exit 1
fi

# Copy own user.conf if it does not exists already
if [ ! -f "$ALEPHIUM_HOME/user.conf" ]
then
    echo "Copying standalone user.conf file"
    cp /user-$ALEPHIUM_NETWORK.conf "$ALEPHIUM_HOME/user.conf"
fi

# Cleanup from previous run, if needed
rm -fr "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot" || true

if [ "${ALEPHIUM_FORCE_RELOAD_SNAPSHOT}" != "0" ]
then
    echo "Removing ${ALEPHIUM_NETWORK} network data"
    rm -rf "$ALEPHIUM_HOME/$ALEPHIUM_NETWORK"
fi

if [ ! -d "$ALEPHIUM_HOME/$ALEPHIUM_NETWORK" ]
then
    echo "Loading $ALEPHIUM_NETWORK snapshot from official https://archives.alephium.org"
    mkdir "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot"
    curl -L $(curl -s https://s3.eu-central-1.amazonaws.com/archives.alephium.org/archives/$ALEPHIUM_NETWORK/full-node-data/_latest.txt) | tar xf - -C "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot"
    mv "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot/$ALEPHIUM_NETWORK" "$ALEPHIUM_HOME"
    rmdir "$ALEPHIUM_HOME/${ALEPHIUM_NETWORK}-snapshot"
    echo "Loading $ALEPHIUM_NETWORK snapshot completed. Starting broker now"
else
    echo "Folder $ALEPHIUM_HOME/$ALEPHIUM_NETWORK alredy exists, not loading the snapshot. If this is not expected, please manualy remove the folder $ALEPHIUM_HOME/$ALEPHIUM_NETWORK or set ALEPHIUM_FORCE_RELOAD_SNAPSHOT=1 and restart "
fi

exec /entrypoint.sh $@
