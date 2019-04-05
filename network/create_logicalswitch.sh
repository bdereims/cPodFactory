#!/bin/bash
#bdereims@vmware.com

. ./env

[ "$1" == "" -o "$2" == "" ] && echo "usage: $0 <name_of_transportzone> <name_of_logicalswitch>" && exit 1 


TZ_ID=$( ${NETWORK_DIR}/id_transportzone.sh ${1} )
[ "${TZ_ID}" == "" ] && echo "${1} doesn't exist!" && exit 1

NEW_LOGICALSWITCH="<virtualWireCreateSpec><name>${2}</name><description>Logical Switch via REST API</description><tenantId></tenantId><controlPlaneMode>HYBRID_MODE</controlPlaneMode><guestVlanAllowed>true</guestVlanAllowed></virtualWireCreateSpec>"

curl -s -k -u ${NSX_ADMIN}:${NSX_PASSWD} -H "Content-Type:text/xml;charset=UTF-8" -X POST --data "${NEW_LOGICALSWITCH}" https://${NSX}/api/2.0/vdn/scopes/${TZ_ID}/virtualwires 2>&1 > /dev/null

LS_PROPS=$( ${NETWORK_DIR}/props_logicialswitch.sh $1 $2 )

[ "${LS_PROPS}" != "" ] && echo "Logicial Switch '${2}' has been sucessfully created in '${1}'." && exit 0

echo "Logical Switch '${2}' does not seem to be created." && exit 1
