#!/bin/bash
# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Configure NAT (masquerade traffic from private subnets)
iptables -t nat -A POSTROUTING -s 10.0.0.0/16 -o ens5 -j MASQUERADE
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Save iptables
sudo apt update -y
sudo apt install -y iptables-persistent
sudo netfilter-persistent save