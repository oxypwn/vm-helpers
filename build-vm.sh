#!/bin/sh -e

# VirtualBox VM provisioning script
# https://github.com/ajclark/preseed/blob/master/build-vm.sh
# VBoxManage list ostypes | grep "ID:" | sed -e '/Family ID:/d' | awk '{ print $2}'



which -s VBoxManage || exit 1

function iso()
{
ISO_LOCAL=~/Downloads
while [ ! -e $ISO_LOCAL/$ISO_NAME ]; do
    /usr/bin/curl -L $ISO_REMOTE/$ISO_NAME -o $ISO_LOCAL/$ISO_NAME
done
}

function create()
{
# Create VM, set boot order
VBoxManage createvm --name $VMNAME --ostype $OSTYPE --register
VBoxManage modifyvm $VMNAME --memory $RAM --boot1 dvd --cpus 1


if [ "`hostname -s`" = stewie ]; then
    VBoxManage modifyvm $VMNAME --nic1 bridged --bridgeadapter1 "en0: Ethernet" --nictype1 82540EM --cableconnected1 on
else
    VBoxManage modifyvm $VMNAME --nic1 bridged --bridgeadapter1 "p4p1" --nictype1 82540EM --cableconnected1 on
fi
VBoxManage modifyvm $VMNAME --nic2 intnet --nictype2 82540EM --cableconnected2 on

# Add hard disk
VBoxManage storagectl $VMNAME --name "SATA Controller" --add sata
VBoxManage createhd --filename ~/.VirtualBox/${VMNAME}_hdd.vdi --size 51200
VBoxManage storageattach $VMNAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium ~/.VirtualBox/${VMNAME}_hdd.vdi

# Add DVD-ROM
VBoxManage storagectl $VMNAME --name "IDE Controller" --add ide
VBoxManage storageattach $VMNAME --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $ISO_LOCAL/$ISO_NAME

# Start VM
VBoxManage startvm $VMNAME || VBoxManage unregistervm --delete $VMNAME
}

function help()
{
    echo $"Usage: $0 <ostype> <comment>\n"
    echo -e "Ostypes:\n"
    echo -e 'debian\n centos\n obsd\n'

}

if [ -z $2 ];then
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
	iso
	create
	;;
    centos)
	VMNAME=${2}
	OSTYPE=RedHat_64
	RAM=512
	ISO=centos.iso
	iso
	create
	;;
    debian)
	VMNAME=${2}
	OSTYPE=Debian_64
	RAM=1000
	ISO_REMOTE="http://cdimage.debian.org/cdimage/wheezy_di_beta3/amd64/iso-cd/"
	ISO_NAME="debian-wheezy-DI-b3-amd64-netinst.iso"
	iso
	create
	;;
    bt)
        VMNAME=${2}
        OSTYPE=Debian_64
        RAM=1000
        ISO_REMOTE="http://ftp.halifax.rwth-aachen.de/backtrack/"
        ISO_NAME="BT5R3-GNOME-64.iso"
        iso
        create
        ;;
    *)
	help
	exit 1
esac




 
python -m SimpleHTTPServer

