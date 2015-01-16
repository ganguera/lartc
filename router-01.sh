#!/usr/bin/env bash

# Install packages
apt-get update
apt-get install -y vim vlan bridge-utils dhcp3-server

# Configure VLAN
modprobe 8021q
echo "8021q" >> /etc/modules

# Enable ip_forward
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/20-ip_forward.conf

# Create routing tables
cat << EOF >> /etc/iproute2/rt_tables
10  ISP-01
20  ISP-02
EOF

# Configure interfaces
cat << EOF >> /etc/network/interfaces

auto eth1.10
iface eth1.10 inet static
  address 172.16.10.2
  netmask 255.255.255.252
  vlan-raw-device eth1
  post-up ip route add 172.16.10.0/30 dev eth1.10 src 172.16.10.2 table ISP-01
  post-up ip route add default via 172.16.10.1 table ISP-01
  post-up ip route add 172.16.10.0/30 dev eth1.10 table ISP-02
  post-up ip route add 127.0.0.0/8 dev lo table ISP-01
  post-up ip rule add from 172.17.10.0/24 table ISP-01
  pre-down ip rule del from 172.17.10.0/24 table ISP-01
  pre-down ip route flush table ISP-01

auto eth1.20
iface eth1.20 inet static
  address 172.16.20.2
  netmask 255.255.255.252
  vlan-raw-device eth1
  post-up ip route add 172.16.20.0/30 dev eth1.20 src 172.16.20.2 table ISP-02
  post-up ip route add default via 172.16.20.1 table ISP-02
  post-up ip route add 172.16.20.0/30 dev eth1.20 table ISP-01
  post-up ip route add 127.0.0.0/8 dev lo table ISP-02
  post-up ip rule add from 172.17.50.0/24 table ISP-02
  pre-down ip rule del from 172.17.50.0/24 table ISP-02
  pre-down ip route flush table ISP-02

#auto eth2
#iface eth2 inet static
#  address 172.17.10.1
#  netmask 255.255.255.0
#  post-up ip route add 172.17.10.0/24 dev eth2 table ISP-01
#  post-up ip route add 172.17.10.0/24 dev eth2 table ISP-02

#auto eth3
#iface eth3 inet static
#  address 172.17.20.1
#  netmask 255.255.255.0

auto eth2
iface eth2 inet manual

auto eth3
iface eth3 inet manual

auto br0
iface br0 inet static
  bridge_ports eth2 eth3
  address 172.17.10.1
  netmask 255.255.255.0
  post-up ip route add 172.17.10.0/24 dev br0 table ISP-01
  post-up ip route add 172.17.10.0/24 dev br0 table ISP-02
EOF

# Restart networking
/etc/init.d/networking restart

# Configure DHCP
sed -i 's/INTERFACES=""/INTERFACES="br0"/' /etc/default/isc-dhcp-server

rm /etc/dhcp/dhcpd.conf

cat << EOF >> /etc/dhcp/dhcpd.conf
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;
subnet 172.17.10.0 netmask 255.255.255.0 {
  range 172.17.10.11 172.17.10.15;
}

EOF

/etc/init.d/isc-dhcp-server restart

exit 0