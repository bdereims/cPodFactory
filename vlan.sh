#!/bin/bash
#bdereims@vmware.com

INTERFACE=eth2
BIG_MTU=9000
REG_MTU=1500
VLANID=$( ip addr show eth1 | grep inet | head -1 | awk '{print $2}' | sed 's/\/.*$//' | sed -e "s/^.*\.//" )

create_vlan() 
{
	VLAN=${VLANID}${2}
	SUBNET=$( echo ${2} | sed -e "s/0//" )
	ip link add link ${INTERFACE} name ${INTERFACE}.${VLAN} type vlan id ${VLAN} 
	ip addr add 10.${VLANID}.${SUBNET}.1/${3} dev ${INTERFACE}.${VLAN}
	ip link set mtu ${1} dev ${INTERFACE}.${VLAN}
	ip link set up ${INTERFACE}.${VLAN}
}

# vMOTION + vSAN
create_vlan ${BIG_MTU} 01 24

# TEP Edges
create_vlan ${BIG_MTU} 02 24

# TEP Hosts
create_vlan ${BIG_MTU} 03 24

# General purpose VLAN 
create_vlan ${REG_MTU} 04 24

# General purpose VLAN 
create_vlan ${REG_MTU} 05 24

# General purpose VLAN 
create_vlan ${REG_MTU} 06 24

# General purpose VLAN 
create_vlan ${REG_MTU} 07 24

# Expose/Uplink - Large Subnet
# Ex. of Carve Out: 10.12.8.0/21 = 10.12.8.0/22 + 10.12.12.0/22
# Ex. of Carve Out: 10.12.8.0/21 = 10.12.8.0/24 + 10.12.9.0/24 + 10.12.10.0/23 + 10.12.12.0/22
create_vlan ${REG_MTU} 08 21
