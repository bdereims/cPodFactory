#/bin/bash

PEM_FILE=haproxy/conf/cpodedge.pem
DOMAIN="cloud-garage.net"
ACME=~/.acme.sh/${DOMAIN}

cat ${ACME}/fullchain.cer ${ACME}/${DOMAIN}.key > ${PEM_FILE}
