#!/bin/sh
sudo apt-get install isc-dhcp-server
INTERFACES=eth0

sudo sed -e 's/^#DHCPDv4_CONF=/DHCPDv4_CONF=/g' \
    -e 's/^#DHCPDv4_PID=/DHCPDv4_PID=/g' \
    -e "s/INTERFACESv4=\"\"/INTERFACESv4=\"${INTERFACES}\"/g" \
    -i /etc/default/isc-dhcp-server