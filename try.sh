. ./env

DNSMASQ=/etc/dnsmasq.conf
HOSTS=/etc/hosts

        FIRST_LINE=$( grep ${ROOT_DOMAIN} ${DNSMASQ} | grep "${TRANSIT_NET}\." | grep "cpod-" | awk -F "/" '{print $3}' | sort -n -t "." -k 4 | head -1 )
        echo ${FIRST_LINE}
        LAST_LINE=$( grep ${ROOT_DOMAIN} ${DNSMASQ} | grep "${TRANSIT_NET}\." | grep "cpod-" | awk -F "/" '{print $3}' | sort -n -t "." -k 4 | tail -1 )

        TRANSIT_SUBNET=$( echo ${FIRST_LINE} | sed 's!^.*/!!' | sed 's/\.[0-9]*$//' )
	echo "### ${TRANSIT_SUBNET}"

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
