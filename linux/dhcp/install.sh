#!/bin/bash
export MSYS_NO_PATHCONV=1
SCRIPT_ROOT=$(dirname $0)
ssh packer@192.168.200.1 sudo apt-get install isc-dhcp-server
scp $SCRIPT_ROOT/dhcpd.conf packer@192.168.200.1:~/dhcpd.conf
scp $SCRIPT_ROOT/isc-dhcp-server packer@192.168.200.1:~/isc-dhcp-server
ssh packer@192.168.200.1 'sudo cp ~/dhcpd.conf /etc/dhcp/dhcpd.conf'
ssh packer@192.168.200.1 'sudo cp ~/isc-dhcp-server /etc/default/isc-dhcp-server'
ssh packer@192.168.200.1 'sudo systemctl enable isc-dhcp-server'
ssh packer@192.168.200.1 'sudo systemctl restart isc-dhcp-server'