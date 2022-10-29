FROM alephium/alephium:v1.4.6

COPY snapshot-loader-entrypoint-wrapper.sh /snapshot-loader-entrypoint-wrapper.sh

COPY user-mainnet.conf /user-mainnet.conf
COPY user-testnet.conf /user-testnet.conf

ENTRYPOINT ["/snapshot-loader-entrypoint-wrapper.sh"]
