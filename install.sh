#!/bin/bash -e

script_dir="${BASH_SOURCE[0]%/*}"
DESTDIR=${DESTDIR:-/usr/local}
SYSTEMD_UNIT=/etc/systemd/system/wg-setup.service

install-wgs() {
    echo "Install ${DESTDIR}/bin/wg-setup"
    install -m755 ${script_dir}/wg-setup ${DESTDIR}/bin/wg-setup
}

wireguard() {
    echo "Setting up WireGuard server using wg-setup-client"
    ${script_dir}/wg-setup-client --server "$@"
    echo "Installing wg-setup"
    install-wgs
}

uninstall() {
    echo "Remove ${DESTDIR}/bin/wg-setup"
    rm -f ${DESTDIR}/bin/wg-setup
}

cmd=${1:-install}

case "${cmd}" in
install)
    install-wgs
    ;;
uninstall|remove)
    uninstall
    ;;
wireguard|wg)
    shift
    wireguard "$@"
    ;;
*)
    echo "Available commands:

    install     Install wg-setup
    uninstall   Remove wg-setup
    wireguard   Set up WireGuard server with wg-setup-client and install wg-setup"
    ;;
esac
