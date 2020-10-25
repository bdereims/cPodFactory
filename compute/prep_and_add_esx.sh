#!/bin/bash
#bdereims@vmware.com

DHCP_LEASE=/var/lib/misc/dnsmasq.leases
DNSMASQ=/etc/dnsmasq.conf
HOSTS=/etc/hosts
PASSWORD=###ROOT_PASSWD###
GEN_PASSWORD="###GEN_PASSWD###"
ISO_BANK_SERVER="###ISO_BANK_SERVER###"
ISO_BANK_DIR="###ISO_BANK_DIR###"
NUM_ESX="###NUM_ESX###"
NOCUSTO="###NOCUSTO###"
DOMAIN=$( grep "domain=" /etc/dnsmasq.conf | sed "s/domain=//" )

[ "$( hostname )" == "mgmt-cpodrouter" ] && exit 1
[ -f already_prep ] && exit 0

touch already_prep

# waiting for all ESX get lease, boot takes time
ISTHERE=0
NUM_ESX=$( expr ${NUM_ESX} )
while [ ${ISTHERE} != ${NUM_ESX} ]
do
	sleep 3 
	ISTHERE=$( cat ${DHCP_LEASE} | cut -d ' ' -f2 | sort -u | wc -l )
	if [ "${ISTHERE}X" == "X" ]; then
		ISTHERE=0
	fi
done

if [ ${NUM_ESX} -ge 1 ]; then
	sleep 40
fi

I=$( cat ${DHCP_LEASE} | wc -l )
for ESX in $( cat ${DHCP_LEASE} | cut -f 2,3 -d' ' | sed 's/\ /,/' ); do
	IP=$( echo ${ESX} | cut -f2 -d',' )
	BASEIP=$( echo ${IP} | sed 's/\.[0-9]*$/./' )
	CPODROUTER="${BASEIP}1"
	NEWIP=$( expr ${I} + 20 )
	NEWIP="${BASEIP}${NEWIP}"
	NAME=$( printf "esx%02d" ${I} )
	printf "${NEWIP}\t${NAME}\n" >> ${HOSTS}
	I=$( expr ${I} - 1 )
	echo "Configuring ${NAME}..."
	sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "esxcli system hostname set --host=${NAME}" 2>&1 > /dev/null
	sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "esxcli system settings advanced set -o /Mem/ShareForceSalting -i 0" 2>&1 > /dev/null
	sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "esxcli system settings advanced set -o /UserVars/SuppressCoredumpWarning -i 1" 2>&1 > /dev/null
	if [ "${NOCUSTO}" != "YES" ]; then
		sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "vim-cmd hostsvc/vmotion/vnic_set vmk0" 2>&1 > /dev/null
		sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "esxcli storage nfs add --host=${CPODROUTER} --share=/data/Datastore --volume-name=nfsDatastore" 2>&1 > /dev/null
		sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "esxcli storage nfs add --host=${ISO_BANK_SERVER} --share=${ISO_BANK_DIR} --volume-name=BITS -r" 2>&1 > /dev/null
		sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "echo \"server ${CPODROUTER}\" >> /etc/ntp.conf ; chkconfig ntpd on ; /etc/init.d/ntpd start" 2>&1 > /dev/null
	fi
	sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "echo \"nameserver ${CPODROUTER}\" > /etc/resolv.conf ; echo \"search ${DOMAIN}\" >> /etc/resolv.conf" 2>&1 > /dev/null
	
	sshpass -p ${PASSWORD} scp -o StrictHostKeyChecking=no /root/update/ssd_esx_tag.sh root@${IP}:/tmp/ssd_esx_tag.sh 2>&1 > /dev/null
	sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "/tmp/ssd_esx_tag.sh" 2>&1 > /dev/null

	sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "printf \"${GEN_PASSWORD}\n${GEN_PASSWORD}\n\" | passwd root 2>&1 > /dev/null" 2>&1 > /dev/null
	sshpass -p ${GEN_PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "esxcli network ip interface ipv4 set -i vmk0 -I ${NEWIP} -N 255.255.255.0 -t static ; esxcli network ip interface set -e false -i vmk0 ; esxcli network ip interface set -e true -i vmk0" 2>&1 > /dev/null
done

# Create entry for VCSA
if [ ${NUM_ESX} -ge 1 ]; then
	printf "${BASEIP}3\tvcsa\n" >> ${HOSTS}
fi

# Optionnal
#printf "${BASEIP}4\tnsx\n" >> ${HOSTS}
#printf "#${BASEIP}5-7\tnsx controllers\n" >> ${HOSTS}
#printf "${BASEIP}8\tedge\n" >> ${HOSTS}

touch /data/Datastore/exclude.tag

mkdir -p /data/Datastore/scratch/log
chown -R nobody:65534 /data/Datastore/scratch

sed -i "s#ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS#ExecStart=/usr/sbin/rpc.nfsd 12 $RPCNFSDARGS#" /usr/lib/systemd/system/nfs-server.service
systemctl daemon-reload
systemctl stop nfs-server ; systemctl start nfs-server
	
systemctl stop dnsmasq ; systemctl start dnsmasq 

echo "root:${GEN_PASSWORD}" | chpasswd
