FROM alpine:latest

RUN apk add --no-cache wireguard-tools gawk netcat-openbsd
COPY . /root/wg-setup/
