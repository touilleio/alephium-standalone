version: "3"
services:
  broker:
    image: "${alephium_image}"
    restart: always
    ports:
      - 39973:39973/tcp
      - 39973:39973/udp
      - 10973:10973/tcp
      - 12973:12973/tcp
    security_opt:
      - no-new-privileges:true
    volumes:
      - ./alephium-data:/alephium-home/.alephium
      - ./alephium-wallets:/alephium-home/.alephium-wallets
    environment:
      - NODE_TYPE=${node_type}
      - ALEPHIUM_NETWORK=${network}
    labels:
      - org.label-schema.group=alephium
    logging:
      driver: "json-file"
      options:
        max-file: "10"
        max-size: 100m
