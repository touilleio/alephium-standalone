#!/usr/bin/env sh

ALEPHIUM_HOME=${ALEPHIUM_HOME:-/alephium-home/.alephium}
ALEPHIUM_NETWORK=${ALEPHIUM_NETWORK:-mainnet}

./snapshot-loader.sh
ret=$?
if [ "$ret" != "0" ]
then
  echo "Loading the snapshot failed. See logs above for more details, apply recommended actions and retry"
  exit 1
fi

# Copy default user.conf if it does not exists already
if [ ! -f "$ALEPHIUM_HOME/user.conf" ]
then
    echo "Copying standalone user.conf file"
    cp "/user-$ALEPHIUM_NETWORK.conf" "$ALEPHIUM_HOME/user.conf"
fi

echo "Now starting Alephium full node!"

# Call the official entrypoint of the parent image `alephium/alephium`
exec /entrypoint.sh "$@"
