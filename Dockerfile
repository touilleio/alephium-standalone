FROM --platform=$BUILDPLATFORM golang:1.19-buster as builder

ARG TARGETOS
ARG TARGETARCH

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go install github.com/touilleio/tee-hash@latest

FROM alephium/alephium:v1.4.6

COPY --from=builder /go/bin/tee-hash /usr/local/bin/tee-hash

COPY snapshot-loader-entrypoint-wrapper.sh /snapshot-loader-entrypoint-wrapper.sh

COPY user-mainnet.conf /user-mainnet.conf
COPY user-testnet.conf /user-testnet.conf

ENTRYPOINT ["/snapshot-loader-entrypoint-wrapper.sh"]
