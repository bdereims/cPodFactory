#!/bin/bash
#bdereims@vmware.com

export GOVC_USERNAME="${VCENTER_ADMIN}"
export GOVC_PASSWORD=${VCENTER_PASSWD}
export GOVC_URL="${VCENTER}"
export GOVC_INSECURE=1
export GOVC_DATACENTER="${VCENTER_DATACENTER}"
export GOVC_DATASTORE="${VCENTER_DATASTORE}"

replace_json() {
	TEMP=/tmp/$$

	# ${1} : Source File
	# ${2} : Nested Item
	# ${3} : Key to find
	# ${4} : Value of Key
	# ${5} : Key to update
	# ${6} : Update Key

	cat ${1} | \
	jq '(.'"${2}"'[] | select (.'"${3}"' == "'"${4}"'") | .'"${5}"') = "'"${6}"'"' > ${1}-tmp

	cp ${1}-tmp ${1} ; rm ${1}-tmp
}
