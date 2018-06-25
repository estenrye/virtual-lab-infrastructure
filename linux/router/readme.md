# Router Configuration
This configuration is largely based off the following web resources:
* (The Ars guide to building a Linux router from scratch)[https://arstechnica.com/gadgets/2016/04/the-ars-guide-to-building-a-linux-router-from-scratch/]
* (Ubuntu 18.04: Install isc-dhcp-server for DHCP server)[https://www.hiroom2.com/2018/05/06/ubuntu-1804-isc-dhcp-server-en/]


# Purpose
I needed a lightweight DHCP router and firewall configuration for my virtual lab that would run on a Generation 2 Hyper-V virtual machine.  This configuration setus up Ubuntu 18.04 to be a simple router.

# Configuring the Network Interfaces.
Ubuntu 18.04 changed the way network interfaces are configured with the recent addition of netplan.  For my router, I configured the Hyper-V virtual machine with two NICs.  One connected to the `Default Switch` which external (WAN) and one connected to `packer-hyperv-iso` which is internal (LAN) and not connected to the internet.  Because I configured the WAN interface first, it is `eth0` and the LAN interface is `eth1`.  Below is my yaml netplan configuration, note indentation is incredibly important in yaml, a missed space will cause you pain.

```yaml
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: yes
    eth1:
      dhcp4: no
      dhcp6: no
      addresses: [192.168.200.1/24]
```

This configuration lives in `/etc/netplan/01-netcfg.yaml`.  Your filename may or may not differ depending on your particular installation and network cards.  Once you have completed your edits to your configuration file, run the following command to apply it.

```bash
sudo netplan apply
```

# Enable forwarding in /etc/sysctl.conf
Uncomment the following lines to enable IPV4 and IPV6 forwarding.
```conf
# Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward=1

# Uncomment the next line to enable packet forwarding for IPv6
#  Enabling this option disables Stateless Address Autoconfiguration
#  based on Router Advertisements for this host
net.ipv6.conf.all.forwarding=1
```

Apply the changes with the following command:

```bash
sudo sysctl -p
```

# Enavle DHCP and DNS
Install `isc-dhcp-server` and `bind9`
```bash
suod apt-get udpate
sudo apt-get install isc-dhcp-server
sudo apt-get install bind9
```

Configure dhcp subnets and static addresses.
```bash
sudo vi /etc/dhcp/dhcpd.conf
```

My configuration file:
```conf
option domain-name "ryezone.lab";

default-lease-time 600;
max-lease-time 7200;

ddns-update-style none;

authoritative;

subnet 192.168.200.0 netmask 255.255.255.0 {
  range 192.168.200.100 192.168.200.199;
  option routers 192.168.200.1;
  option domain-name-servers 192.168.200.1;
  option broadcast-address 192.168.200.255;
}

host builder {
  hardware ethernet 00:e5:10:00:00:01;
  fixed-address 192.168.200.3;
  option host-name "builder.ryezone.lab";
}
```

Configure the isc-dhcp-server configuration file

```bash
sudo vi /etc/default/isc-dhcp-server
```

My configuration file.  Note the LAN interface in the `INTERFACESv4` list.  This tells the dhcpserver to listen for dhcp requests on the LAN interface.

```conf
# Defaults for isc-dhcp-server (sourced by /etc/init.d/isc-dhcp-server)

# Path to dhcpd's config file (default: /etc/dhcp/dhcpd.conf).
DHCPDv4_CONF=/etc/dhcp/dhcpd.conf
#DHCPDv6_CONF=/etc/dhcp/dhcpd6.conf

# Path to dhcpd's PID file (default: /var/run/dhcpd.pid).
DHCPDv4_PID=/var/run/dhcpd.pid
#DHCPDv6_PID=/var/run/dhcpd6.pid

# Additional options to start dhcpd with.
#	Don't use options -cf or -pf here; use DHCPD_CONF/ DHCPD_PID instead
#OPTIONS=""

# On what interfaces should the DHCP server (dhcpd) serve DHCP requests?
#	Separate multiple interfaces with spaces, e.g. "eth0 eth1".
INTERFACESv4="eth1"
INTERFACESv6=""
```

Enable DHCP to start on boot and apply the configuration.
```bash
sudo systemctl enable isc-dhcp-server
sudo systemctl restart isc-dhcp-server
sudo systemctl status isc-dhcp-server
```

# Configure iptables

```bash
sudo vi /etc/network/if-pre-up.d/iptables
```

Add the following script:

```bash
#!/bin/sh
/sbin/iptables-restore < /etc/network/iptables
```

Configure proper ownership and permissions:

```bash
sudo chown root /etc/network/if-pre-up.d/iptables
sudo chmod 755 /etc/network/if-pre-up.d/iptables
```

Create an iptables ruleset:

```conf
# Enable NAT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

# eth0 is WAN interface, eth1 is LAN interface
-A POSTROUTING -o eth0 -j MASQUERADE

COMMIT

*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]

# Service rules

# basic global accept rules - ICMP, loopback, traceroute, established all accepted
-A INPUT -s 127.0.0.0/8 -d 127.0.0.0/8 -i lo -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -m state --state ESTABLISHED -j ACCEPT

# enable traceroute rejections to get sent out
-A INPUT -p udp -m udp --dport 33434:33523 -j REJECT

# DNS accept from LAN
-A INPUT -i eth1 -p tcp --dport 53 -j ACCEPT
-A INPUT -i eth1 -p udp --dport 53 -j ACCEPT

# SSH accept from LAN
-A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT

# DHCP client requests - accept from LAN
-A INPUT -i eth1 -p udp --dport 67:68 -j ACCEPT

# drop all other inbound traffic
-A INPUT -j DROP

# Forwarding rules

# Forward all packets along established/related connections
-A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Forward from LAN (eth1) to WAN (eth0)
-A FORWARD -i eth1 -o eth0 -j ACCEPT

# Drop all other forwarded traffic
-A FORWARD -j DROP

COMMIT
```

Apply the iptables configuration:

```bash
sudo /etc/network/if-pre-up.d/iptables
```