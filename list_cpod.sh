#!/bin/bash
#bdereims@vmware.com

. ./env

LHEADER=$( echo ${HEADER} | tr '[:upper:]' '[:lower:]' )

main() {
	echo "=== List of cPods"
<<<<<<< HEAD
	for CPOD in $( cat ${HOSTS} | grep "${LHEADER}-" | awk '{print $2}' ); do
=======
	for CPOD in $( cat ${HOSTS} | grep ${LHEADER} | awk '{print $2}' ); do
>>>>>>> d3b44815b50d52d2eeb89ce85f205cc6104db56b
		
		FIRST=$( cat /etc/hosts | grep ${CPOD} | sed "s/#//" | awk '$2 ~ /cpod-/ {gsub(/cpod-/,""); print toupper($2),"("$3")"}' )
		LAST=$( cat /etc/dnsmasq.conf | grep ${CPOD} | sed -e "/start/d" -e "s/^.*=\///" -e "s/\/.*$//" )
		FIRST="${FIRST} ......................................................."
		FIRST=$( echo ${FIRST} | cut -c1-40 )
		printf "${FIRST} --> ${LAST}\n"
	done
}

main $1
