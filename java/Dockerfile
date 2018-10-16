FROM golang:1.9.4
WORKDIR /go/src/github.com/Cidan/dataflow-demo
ADD . /go/src/github.com/Cidan/dataflow-demo
RUN apt-get update && \
apt-get install -y git ca-certificates && \
mkdir -p /go/bin && \
curl https://glide.sh/get | sh && \
glide up && \
go build ./...
FROM debian:stretch
COPY --from=0 /go/src/github.com/Cidan/dataflow-demo/generate .
RUN apt update && apt install -y ca-certificates
CMD [ "./generate" ]