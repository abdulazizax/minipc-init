#!/bin/bash

# Usage: ./set-static-ip.sh 192.168.1.50

if [ -z "$1" ]; then
  echo "❌ Usage: $0 <IP_ADDRESS>"
  echo "Example: $0 192.168.1.50"
  exit 1
fi

NEW_IP="$1"

echo "🔧 Setting static IP: $NEW_IP"

# Validate IP format
if ! [[ $NEW_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Invalid IP address format"
  exit 1
fi

# Backup
sudo cp /etc/netplan/03-final-config.yaml /etc/netplan/03-final-config.yaml.backup-$(date +%Y%m%d-%H%M%S)

# Update config
sudo sed -i "s|addresses:\s*-\s*192\.168\.1\.[0-9]*/24|addresses:\n        - $NEW_IP/24|g" /etc/netplan/03-final-config.yaml

# Apply
sudo netplan apply

echo "✅ Done! enp6s0 is now $NEW_IP"
ip addr show enp6s0 | grep "inet "