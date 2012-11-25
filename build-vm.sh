#!/bin/bash

#################################################################################################################
# vm-helper creates vms fast by both handling downloading of isos and letting each vm has it own template.	#
# Copyright (C) <2012>  <Paul Andrew Liljenberg>								#
#														#
# This program is free software: you can redistribute it and/or modify						#
# it under the terms of the GNU General Public License as published by						#
# the Free Software Foundation, either version 3 of the License, or						#
# (at your option) any later version.										#
#														#
# This program is distributed in the hope that it will be useful,						#
# but WITHOUT ANY WARRANTY; without even the implied warranty of						#
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the							#
# GNU General Public License for more details.									#
#														#
# You should have received a copy of the GNU General Public License						#
# along with this program.  If not, see <http://www.gnu.org/licenses/>.						#
###############################################################################################################	#

# The following code is built upon
# https://github.com/ajclark/preseed/blob/master/build-vm.sh
EXPORT_PATH=$HOME
IMPORT_PATH=$EXPORT_PATH
ISO_LOCAL=~/Downloads
BASEFOLDER=~/.VirtualBox
HD_LOCAL=$BASEFOLDER/$VMNAME

which -s VBoxManage || exit 1

_iso()
{
while [ ! -e $ISO_LOCAL/$ISO_NAME ]; do
    /usr/bin/curl -L $ISO_REMOTE/$ISO_NAME -o $ISO_LOCAL/$ISO_NAME
done
}

_export()
{
VBoxManage export $VMNAME --output $EXPORT_PATH/${VMNAME}.ova
VBoxManage unregistervm "$VMNAME" --delete
}


_import()
{
VBoxManage import $IMPORT_PATH/${VMNAME}.ova
rm -i $IMPORT_PATH/${VMNAME}.ova
}

_start()
{
VBoxManage startvm "$VMNAME"
}


_create()
{
if [ "`VBoxManage list runningvms | cut -d" " -f1 | grep "$VMNAME"`" ]; then
        VBoxManage controlvm "$VMNAME" poweroff && sleep 2 && VBoxManage unregistervm "$VMNAME" --delete
else
	# Create VM, set boot order
	VBoxManage createvm --basefolder $BASEFOLDER --name $VMNAME --ostype $OSTYPE --register
	VBoxManage modifyvm $VMNAME --memory $RAM --boot1 dvd --cpus 1

	# setup first interface, depends on hostname
	if [ "`hostname -s`" = stewie ]; then
    		VBoxManage modifyvm $VMNAME --nic1 bridged --bridgeadapter1 "en0: Ethernet" --nictype1 82540EM --cableconnected1 on
	else
		VBoxManage modifyvm $VMNAME --nic1 bridged --bridgeadapter1 "p4p1" --nictype1 82540EM --cableconnected1 on
	fi

	# setup the second interface
	VBoxManage modifyvm $VMNAME --nic2 intnet --nictype2 82540EM --cableconnected2 on

	# Add hard disk
	VBoxManage storagectl $VMNAME --name "SATA Controller" --add sata
	VBoxManage createhd --filename $HD_LOCAL/${VMNAME}_hdd.vdi --size 51200
	VBoxManage storageattach $VMNAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $HD_LOCAL/${VMNAME}_hdd.vdi

	# Add DVD-ROM
	VBoxManage storagectl $VMNAME --name "IDE Controller" --add ide
	VBoxManage storageattach $VMNAME --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $ISO_LOCAL/$ISO_NAME

	# Start VM
	VBoxManage startvm $VMNAME || VBoxManage unregistervm --delete $VMNAME
fi
}


_help()
{
    echo -e "usage: $0 <option> <name>\n"
    echo "obsd centos debian backtrack gentoo export import start"

}


# Main
if [ -z "$2" ];then
    help
    exit 1
fi


case "$1" in
    obsd)
	VMNAME=${2}
	OSTYPE=OpenBSD_64
	RAM=256
	ISO_REMOTE="ftp://ftp.eu.openbsd.org/pub/OpenBSD/5.2/amd64/"
	ISO_NAME="install52.iso"
	_iso
	_create
	;;
    centos)
	VMNAME=${2}
	OSTYPE=RedHat_64
	RAM=512
	ISO=centos.iso
	_iso
	_create
	;;
    debian)
	VMNAME=${2}
	OSTYPE=Debian_64
	RAM=1000
	ISO_REMOTE="http://cdimage.debian.org/cdimage/wheezy_di_beta3/amd64/iso-cd/"
	ISO_NAME="debian-wheezy-DI-b3-amd64-netinst.iso"
	_iso
	_create
	;;
    backtrack)
	VMNAME=${2}
	OSTYPE=Debian_64
        RAM=1000
        ISO_REMOTE="http://ftp.halifax.rwth-aachen.de/backtrack/"
        ISO_NAME="BT5R3-GNOME-64.iso"
        _iso
        _create
        ;;
    gentoo)
	VMNAME=${2}
	OSTYPE=Gentoo_64
	RAM=2000
	ISO_REMOTE="http://gentoo.ussg.indiana.edu//releases/amd64/12.1/"
	ISO_NAME="livedvd-amd64-multilib-2012.1.iso"
	_iso
	_create
	;;
    export)
	VMNAME=${2}
	_export
	;;
    import)
        VMNAME=${2}
        _import
        ;;
    start)
	VMNAME=${2}
	_start
	;;
	*)
	_help
	exit 1
esac
_help



 
#python -m SimpleHTTPServer

