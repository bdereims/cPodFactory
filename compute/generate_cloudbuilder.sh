#!/bin/bash
#bdereims@vmware.com

# $1 : cPod Name
# add : "server=/5.23.172.in-addr.arpa/172.23.5.1" in dnsmasq.conf @ wdm in order to add cPod as WD

. ./env

[ "$1" == "" ] && echo "usage: $0 <name_of_cpod>" && exit 1 

add_to_cpodrouter_hosts() {
	echo "add ${1} -> ${2}"
	ssh -o LogLevel=error ${NAME_LOWER} "sed "/${1}/d" -i /etc/hosts ; printf \"${1}\\t${2}\\n\" >> /etc/hosts"
}

JSON_TEMPLATE=cloudbuilder-401.json
DNSMASQ_TEMPLATE=dnsmasq.conf-vcf
BGPD_TEMPLATE=bgpd.conf-vcf

CPOD_NAME=$( echo ${1} | tr '[:lower:]' '[:upper:]' )
NAME_LOWER=$( echo ${HEADER}-${CPOD_NAME} | tr '[:upper:]' '[:lower:]' )
VLAN=$( grep -m 1 "${NAME_LOWER}\s" /etc/hosts | awk '{print $1}' | cut -d "." -f 4 )
#SUBNET="172.25.$( expr ${VLAN} - 10 )"
SUBNET=$( ./${COMPUTE_DIR}/cpod_ip.sh ${1} )

PASSWORD=$( ${EXTRA_DIR}/passwd_for_cpod.sh ${CPOD_NAME} ) 

SCRIPT_DIR=/tmp/scripts
SCRIPT=/tmp/scripts/cloudbuilder-${NAME_LOWER}.json
DNSMASQ=/tmp/scripts/dnsmasq-${NAME_LOWER}.json
BGPD=/tmp/scripts/bgpd-${NAME_LOWER}.conf

mkdir -p ${SCRIPT_DIR} 
cp ${COMPUTE_DIR}/${JSON_TEMPLATE} ${SCRIPT} 
cp ${COMPUTE_DIR}/${DNSMASQ_TEMPLATE} ${DNSMASQ} 
cp ${COMPUTE_DIR}/${BGPD_TEMPLATE} ${BGPD} 

# Generate JSON for cloudbuilder
sed -i -e "s/###SUBNET###/${SUBNET}/g" \
-e "s/###PASSWORD###/${PASSWORD}/" \
-e "s/###VLAN###/${VLAN}/g" \
-e "s/###CPOD###/${NAME_LOWER}/g" \
-e "s/###DOMAIN###/${ROOT_DOMAIN}/g" \
-e "s/###LIC_ESX###/${LIC_ESX}/g" \
-e "s/###LIC_VCSA###/${LIC_VCSA}/g" \
-e "s/###LIC_VSAN###/${LIC_VSAN}/g" \
-e "s/###LIC_NSXT###/${LIC_NSXT}/g" \
${SCRIPT}

# Generate DNSMASQ conf file
sed -i -e "s/###SUBNET###/${SUBNET}/g" \
-e "s/###PASSWORD###/${PASSWORD}/" \
-e "s/###VLAN###/${VLAN}/g" \
-e "s/###CPOD###/${NAME_LOWER}/g" \
-e "s/###DOMAIN###/${ROOT_DOMAIN}/g" \
-e "s/###LIC_ESX###/${LIC_ESX}/g" \
-e "s/###LIC_VCSA###/${LIC_VCSA}/g" \
-e "s/###LIC_VSAN###/${LIC_VSAN}/g" \
-e "s/###LIC_NSXT###/${LIC_NSXT}/g" \
${DNSMASQ}

# Generate BGPD conf file
sed -i -e "s/###VLAN###/${VLAN}/g" \
${BGPD}

echo "Modifying dnsmasq on cpodrouter."
scp ${DNSMASQ} ${NAME_LOWER}:/etc/dnsmasq.conf

echo "Modifying bgpd on cpodrouter."
scp ${BGPD} ${NAME_LOWER}:/etc/quagga/bgpd.conf

echo "Adding entries into hosts of ${NAME_LOWER}."
add_to_cpodrouter_hosts "${SUBNET}.3" "cloudbuilder"
add_to_cpodrouter_hosts "${SUBNET}.4" "vcsa"
add_to_cpodrouter_hosts "${SUBNET}.5" "nsx01"
add_to_cpodrouter_hosts "${SUBNET}.6" "nsx01a"
add_to_cpodrouter_hosts "${SUBNET}.7" "nsx01b"
add_to_cpodrouter_hosts "${SUBNET}.8" "nsx01c"
add_to_cpodrouter_hosts "${SUBNET}.9" "en01"
add_to_cpodrouter_hosts "${SUBNET}.10" "en02"
add_to_cpodrouter_hosts "${SUBNET}.11" "sddcmanager"
	
ssh -o LogLevel=error ${NAME_LOWER} "systemctl restart dnsmasq"
ssh -o LogLevel=error ${NAME_LOWER} "systemctl restart bgpd"

echo "JSON is genereated: ${SCRIPT}"

#curl -i -k -u admin:${PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' -d @${SCRIPT} -X POST https://cloudbuilder.${NAME_LOWER}.${ROOT_DOMAIN}/v1/sddcs/validations
curl -i -k -u admin:${PASSWORD} -H 'Content-Type: application/json' -H 'Accept: application/json' -d @${SCRIPT} -X POST https://cloudbuilder.${NAME_LOWER}.${ROOT_DOMAIN}/v1/sddcs

# Delete a failed deployment
# curl -X GET http://localhost:9080/bringup-app/bringup/sddcs/test/deleteAll