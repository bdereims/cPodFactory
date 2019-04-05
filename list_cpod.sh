#!/bin/bash
#bdereims@vmware.com

. ./env

DNSMASQ=/etc/dnsmasq.conf
HOSTS=/etc/hosts

main() {
	echo "=== List of cPods"
	#cat /etc/hosts | cut -f2 | grep "cpod-" | sed "s/cpod-//" | tr [:lower:] [:upper:]
	cat /etc/hosts | sed "s/#//" | awk '$2 ~ /cpod-/ {gsub(/cpod-/,""); print toupper($2),"("$3")"}'
}

main $1
