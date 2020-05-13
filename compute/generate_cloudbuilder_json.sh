#!/bin/bash
#bdereims@vmware.com

# $1 : cPod Name

. ./env

[ "$1" == "" ] && echo "usage: $0 <name_of_cpod>" && exit 1 

add_to_cpodrouter_hosts() {
	echo "add ${1} -> ${2}"
	ssh -o LogLevel=error ${NAME_LOWER} "sed "/${1}/d" -i /etc/hosts ; printf \"${1}\\t${2}\\n\" >> /etc/hosts"
}

JSON_TEMPLATE=cloudbuilder.json

CPOD_NAME=$( echo ${1} | tr '[:lower:]' '[:upper:]' )
NAME_LOWER=$( echo ${HEADER}-${CPOD_NAME} | tr '[:upper:]' '[:lower:]' )
VLAN=$( grep -m 1 "${NAME_LOWER}\s" /etc/hosts | awk '{print $1}' | cut -d "." -f 4 )
SUBNET="172.25.$( expr ${VLAN} - 10 )"

VLAN="0"
SUBNET="172.25.10"

PASSWORD=$( ${EXTRA_DIR}/passwd_for_cpod.sh ${CPOD_NAME} ) 

SCRIPT_DIR=/tmp/scripts
SCRIPT=/tmp/scripts/cloudbuilder-${NAME_LOWER}.json

mkdir -p ${SCRIPT_DIR} 
cp ${COMPUTE_DIR}/${JSON_TEMPLATE} ${SCRIPT} 

sed -i -e "s/###SUBNET###/${SUBNET}/g" \
-e "s/###PASSWORD###/${PASSWORD}/" \
-e "s/###VLAN###/${VLAN}/g" \
-e "s/###CPOD###/${NAME_LOWER}/g" \
-e "s/###DOMAIN###/${ROOT_DOMAIN}/g" \
${SCRIPT}

echo "Adding entries into hosts of ${NAME_LOWER}."
add_to_cpodrouter_hosts "${SUBNET}.3" "cloudbuilder"
add_to_cpodrouter_hosts "${SUBNET}.4" "vcsa"
add_to_cpodrouter_hosts "${SUBNET}.9" "vcf"
add_to_cpodrouter_hosts "${SUBNET}.10" "nsx"
add_to_cpodrouter_hosts "${SUBNET}.11" "nsx01"
add_to_cpodrouter_hosts "${SUBNET}.12" "nsx02"
add_to_cpodrouter_hosts "${SUBNET}.13" "nsx03"
add_to_cpodrouter_hosts "${SUBNET}.15" "en01"
add_to_cpodrouter_hosts "${SUBNET}.16" "en02"
	
ssh -o LogLevel=error ${NAME_LOWER} "systemctl restart dnsmasq"

echo "JSON is genereated: ${SCRIPT}"
