#!/bin/bash
#bdereims@vmware.com

. ./env

case $BACKEND_NETWORK in
	"NSX-V")
		curl -s -k -u ${NSX_ADMIN}:${NSX_PASSWD} -X GET -H "Accept: application/json" https://${NSX}/api/2.0/vdn/scopes | jq '. | .["allScopes"] | .[0] | {name: .name, id: .id}'
		;;
	"NSX-T")
		curl -s -k -u ${NSX_ADMIN}:${NSX_PASSWD} -X GET -H "Accept: application/json" https://${NSX}/api/v1/transport-zones/ | jq '. | .["results"] | .[] | select(._create_user == "'${NSX_ADMIN}'") | {name: .display_name, id: .id, nested_esx: .nested_nsx}'
		;;
esac
