#!/bin/sh ++group=host/vim/vmvisor/boot

# local configuration options

# Note: modify at your own risk!  If you do/use anything in this
# script that is not part of a stable API (relying on files to be in
# specific places, specific tools, specific output, etc) there is a
# possibility you will end up with a broken system after patching or
# upgrading.  Changes are not supported unless under direction of
# VMware support.

# Note: This script will not be run when UEFI secure boot is enabled.

######
### Disable secure boot option in vCenter for ESX template, without that this script will not run.
######

FILE=/etc/rc.local.d/configured

if [ ! -f ${FILE} ]; then
        echo "vmk0 recreation."
        touch ${FILE}
        esxcli network ip interface remove --interface-name=vmk0
        esxcli network ip interface add --interface-name=vmk0 --portgroup-name="Management Network"
        esxcli network ip interface ipv4 set --interface-name=vmk0 --type=dhcp
        #esxcli network ip interface tag add -i vmk0 -t VSAN
        #esxcli network ip interface tag add -i vmk0 -t VMotion
fi

exit 0
