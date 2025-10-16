#!/bin/bash
# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Configure NAT (masquerade traffic from private subnets)
iptables -t nat -A POSTROUTING -s 10.0.0.0/16 -o ens5 -j MASQUERADE

# Save iptables
apt update -y
apt install -y iptables-persistent
netfilter-persistent save