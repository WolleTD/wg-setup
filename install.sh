#!/bin/bash -e

script_dir="${BASH_SOURCE[0]%/*}"
DESTDIR=${DESTDIR:-/usr/local}

echo "Install ${DESTDIR}/bin/wg-setup"
install -m755 ${script_dir}/wg-setup ${DESTDIR}/bin/wg-setup
