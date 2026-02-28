# 1. Custom netplan configni o'chirish
sudo rm -f /etc/netplan/01-static-ip.yaml

# 2. Default configni tiklash (NetworkManager orqali DHCP)
sudo tee /etc/netplan/01-network-manager-all.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: NetworkManager
EOF
sudo chmod 600 /etc/netplan/01-network-manager-all.yaml

# 3. Qo'llash
sudo netplan apply
sudo systemctl restart NetworkManager