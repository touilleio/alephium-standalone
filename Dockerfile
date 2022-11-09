ARG RELEASE=v0.0.0
ARG IMAGE=alephium/alephium
ARG TARGETOS
ARG TARGETARCH

FROM golang:1.19-buster as builder

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go install github.com/touilleio/tee-hash@latest

FROM ${IMAGE}:${RELEASE}

COPY --from=builder /go/bin/tee-hash /usr/local/bin/tee-hash

COPY snapshot-loader.sh /snapshot-loader.sh
COPY entrypoint-wrapper.sh /entrypoint-wrapper.sh

COPY user-mainnet.conf /user-mainnet.conf
COPY user-testnet.conf /user-testnet.conf

EXPOSE 39973/tcp
EXPOSE 39973/udp

ENTRYPOINT ["/entrypoint-wrapper.sh"]
