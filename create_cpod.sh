#!/bin/bash
#bdereims@vmware.com

# Usage : ./create_cpod.sh EUC (not cPod-EUC)

. ./env

[ "$1" == "" ] && echo "usage: $0 <name_of_cpod> <number_of_esx (default = 3)> <owner's email alias (ex: bdereims)>" && exit 1 

if [ "${2}" ==  "" ]; then
	NUM_ESX="3"
else
	NUM_ESX="${2}"
fi

if [ "${3}" ==  "" ]; then
	OWNER="admin"
else
	OWNER="${3}"
fi

#========================================================================================

DNSMASQ=/etc/dnsmasq.conf
HOSTS=/etc/hosts

network_env() {
	FIRST_LINE=$( grep ${ROOT_DOMAIN} ${DNSMASQ} | grep "cpod-" | awk -F "/" '{print $3}' | sort -n -t "." -k 7 | head -1 )
	LAST_LINE=$( grep ${ROOT_DOMAIN} ${DNSMASQ} | grep "cpod-" | awk -F "/" '{print $3}' | sort -n -t "." -k 7 | tail -1 )

	TRANSIT_SUBNET=$( echo ${FIRST_LINE} | sed 's!^.*/!!' | sed 's/\.[0-9]*$//' )

	TRANSIT_IP=$( echo ${FIRST_LINE} | sed 's!^.*/!!' | sed 's/.*\.//' )
	TRANSIT_IP=$( expr ${TRANSIT_IP} )
	LAST_IP=$( echo ${LAST_LINE} | sed 's!^.*/!!' | sed 's/.*\.//' )
	LAST_IP=$( expr ${LAST_IP} )

	while [ ${TRANSIT_IP} -le ${LAST_IP} ]
	do
        	if [[ ! $( grep "${TRANSIT_SUBNET}.${TRANSIT_IP}" ${DNSMASQ} ) ]]; then
                	break
        	fi

        	TRANSIT_IP=$( expr ${TRANSIT_IP} + 1 )
	done

	[ ${TRANSIT_IP} -gt 253 ] && echo "! Impossible to create cPod. Maximum is reached." && exit_gate 1

	ASN=$( expr ${ASN} + ${TRANSIT_IP} - 1 )
	NEXT_IP="${TRANSIT_SUBNET}.${TRANSIT_IP}"

	TMP=$( expr ${TRANSIT_IP} - 10 )
	SUBNET="${TRANSIT}.${TMP}.0/24"

	echo "The cPod IP address is '${NEXT_IP}' in transit network."
	echo "The subnet of the cPod is '${SUBNET}'."
}

mutex() {
	while ! mkdir lock 2>&1 > /dev/null
	do
		echo "Waiting (PID $$)..."
		sleep 2 
	done
}

de_mutex() {
	rmdir lock
}

network_create() {
	NSX_LOGICALSWITCH="cpod-${NAME_LOWER}"
	${NETWORK_DIR}/create_logicalswitch.sh ${NSX_TRANSPORTZONE} ${NSX_LOGICALSWITCH}

	PORTGROUP=$( ${NETWORK_DIR}/list_logicalswitch.sh ${NSX_TRANSPORTZONE} | jq 'select(.name == "'${NSX_LOGICALSWITCH}'") | .portgroup' | sed 's/"//g' )
	PORTGROUP_NAME=$( ${COMPUTE_DIR}/list_portgroup.sh | jq 'select(.network == "'${PORTGROUP}'") | .name' | sed 's/"//g' )

	${COMPUTE_DIR}/modify_portgroup.sh ${PORTGROUP_NAME}
}

vapp_create() {
	NAME_UPPER=$( echo ${1} | tr '[:lower:]' '[:upper:]' )
	${COMPUTE_DIR}/create_vapp.sh ${NAME_UPPER} ${2} ${3} ${4} ${5}
}

modify_dnsmasq() {
	echo "Modifying '${DNSMASQ}' and '${HOSTS}'."
	echo "server=/cpod-${1}.${ROOT_DOMAIN}/${2}" >> ${DNSMASQ}
	GEN_PASSWORD="$(pwgen -s -1 15 1)!"

	#PRIME=$( echo $RANDOM % 15 + 1 | bc )
	#SECOND=$( expr 15 - ${PRIME} )

	#PRIME=$( pwgen -s -1 ${PRIME} 1 )
	#SECOND=$( pwgen -s -1 ${SECOND} 1 )

	#GEN_PASSWD="${PRIME}!${SECOND}"

	printf "${2}\tcpod-${1}\t#${OWNER}\t${GEN_PASSWORD}\n" >> ${HOSTS}

	systemctl stop dnsmasq ; systemctl start dnsmasq
}

bgp_add_peer() {
	echo "Adding cPodRouter as BGP peer"
	./network/add_bgp_neighbour.sh $1 $2 
}

bgp_add_peer_vtysh() {
        echo "Adding cPodRouter as BGP peer ${1} with ASN ${2}"
        ./network/add_bgp_peer_vtysh.sh $1 $2
}

prep_cpod() {
	./prep_cpod.sh $1 $2
}

exit_gate() {
	#[ -f lock ] && rm lock
	exit $1 
}

check_space() {
	./extra/check_space.sh 2>&1 > /dev/null
	if [ $? != 0 ]; then
		echo "Error: No more space, can't continue."
		./extra/post_slack.sh ":thumbsdown: Can't create cPod *${1}*, no more space on Datastore or not enough Memory."
		exit_gate 1
	fi
}

check_if_existing() {
	IN_HOSTS=$( grep ${1} ${HOST} | wc -l )	
	IN_DNSMASQ=$( grep ${1} ${DNSMASQ} | wc -l )	
	RESULT=$( expr ${IN_HOSTS} + ${IN_DNSMASQ} )

	if [ ${RESULT} > 0 ]; then
		NAME_UPPER=$( echo $1 | tr '[:lower:]' '[:upper:]' )
		echo "=== cPod ${NAME_UPPER} already exists, choose other name or destroy it."
		./extra/post_slack.sh ":thumbsdown: cPod *${NAME_UPPER}* already exists."
		exit 1
	fi
}

main() {
	NAME_LOWER=$( echo $1 | tr '[:upper:]' '[:lower:]' )

	check_space $1

	echo "=== Starting to deploy a new cPod called '${HEADER}-${1}'."
	./extra/post_slack.sh "Starting creation of cPod *${1}*"
	START=$( date +%s ) 
	
	mutex
		network_env
		network_create ${NAME_LOWER}
		modify_dnsmasq ${NAME_LOWER} ${NEXT_IP} ${3}
		ASN=$(expr ${ASN} + 1)
		bgp_add_peer_vtysh ${NEXT_IP} ${ASN} 
	de_mutex

	vapp_create ${1} ${PORTGROUP_NAME} ${NEXT_IP} ${NUM_ESX} ${ROOT_DOMAIN}

	echo "prep with ${1} ${NUM_ESX}"
	prep_cpod ${1} ${NUM_ESX}

	echo "=== Creation is finished."
	END=$( date +%s )
	TIME=$( expr ${END} - ${START} )
	echo "In ${TIME} Seconds."
	./extra/post_slack.sh ":thumbsup: cPod *${1}* has been successfully created in *${TIME}s*"

	exit_gate 0
}

main $1
