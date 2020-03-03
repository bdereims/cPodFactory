#!/bin/bash
#bdereims@vmware.com

INTERFACE=eth2
MTU=9000

create_vlan() 
{
	ip link add link ${INTERFACE} name ${INTERFACE}.${1} type vlan id ${1} 
	ip addr add ${2} dev ${INTERFACE}.${1}
	ip link set up ${INTERFACE}.${1}
	ip link set mtu ${MTU} dev ${INTERFACE}.${1}
}

create_vlan 1201 10.12.1.1/24
create_vlan 1202 10.12.2.1/24
create_vlan 1203 10.12.3.1/24
create_vlan 1204 10.12.4.1/22
