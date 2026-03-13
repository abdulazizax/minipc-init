nmcli connection modify "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.7.20/24 \
  ipv4.gateway 192.168.7.10 \
  ipv4.dns "8.8.8.8,8.8.4.4"

nmcli connection down "Wired connection 1" && nmcli connection up "Wired connection 1"