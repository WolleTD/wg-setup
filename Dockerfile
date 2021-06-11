FROM alpine:latest

RUN apk add --no-cache wireguard-tools netcat-openbsd
COPY . /root/wg-setup/
