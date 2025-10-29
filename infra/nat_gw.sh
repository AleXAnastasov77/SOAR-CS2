#!/bin/bash
# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Detect main network interface dynamically
NIC=$(ip route show default | awk '/default/ {print $5}')

# Configure NAT dynamically
sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/16 -o $NIC -j MASQUERADE

# Persist rules
sudo apt update -y
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
