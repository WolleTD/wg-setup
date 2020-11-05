#!/bin/bash -e
# WireGuard is currently not available in Raspbian repositories,
# so we have to build the DKMS module from debian/sid
[[ $UID -eq 0 ]] || { echo "Must run as root!" >&2; exit 1; }
echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/deb-unstable.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138
echo -e "Package: *\nPin: release a=unstable\nPin-Priority: 90" > /etc/apt/preferences.d/limit-unstable
apt-get update
apt-get install -y raspberrypi-kernel-headers wireguard-dkms wireguard-tools
