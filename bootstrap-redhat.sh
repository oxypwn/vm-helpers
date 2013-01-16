# -*- syntax: sh -*-
#!/bin/sh

if [ $HOSTNAME == student ]; then
    wget http://download.virtualbox.org/virtualbox/4.2.6/VirtualBox-4.2-4.2.6_82870_el6-1.x86_64.rpm -O /tmp/VirtualBox.rpm
    cd /etc/yum.repos.d
    su -c 'rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
    su -c 'yum -y install kernel-headers'
    su -c '/etc/init.d/vboxdrv setup'
    su -c 'yum install git'
    cd $HOME && git clone https://github.com/pandrew/vm-helpers.git

    wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -O /tmp/chrome.rpm
fi
