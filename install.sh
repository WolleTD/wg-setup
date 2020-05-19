#!/bin/bash -e

DESTDIR=${DESTDIR:-/usr/local}
SYSTEMD_UNIT=/etc/systemd/system/wg-setup.service

install-scripts() {
	echo "Install ${DESTDIR}/bin/wg-setup"
    install -m755 wg-setup ${DESTDIR}/bin/wg-setup
	echo "Install ${DESTDIR}/bin/wg-setup-service"
	install -m755 wg-setup-service ${DESTDIR}/bin/wg-setup-service
	echo "Install ${DESTDIR}/bin/wg-setup-use-token"
	install -m755 wg-setup-use-token ${DESTDIR}/bin/wg-setup-use-token
}

install-full() {
    install-scripts

    # DESTDIR isn't usable for /etc targets
	echo "Install /etc/sudoers.d/wg-setup"
	install -m600 system/wg-setup.sudoers /etc/sudoers.d/wg-setup

	if ! id wg-setup >/dev/null 2>&1; then
        echo "Adding wg-setup system user"
        useradd -rmd /var/lib/wg-setup -s /usr/bin/nologin wg-setup
    fi

	[[ -f "${SYSTEMD_UNIT}" ]] &&
        WG_PORT=$(awk -F\= '/Environment=PORT=/{print $3}' "${SYSTEMD_UNIT}")

    [[ -z "${WG_PORT}" ]] &&
        WG_PORT=${WG_PORT:-$(wg show | awk '/listening port/{print $3;exit 0}')}

	[[ -z "${WG_PORT}" ]] &&
		echo "WARNING: No WireGuard configuration found! Installing ${SYSTEMD_UNIT} without a port!"

    echo "Install ${SYSTEMD_UNIT}"
    install -m644 system/wg-setup.service ${SYSTEMD_UNIT}
    sed -i "s/WG_PORT/${WG_PORT}/" ${SYSTEMD_UNIT}
    systemctl daemon-reload
}

wireguard() {
    echo "Setting up WireGuard server using wg-setup-client"
    wg-setup-client --server $1
    echo "Installing wg-setup"
    install-full
}

uninstall() {
	echo "Remove ${DESTDIR}/bin/wg-setup"
	rm -f ${DESTDIR}/bin/wg-setup
	echo "Remove ${DESTDIR}/bin/wg-setup-service"
	rm -f ${DESTDIR}/bin/wg-setup-service
	echo "Remove ${DESTDIR}/bin/wg-setup-use-token"
	rm -f ${DESTDIR}/bin/wg-setup-use-token

    echo "Remove ${SYSTEMD_UNIT}"
    if [[ -f "${SYSTEMD_UNIT}" ]]; then
        systemctl disable --now wg-setup.service
        rm -f "${SYSTEMD_UNIT}"
        systemctl daemon-reload
    fi

    echo "Remove /etc/sudoers.d/wg-setup"
	rm -f /etc/sudoers.d/wg-setup

    echo "Remove wg-setup system user"
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
scripts)
    install-scripts
    ;;
wireguard|wg)
    wireguard
    ;;
*)
    echo "Available commands:

    install     Install wg-setup, including system user and service
    uninstall   Remove wg-setup, including system user and service
    scripts     Install only scripts, no users or config files
    wireguard   Full install, including setting up the WireGuard server with wg-setup-client"
    ;;
esac
