IP='172.25.7.21'
PASSWORD='y6pkDMIIWtr!'
      
#sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "for DISK in $( esxcli storage core device list | grep mpx | sed -e \"/^.*D/d\" -e \"/T0/d\" ); do echo ${DISK} ; esxcli storage nmp satp rule add -s VMW_SATP_LOCAL -d ${DISK} -o enable_ssd ; esxcli storage core claiming reclaim -d ${DISK} ; done" 2>&1 > /dev/null
sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no root@${IP} "cat /etc/hosts | grep -e \"/brice/d\""
