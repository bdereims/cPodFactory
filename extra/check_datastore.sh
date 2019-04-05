#!/bin/bash
#bdereims@vmware.com

. ./govc_env

CLUSTER=$( echo ${1} | tr '[:lower:]' '[:upper:]' )

DATASTORE=$( govc datastore.info ${CLUSTER}-VSAN | grep Free | sed -e "s/^.*://" -e "s/GB//" -e "s/ //g" )
DATASTORE=$( echo "${DATASTORE}/1" | bc )
DATASTORE=$( expr ${DATASTORE} )

if [ ${DATASTORE} -lt 10000 ]; then
	echo "No more space!"
	exit 1
fi

echo "Ok!"
exit 0
