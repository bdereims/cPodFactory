#!/bin/bash
#bdereims@vmware.com

. ./env

curl -s -k -u ${NSX_ADMIN}:${NSX_PASSWD} -X GET -H "Accept: application/json" https://${NSX}/api/2.0/vdn/scopes | jq '. | .["allScopes"] | .[0] | {name: .name, id: .id}'
