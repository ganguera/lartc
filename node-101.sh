#!/usr/bin/env bash

# Install packages
apt-get update
apt-get install -y vim

# Configure interfaces
cat << EOF >> /etc/network/interfaces

auto eth1
iface eth1 inet dhcp
  post-up ip route del default via 10.0.2.2
  post-up ip route add default via 172.17.10.1
EOF

## Restart networking
/etc/init.d/networking restart

exit 0