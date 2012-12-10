# -*- mode: sh -*-
#!/bin/bash

# vm-helper creates vms fast by both handling downloading of isos and letting each vm has it own template.	
# Copyright (C) <2012>  <Paul Andrew Liljenberg>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.				
#								
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of	
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the	
# GNU General Public License for more details.		
#						
# You should have received a copy of the GNU General Public License	
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# The following code is built upon
# https://github.com/ajclark/preseed/blob/master/build-vm.sh
EXPORT_PATH=$HOME
IMPORT_PATH=$EXPORT_PATH
ISO_LOCAL=~/Downloads
BASEFOLDER=~/.VirtualBox
LOG=/tmp/build-vm.log
ERRORS=/tmp/build-vm.errors

which -s VBoxManage || exit 1

function iso()
{
while [ ! -e $ISO_LOCAL/$ISO_NAME ]; do
    /usr/bin/curl -L $ISO_REMOTE/$ISO_NAME -o $ISO_LOCAL/$ISO_NAME
done
}

function export()
{
VBoxManage export "$VMNAME" --output $EXPORT_PATH/${VMNAME}.ova
VBoxManage unregistervm "$VMNAME" --delete
}


function import()
{
VBoxManage import $IMPORT_PATH/${VMNAME}.ova
rm -i $IMPORT_PATH/${VMNAME}.ova
}

function start()
{
VBoxManage startvm "$VMNAME"
}

function killsingle()
{
# Poweroff
VBoxManage controlvm "$VMNAME" poweroff 2>> $LOG && echo "[*] Powered off $VMNAME!" || echo "[*] $VMNAME is not running..."  2>> $LOG

# Delete
read -p "Delete $VMNAME? [Yy]`echo $'\n> '`" -n 1 -r; echo -e '\n'
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	help
	exit 1
else
	VBoxManage unregistervm "$VMNAME" --delete 2>> $LOG && echo "[*] Unregistered and deleted $VMNAME" || echo "[*] $VMNAME does not exist..." 
fi
}

function killrange()
{
    for ((NUM=1;NUM<=$RANGE;NUM++)); do
         # Poweroff virtual machine
        VBoxManage controlvm "$VMNAME $NUM" poweroff 2>> $LOG && echo "[*] Powered off $VMNAME $NUM!" || echo "[*] $VMNAME $NUM is not running..."  2>> $LOG
    done
	
    read -p "Delete all virtual machines? [Yy]`echo $'\n> '`" -n 1 -r; echo -e '\n'
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        help
        exit 1
    else
        for ((NUM=1;NUM<=$RANGE;NUM++)); do
            # Delete virtual machine
		    VBoxManage unregistervm "$VMNAME $NUM" --delete 2>> $LOG && echo "[*] Unregistered and deleted $VMNAME $NUM" || echo "[*] $VMNAME $NUM does not exist..."
            sleep 1
        done
    fi
}

function createsingle()
{
HD_LOCAL="$BASEFOLDER"/"$VMNAME"

    # Create VM, set boot order
    echo "[*] Creating machine $VMNAME!"
    VBoxManage createvm --basefolder "$BASEFOLDER" --name "$VMNAME" --ostype $OSTYPE --register  1>> $LOG 2>> $ERRORS
    VBoxManage modifyvm "$VMNAME" --memory $RAM --boot1 dvd --cpus 1  1>> $LOG 2>> $ERRORS

    # setup first interface, depends on hostname
    if [ "`hostname -s`" = stewie ]; then
    	VBoxManage modifyvm "$VMNAME" --nic1 bridged --bridgeadapter1 "en0: Ethernet" --nictype1 82540EM --cableconnected1 on
    else
	    VBoxManage modifyvm "$VMNAME" --nic1 bridged --bridgeadapter1 "p4p1" --nictype1 82540EM --cableconnected1 on
    fi

    # setup the second interface
    VBoxManage modifyvm "$VMNAME" --nic2 intnet --nictype2 82540EM --cableconnected2 on

    # Add hard disk
    VBoxManage storagectl "$VMNAME" --name "SATA Controller" --add sata  1>> $LOG 2>> $ERRORS
    VBoxManage createhd --filename $HD_LOCAL/"${VMNAME}"_hdd.vdi --size 51200  1>> $LOG 2>> $ERRORS
    VBoxManage storageattach "$VMNAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $HD_LOCAL/"${VMNAME}"_hdd.vdi  1>> $LOG 2>> $ERRORS

    # Add DVD-ROM
    VBoxManage storagectl "$VMNAME" --name "IDE Controller" --add ide  1>> $LOG 2>> $ERRORS
    VBoxManage storageattach "$VMNAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $ISO_LOCAL/$ISO_NAME  1>> $LOG 2>> $ERRORS

    # Start VM
    VBoxManage startvm "$VMNAME" || VBoxManage unregistervm --delete "$VMNAME" 
}

