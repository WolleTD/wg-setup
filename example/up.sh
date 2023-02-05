#!/bin/bash
set -e

touch wg-pubkey.env

echo "Starting WireGuard server..."
docker-compose up -d wg-server

while ! docker-compose logs wg-server | grep "PublicKey:"; do
    sleep 0.1
done
SERVER_KEY="$(docker-compose logs --no-log-prefix wg-server | awk '/PublicKey:/{print $2}')"

echo "WG_PKEY=${SERVER_KEY}" > wg-pubkey.env

echo "Starting WireGuard client..."
# Note: this may not work with some versions of docker-compose that unnecessarily recreate
# containers. I experienced this with v2.16.0 and my particular bug may be fixed in v2.16.1,
# but there seem to be older issues as well. See https://github.com/docker/compose/issues/9600
# as an entrypoint.
# If you experience any issues, run this line instead:
#docker-compose up -d wg-client nginx
# Though I refuse to make this the default, because I *expect* this line to work:
docker-compose up -d

while ! docker-compose logs wg-client 2>/dev/null | grep "wg-setup add-peer"; do
    sleep 0.1
done
ADD_CMD="$(docker-compose logs --no-log-prefix wg-client | grep "wg-setup add-peer")"

echo "Adding client to server..."
docker-compose exec wg-server ${ADD_CMD} -y

echo "Testing connection..."
docker-compose exec wg-client ping -c 1 172.16.10.1
docker-compose exec wg-client ping -c 2 172.16.10.1
docker-compose exec wg-server ping -c 2 172.16.10.2

echo "Trying to connect to nginx from the server"
docker-compose exec wg-server wget http://wg-client/

echo "==== If you can read this, everything seems to work. Yay! ===="
echo "The containers are still running, use docker-compose down to stop them."
