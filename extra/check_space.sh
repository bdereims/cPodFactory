#!/bin/bash

. ./govc_env
. ./env

CLUSTER=$( echo $CLUSTER | tr '[:lower:]' '[:upper:]' )

DELLVSAN=$( govc datastore.info ${CLUSTER}-VSAN | grep Free | sed -e "s/^.*://" -e "s/GB//" -e "s/ //g" )
DELLVSAN=$( echo "${DELLVSAN}/1" | bc )
DELLVSAN=$( expr ${DELLVSAN} )

MEM=$( govc metric.sample "host/DELL Cluster" mem.usage.average | sed -e "s/,.*$//" | cut -f10 -d" " | cut -f1 -d"." )
#govc metric.sample "host/DELL Cluster" mem.usage.average | sed "s/^.*,//" | cut -f1 -d" " | cut -f1 -d"." )
MEM=$( expr ${MEM} )

if [ 10000 -gt ${DELLVSAN} ] || [ 80 -lt ${MEM} ]
then
	echo "No more space!"
	exit 1
fi

echo "Ok!"
exit 0
