#!/bin/bash
#bdereims@vmware.com

. ./env

[ "$1" == "" ] && echo "usage: $0 <name_of_transportzone>" && exit 1 

TZ_ID=$( ${NETWORK_DIR}/id_transportzone.sh ${1} )
[ "${TZ_ID}" == "" ] && echo "${1} doesn't exist!" && exit 1

curl -s -k -u ${NSX_ADMIN}:${NSX_PASSWD} -X GET -H "Accept: application/json" "https://${NSX}/api/2.0/vdn/scopes/${TZ_ID}/virtualwires?pagesize=254&startindex=0" | jq '. | .["dataPage"] | .["data"] | .[] | {name: .name, vdnID: .vdnId, portgroup: .backing[].backingValue}' 
