FROM golang:1.12.7
WORKDIR /app
COPY . .
RUN apt-get update && \
apt-get install -y git ca-certificates && \
ls -alh && \
go build ./... && \
go install ./...
FROM debian:stretch
COPY --from=0 /go/bin/generate .
RUN apt update && apt install -y ca-certificates
CMD [ "./generate" ]