# -*- syntax: sh -*-
#!/bin/sh

if [ $HOSTNAME = student ]; then
    get http://download.virtualbox.org/virtualbox/4.2.4/VirtualBox-4.2-4.2.4_81684_el6-1.x86_64.rpm -O /tmp/VirtualBox.rpm
    cd /etc/yum.repos.d
    wget http://public-yum.oracle.com/public-yum.ol6.repo
    su -c 'yum install git'
    cd $HOME && git clone https://github.com/pandrew/vm-helpers.git
fi
