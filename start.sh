#!/bin/bash -eu

if [ -f /etc/wireguard/wg0.conf ]; then
	wg-quick up wg0
elif [ -z "${WG_LISTEN_PORT:-}" ]; then
	wg-setup-client -e $WG_PEER -p $WG_PKEY $WG_ADDR
else
	wg-setup-client -s $WG_ADDR $WG_LISTEN_PORT
fi

# We have no command, just keep the container running
trap 'wg-quick down wg0' EXIT
sleep infinity
