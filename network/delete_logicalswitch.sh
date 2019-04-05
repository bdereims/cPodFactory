#!/bin/bash
#bdereims@vmware.com

. ./env

[ "$1" == "" -o "$2" == "" ] && echo "usage: $0 <name_of_transportzone> <name_of_logicalswitch>" && exit 1 

TZ_ID=$( ${NETWORK_DIR}/id_transportzone.sh ${1} )
[ "${TZ_ID}" == "" ] && echo "'${1}' doesn't exist!" && exit 1

VIRTUALWIRE_ID=$( ${NETWORK_DIR}/props_logicialswitch.sh $1 $2 | jq '.objectId' | sed 's/"//g' )
[ "${VIRTUALWIRE_ID}" == "" ] && echo "Logical Switch '$2' doesn't exist in '$1'." && exit 1

echo "Deleting '${VIRTUALWIRE_ID}' on '${1}'."
curl -s -k -u ${NSX_ADMIN}:${NSX_PASSWD} -H "Content-Type:text/xml;charset=UTF-8" -X DELETE https://${NSX}/api/2.0/vdn/virtualwires/${VIRTUALWIRE_ID} 2>&1 > /dev/null
