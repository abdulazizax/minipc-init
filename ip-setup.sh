# 1. Static IP + gateway o'rnatish
nmcli connection modify "enp1s0" \
  ipv4.method manual \
  ipv4.addresses 192.168.7.20/24 \
  ipv4.gateway 192.168.7.10 \
  ipv4.dns "8.8.8.8,8.8.4.4"

# 2. Apply
nmcli connection down "enp1s0" && nmcli connection up "enp1s0"