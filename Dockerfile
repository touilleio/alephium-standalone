ARG RELEASE=v1.4.6
ARG TARGETOS
ARG TARGETARCH

FROM golang:1.19-buster as builder

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go install github.com/touilleio/tee-hash@latest

FROM alephium/alephium:${RELEASE}

COPY --from=builder /go/bin/tee-hash /usr/local/bin/tee-hash

COPY snapshot-loader-entrypoint-wrapper.sh /snapshot-loader-entrypoint-wrapper.sh

COPY user-mainnet.conf /user-mainnet.conf
COPY user-testnet.conf /user-testnet.conf

EXPOSE 39973/tcp
EXPOSE 39973/udp

ENTRYPOINT ["/snapshot-loader-entrypoint-wrapper.sh"]
