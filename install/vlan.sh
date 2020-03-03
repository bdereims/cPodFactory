#!/bin/bash
#bdereims@vmware.com

INTERFACE=eth2
MTU=9000
#VLANID=12
VLANID=$( ip addr show eth1 | grep inet | head -1 | awk '{print $2}' | sed 's/\/.*$//' | sed -e "s/^.*\.//" )

create_vlan() 
{
	ip link add link ${INTERFACE} name ${INTERFACE}.${1} type vlan id ${1} 
	ip addr add ${2} dev ${INTERFACE}.${1}
	ip link set up ${INTERFACE}.${1}
	ip link set mtu ${MTU} dev ${INTERFACE}.${1}
}

create_vlan ${VLANID}01 10.${VLANID}.1.1/24
create_vlan ${VLANID}02 10.${VLANID}.2.1/24
create_vlan ${VLANID}03 10.${VLANID}.3.1/24

# 10.12.8.0/21 = 10.12.8.0/24 + 10.12.10.0/23 + 10.12.12.0/22
create_vlan ${VLANID}04 10.${VLANID}.8.1/21
