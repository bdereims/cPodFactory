#!/bin/bash

. ./govc_env
. ./env

CLUSTER=$( echo $CLUSTER | tr '[:lower:]' '[:upper:]' )

VSAN=$( govc datastore.info ${CLUSTER}-VSAN | grep Free | sed -e "s/^.*://" -e "s/GB//" -e "s/ //g" )
VSAN=$( echo "${DELLVSAN}/1" | bc )
VSAN=$( expr ${DELLVSAN} )

MEM=$( govc metric.sample "host/${CLUSTER} Cluster" mem.usage.average | sed -e "s/,.*$//" | cut -f10 -d" " | cut -f1 -d"." )
MEM=$( expr ${MEM} )

if [ 10000 -gt ${VSAN} ] || [ 80 -lt ${MEM} ]
then
	echo "No more space!"
	exit 1
fi

echo "Ok!"
exit 0
