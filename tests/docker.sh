#!/bin/bash
set -e

docker build -t wg-setup:latest ..
shared=$(mktemp -d)
echo "Setting up WireGuard server..."
docker run -d --name wg-server --rm --cap-add NET_ADMIN -v ${shared}:/var/lib/wg-setup \
    wg-setup:latest bash -c "
    set -xe
    umask 000
    /root/wg-setup/install.sh wireguard 172.16.20.1/24 12345
    wg | awk '/public key/{print \$3}' > /var/lib/wg-setup/pubkey
    nc -l 172.16.20.1 9999 > /var/lib/wg-setup/nc-out" >/dev/null

while [[ ! -f ${shared}/pubkey ]]; do
    sleep 0.1
done

trap "docker kill wg-server wg-client >/dev/null 2>&1" ERR

echo "Setting up client..."
docker run -d --name wg-client --rm -v ${shared}:/var/lib/wg-setup --cap-add NET_ADMIN \
    wg-setup:latest bash -c "
    set -xe
    umask 000
    /root/wg-setup/wg-setup-client -p $(<${shared}/pubkey) \
        -e 172.17.0.2:12345 172.16.20.2/24 | tail -1 > /var/lib/wg-setup/client-setup
    touch /var/lib/wg-setup/client-done
    nc -l 127.0.0.1 9998" >/dev/null

while [[ ! -f ${shared}/client-done ]]; do
    sleep 0.1
done

echo "Adding client to server..."
echo "Y" | docker exec -i wg-server $(<${shared}/client-setup) >/dev/null

echo "Testing connection..."
docker exec wg-client ping -c 1 172.16.20.1
docker exec wg-client ping -c 2 172.16.20.1
docker exec wg-server ping -c 2 172.16.20.2
echo "XXXX" | docker exec -i wg-client nc -N 172.16.20.1 9999

[[ "$(<${shared}/nc-out)" == "XXXX" ]]
echo "Success!"
! docker exec wg-client nc -N 127.0.0.1 9998
rm -rf ${shared}
