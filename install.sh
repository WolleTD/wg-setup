#!/bin/bash -e

DESTDIR=${DESTDIR:-/usr/local}
SYSTEMD_UNIT=/etc/systemd/system/wg-setup.service

install() {
	echo "Install ${DESTDIR}/bin/wg-setup"
    install -m755 wg-setup ${DESTDIR}/bin/wg-setup
}

wireguard() {
    echo "Setting up WireGuard server using wg-setup-client"
    wg-setup-client --server $1
    echo "Installing wg-setup"
    install
}

uninstall() {
	echo "Remove ${DESTDIR}/bin/wg-setup"
	rm -f ${DESTDIR}/bin/wg-setup
	rm -f ${DESTDIR}/bin/wg-setup-service
	rm -f ${DESTDIR}/bin/wg-setup-use-token
    if [[ -f "${SYSTEMD_UNIT}" ]]; then
        systemctl disable --now wg-setup.service
        rm -f "${SYSTEMD_UNIT}"
        systemctl daemon-reload
    fi
	rm -f /etc/sudoers.d/wg-setup
	if id wg-setup >/dev/null 2>&1; then
        userdel -r wg-setup 2>/dev/null
    fi
}

cmd=${1:-install}

case "${cmd}" in
install|full)
    install-full
    ;;
uninstall|remove)
    uninstall
    ;;
wireguard|wg)
    wireguard
    ;;
*)
    echo "Available commands:

    install     Install wg-setup
    uninstall   Remove wg-setup
    wireguard   Set up WireGuard server with wg-setup-client and install wg-setup"
    ;;
esac