function createrange()
{
HD_LOCAL="$BASEFOLDER"/"$VMNAME $NUM"

    # Create VM, set boot order
    echo "[*] Creating machine $VMNAME $NUM!"
    VBoxManage createvm --basefolder "$BASEFOLDER" --name "$VMNAME $NUM" --ostype $OSTYPE --register  1>> $LOG 2>> $ERRORS
    VBoxManage modifyvm "$VMNAME $NUM" --memory $RAM --boot1 dvd --cpus 1  1>> $LOG 2>> $ERRORS

    # setup first interface, depends on hostname
    if [ "`hostname -s`" = stewie ]; then
        VBoxManage modifyvm "$VMNAME $NUM" --nic1 bridged --bridgeadapter1 "en0: Ethernet" --nictype1 82540EM --cableconnected1 on
    else
        VBoxManage modifyvm "$VMNAME $NUM" --nic1 bridged --bridgeadapter1 "p4p1" --nictype1 82540EM --cableconnected1 on
    fi

    # setup the second interface
    VBoxManage modifyvm "$VMNAME $NUM" --nic2 intnet --nictype2 82540EM --cableconnected2 on

    # Add hard disk
    VBoxManage storagectl "$VMNAME $NUM" --name "SATA Controller" --add sata  1>> $LOG 2>> $ERRORS
    VBoxManage createhd --filename $HD_LOCAL/"${VMNAME} $NUM"_hdd.vdi --size 51200  1>> $LOG 2>> $ERRORS
    VBoxManage storageattach "$VMNAME $NUM" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $HD_LOCAL/"${VMNAME} $NUM"_hdd.vdi  1>> $LOG 2>> $ERRORS

    # Add DVD-ROM
    VBoxManage storagectl "$VMNAME $NUM" --name "IDE Controller" --add ide  1>> $LOG 2>> $ERRORS
    VBoxManage storageattach "$VMNAME $NUM" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $ISO_LOCAL/$ISO_NAME  1>> $LOG 2>> $ERRORS

    # Start VM
    VBoxManage startvm "$VMNAME $NUM" || VBoxManage unregistervm --delete "$VMNAME $NUM"
}

function manage()
{
if [ -z $RANGE ]; then
	if [  "`VBoxManage list vms | cut -d"'" -f1 | grep -oh "$VMNAME"`" ]; then
        	killsingle
	else
        	createsingle
	fi
elif [ -n $RANGE ]; then
    # $RANGE is the third argument ie ./build-vm.sh centos centos -> 3 <-
    # and will create three vms if these are not registerd else kill them.
	for ((NUM=1;NUM<=$RANGE;NUM++)); do
		if [ "`VBoxManage list vms | cut -d"'" -f1 | grep -oh "$VMNAME $NUM"`" ]; then
			killrange
		else
			createrange
		fi
	done
fi
}

function help()
{
    echo -e "\nusage: $0 <option> <name> <number>"
    echo -e 'Example: ./build-vm centos web 10 -- Create ten vms with centos as template and "web 1" to "web 10" as name of vm'
    echo -e 'Example: ./build-vm centos web 11 -- Terminate ten vms with centos as template and "web 1" to "web 10" as name of vm. The 11 vm wont be created.'
    echo -e 'Example: ./build-vm centos "centos 10" -- Unregister and terminate vm named "centos 10"\n'
    echo "obsd centos debian backtrack gentoo archlinux export import start"
}

if [ -z "$2" ];then
    help
    exit 1
fi

case "$1" in
    archlinux)
    VMNAME=${2}
    RANGE=${3}
    OSTYPE=ArchLinux_64
    RAM=2000
    ISO_REMOTE="http://ftp.lysator.liu.se/pub/archlinux/iso/2012.12.01/"
    ISO_NAME="archlinux-2012.12.01-dual.iso"
    iso
    manage
    ;; 
    obsd)
    VMNAME=${2}
    RANGE=${3}
    OSTYPE=OpenBSD_64
    RAM=256
    ISO_REMOTE="ftp://ftp.eu.openbsd.org/pub/OpenBSD/5.2/amd64/"
    ISO_NAME="install52.iso"
    iso
    manage
    ;;
    centos)
    VMNAME=${2}
    RANGE=${3}
    OSTYPE=RedHat_64
    RAM=512
    ISO_REMOTE="ftp://ftp.sunet.se/pub/Linux/distributions/centos/6.3/isos/x86_64/"
    ISO_NAME="CentOS-6.3-x86_64-netinstall.iso"
    iso
    manage
    ;;
    debian)
    VMNAME=${2}
    RANGE=${3}
    OSTYPE=Debian_64
    RAM=1000
    ISO_REMOTE="http://cdimage.debian.org/cdimage/wheezy_di_beta4/amd64/iso-cd/"
    ISO_NAME="debian-wheezy-DI-b4-amd64-netinst.iso"
    iso
    manage
    ;;
    backtrack)
    RANGE=${3}
    VMNAME=${2}
    OSTYPE=Debian_64
    RAM=1000
    ISO_REMOTE="http://ftp.halifax.rwth-aachen.de/backtrack/"
    ISO_NAME="BT5R3-GNOME-64.iso"
    iso
    manage
    ;;
    gentoo)
    VMNAME=${2}
    RANGE=${3}
    OSTYPE=Gentoo_64
    RAM=2000
    ISO_REMOTE="http://gentoo.ussg.indiana.edu//releases/amd64/12.1/"
    ISO_NAME="livedvd-amd64-multilib-2012.1.iso"
    iso
    manage
    ;;
    export)
    VMNAME=${2}
    export
    ;;
    import)
    VMNAME=${2}
    import
    ;;
    start)
    VMNAME=${2}
    start
    ;;
     die)
    VMNAME=${2}
    killsingle
    ;;
    *)
    help
    exit 1
esac
help
