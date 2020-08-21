#!/bin/bash -e
FILE="/usr/local/share/vpn-hosts.txt"

[[ -f "${FILE}" ]] && cp "${FILE}" "${FILE}.bak"
cat > "${FILE}" <<EOF
172.20.0.0/16       Whole network
172.20.0.1          Server

172.20.1.0/24       Internal
172.20.2.0/24       Group A
172.20.16.0/24      Group B

ALL CLIENTS
EOF
wg-setup list-peers | sort -V >> "${FILE}"
