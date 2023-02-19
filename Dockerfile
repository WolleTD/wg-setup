FROM alpine:latest

RUN apk add --no-cache wireguard-tools kmod iproute2

ADD wg-setup wg-setup-client start.sh /usr/local/bin/

CMD [ "start.sh" ]
