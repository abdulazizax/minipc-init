#!/bin/bash

# CH340 USB-TTL setup script for Arduino development
# Removes brltty and configures serial drivers

set -e  # Xatolik bo'lsa to'xtaydi

echo "========================================="
echo "CH340 USB-TTL Setup Script"
echo "========================================="

# 1. brltty ni butunlay o'chirish
echo "[1/6] Removing brltty..."
sudo systemctl stop brltty-udev.service 2>/dev/null || true
sudo systemctl mask brltty-udev.service 2>/dev/null || true
sudo systemctl stop brltty.service 2>/dev/null || true
sudo systemctl disable brltty.service 2>/dev/null || true
sudo apt remove -y brltty 2>/dev/null || true
sudo apt autoremove -y

# 2. Zarur driverlarni avtomatik yuklash uchun sozlash
echo "[2/6] Configuring USB serial drivers..."
sudo tee /etc/modules-load.d/usb-serial.conf > /dev/null <<EOF
usbserial
ch341
ftdi_sio
cp210x
pl2303
EOF

# 3. Driverlarni hozir yuklash
echo "[3/6] Loading drivers..."
sudo modprobe usbserial
sudo modprobe ch341
sudo modprobe ftdi_sio
sudo modprobe cp210x
sudo modprobe pl2303

# 4. Foydalanuvchini dialout va tty guruhlariga qo'shish
echo "[4/6] Adding user to dialout and tty groups..."
sudo usermod -a -G dialout $USER
sudo usermod -a -G tty $USER

# 5. Udev qoidalarini sozlash (avtomatik ruxsatlar)
echo "[5/6] Setting up udev rules..."
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

# 6. Udev qoidalarini qayta yuklash
echo "[6/6] Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

echo ""
echo "========================================="
echo "✅ Setup completed successfully!"
echo "========================================="
echo ""
echo "IMPORTANT: Please log out and log back in"
echo "for group changes to take effect."
echo ""
echo "After re-login, connect your USB-TTL and run:"
echo "  ls -la /dev/ttyUSB*"
echo ""

# Test qilish (optional)
echo "Current user groups:"
groups $USER
echo ""
echo "Loaded serial drivers:"
lsmod | grep -E "ch341|ftdi_sio|cp210x|pl2303|usbserial"
