#!/usr/bin/env bash

# Install packages
apt-get update
apt-get install -y vim vlan lighttpd

# Configure VLAN
modprobe 8021q
echo "8021q" >> /etc/modules

# Enable ip_forward
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/20-ip_forward.conf

# Configure interfaces
cat << EOF >> /etc/network/interfaces

auto eth1.10
iface eth1.10 inet static
  address 172.16.10.1
  netmask 255.255.255.252
  vlan-raw-device eth1
  post-up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  post-up iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
  post-up iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
  post-up iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 80
  post-up ip route add 172.16.0.0/12 via 172.16.10.2
  pre-down iptables -t nat -F
  pre-down iptables -F
  pre-down ip route del 172.16.0.0/12 via 172.16.10.2
EOF

# Restart networking
/etc/init.d/networking restart

# Configure Lighttpd
echo "<H1>You are being routed through ISP-01</H1>" >> /var/www/index.html

exit 0