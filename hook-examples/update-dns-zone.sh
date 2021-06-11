#!/bin/bash -e
ZONE="example.org"
FILE="/var/named/${ZONE}.zone"

[[ -f "${FILE}" ]] && cp "${FILE}" "${FILE}.bak"
sed "s/ZONESERIAL/$(date +%Y%m%d%H)/" > "${FILE}" <<EOF
\$TTL 7200
; ${ZONE}
${ZONE}.   IN      SOA     ns.${ZONE}. postmaster.${ZONE}. (
                                                ZONESERIAL  ; Serial
                                                28800       ; Refesh
                                                1800        ; Retry
                                                604800      ; Expire
                                                86400 )     ; Minimum
${ZONE}.            IN   NS   ns
ns                       IN   A    172.20.0.1
gateway                  IN   A    172.20.0.1
EOF
wg-setup list-peers dns-zone | sort -V >> "${FILE}"
rndc reload
