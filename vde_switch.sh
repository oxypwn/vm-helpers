vde_switch -tap tap0 -mod 660 -group kvm -daemon
ip addr add 10.0.2.1/24 dev tap0
ip link set dev tap0 up
