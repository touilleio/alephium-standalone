ARG RELEASE=v0.0.0
ARG IMAGE=alephium/alephium
ARG TARGETOS
ARG TARGETARCH

FROM golang:1.21-buster as builder

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go install github.com/touilleio/tee-hash@latest

FROM ${IMAGE}:${RELEASE}

USER root
RUN apt update && apt-get install -y bc && apt-get clean
USER nobody

COPY --from=builder /go/bin/tee-hash /usr/local/bin/tee-hash

# Remove empty user.conf from parent container
RUN rm -rf /alephium-home/.alephium/user.conf

COPY snapshot-loader.sh /snapshot-loader.sh
COPY entrypoint-wrapper.sh /entrypoint-wrapper.sh

COPY user-mainnet.conf /user-mainnet.conf
COPY user-testnet.conf /user-testnet.conf

EXPOSE 39973/tcp
EXPOSE 39973/udp

ENTRYPOINT ["/entrypoint-wrapper.sh"]
