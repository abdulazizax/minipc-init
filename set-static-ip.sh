#!/bin/bash

# Usage: sudo ./set-static-ip.sh 192.168.1.50

NEW_IP="${1:-192.168.1.50}"

echo "🔧 Setting IP: $NEW_IP"

sudo tee /etc/netplan/01-static-ip.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      dhcp4: no
      addresses:
        - $NEW_IP/24
      nameservers:
        addresses:
          - 8.8.8.8
EOF

sudo chmod 600 /etc/netplan/01-static-ip.yaml
sudo netplan apply

echo "✅ Done! IP: $NEW_IP"
ip addr show enp1s0 | grep "inet "