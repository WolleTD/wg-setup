#!/bin/bash
set -e

DOCKERIMAGE="wolletd/wg-setup:latest"

docker build -t "$DOCKERIMAGE" ..

# Create a new network for the test to have DNS resolving
docker network create wg-test >/dev/null

trap "docker stop wg-server wg-client >/dev/null 2>&1; docker network rm wg-test >/dev/null" EXIT

echo "Setting up WireGuard server..."
docker run -d \
    --name wg-server \
    --network wg-test \
    --rm \
    --cap-add NET_ADMIN \
    -e WG_ADDR="172.16.20.1/24" \
    -e WG_LISTEN_PORT=12345 \
    "$DOCKERIMAGE" >/dev/null

while ! docker logs wg-server 2>/dev/null | grep "PublicKey:"; do
    sleep 0.1
done
SERVER_KEY="$(docker logs wg-server | awk '/PublicKey:/{print $2}')"

echo "Setting up client..."
docker run -d \
    --name wg-client \
    --network wg-test \
    --rm \
    --cap-add NET_ADMIN \
    -e WG_ADDR="172.16.20.2/24" \
    -e WG_PKEY="${SERVER_KEY}" \
    -e WG_PEER="wg-server:12345" \
    "$DOCKERIMAGE" >/dev/null

while ! docker logs wg-client 2>/dev/null | grep "wg-setup add-peer"; do
    sleep 0.1
done
ADD_CMD="$(docker logs wg-client | grep "wg-setup add-peer")"

echo "Adding client to server..."
docker exec wg-server ${ADD_CMD} -y

echo "Testing connection..."
docker exec wg-client ping -c 1 172.16.20.1
docker exec wg-client ping -c 2 172.16.20.1
docker exec wg-server ping -c 2 172.16.20.2

echo "Success!"
rm -rf ${shared}
