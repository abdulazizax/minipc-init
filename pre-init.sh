#!/bin/bash

# Complete setup script for mini PCs
# - Installs Docker & Docker Compose
# - Removes brltty
# - Configures USB serial drivers for Arduino/CH340

set -e  # Xatolik bo'lsa to'xtaydi

echo "========================================="
echo "Mini PC Complete Setup Script"
echo "========================================="
echo ""

# 1. Sistema yangilanishi
echo "[1/9] Updating system..."
sudo apt update
sudo apt upgrade -y

# 2. brltty ni butunlay o'chirish (USB serial uchun)
echo "[2/9] Removing brltty..."
sudo systemctl stop brltty-udev.service 2>/dev/null || true
sudo systemctl mask brltty-udev.service 2>/dev/null || true
sudo systemctl stop brltty.service 2>/dev/null || true
sudo systemctl disable brltty.service 2>/dev/null || true
sudo apt remove -y brltty 2>/dev/null || true
sudo apt autoremove -y

# 3. Docker uchun kerakli paketlar
echo "[3/9] Installing prerequisites..."
sudo apt install -y ca-certificates curl gnupg lsb-release

# 4. Docker GPG kalitini qo'shish
echo "[4/9] Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 5. Docker repository qo'shish
echo "[5/9] Adding Docker repository..."
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 6. Paketlar ro'yxatini yangilash
echo "[6/9] Updating package list..."
sudo apt update

# 7. Docker va Docker Compose o'rnatish
echo "[7/9] Installing Docker and Docker Compose..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 8. Foydalanuvchini docker va serial guruhlariga qo'shish
echo "[8/9] Adding user to docker, dialout, and tty groups..."
sudo usermod -a -G docker $USER
sudo usermod -a -G dialout $USER
sudo usermod -a -G tty $USER

# 9. USB serial driverlar sozlash
echo "[9/9] Configuring USB serial drivers..."

# Driverlarni avtomatik yuklash
sudo tee /etc/modules-load.d/usb-serial.conf > /dev/null <<EOF
usbserial
ch341
ftdi_sio
cp210x
pl2303
EOF

# Driverlarni hozir yuklash
sudo modprobe usbserial 2>/dev/null || true
sudo modprobe ch341 2>/dev/null || true
sudo modprobe ftdi_sio 2>/dev/null || true
sudo modprobe cp210x 2>/dev/null || true
sudo modprobe pl2303 2>/dev/null || true

# Udev qoidalarini sozlash
sudo tee /etc/udev/rules.d/50-usb-serial.rules > /dev/null <<'EOF'
# CH340/CH341
SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666"
KERNEL=="ttyUSB*", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", GROUP="dialout"

# FTDI
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666"
KERNEL=="ttyUSB*", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666", GROUP="dialout"

# CP210x
SUBSYSTEM=="usb", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666"
KERNEL=="ttyUSB*", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"

# PL2303
SUBSYSTEM=="usb", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", MODE="0666"
KERNEL=="ttyUSB*", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", MODE="0666", GROUP="dialout"

# Umumiy serial portlar
SUBSYSTEM=="tty", GROUP="dialout", MODE="0660"
KERNEL=="ttyUSB[0-9]*", MODE="0666"
KERNEL=="ttyACM[0-9]*", MODE="0666"
EOF

# Udev qoidalarini qayta yuklash
sudo udevadm control --reload-rules
sudo udevadm trigger

# Docker xizmatini ishga tushirish va avtomatik ishga tushishni yoqish
sudo systemctl enable docker
sudo systemctl start docker

echo ""
echo "========================================="
echo "✅ Setup completed successfully!"
echo "========================================="
echo ""
echo "Installed versions:"
docker --version
docker compose version
echo ""
echo "User groups:"
groups $USER
echo ""
echo "⚠️  IMPORTANT:"
echo "1. Log out and log back in (or reboot) for group changes to take effect"
echo "2. After re-login, test Docker without sudo:"
echo "   docker run hello-world"
echo "3. Test USB serial:"
echo "   ls -la /dev/ttyUSB*"
echo ""
