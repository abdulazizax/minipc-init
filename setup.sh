#!/bin/bash

# MiniPC Complete Setup Script for Turnstile System
# Xubuntu Linux | Docker + Auto-login + Cursor hide + Screen always on + USB-TTL serial
#
# Usage: chmod +x setup.sh && sudo ./setup.sh

set -e

USERNAME=${SUDO_USER:-$(whoami)}
HOME_DIR=$(eval echo ~$USERNAME)

echo "========================================="
echo "  MiniPC Turnstile Setup"
echo "========================================="
echo "  User: $USERNAME"
echo "  Home: $HOME_DIR"
echo "========================================="
echo ""

# ─────────────────────────────────────────────
# 1. SYSTEM UPDATE
# ─────────────────────────────────────────────
echo "[1/6] Updating system..."
apt update
apt upgrade -y

# ─────────────────────────────────────────────
# 2. DOCKER & DOCKER COMPOSE
# ─────────────────────────────────────────────
echo ""
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
  echo "[2/6] Docker already installed, skipping..."
  echo "  Docker: $(docker --version)"
  echo "  Compose: $(docker compose version)"
else
  echo "[2/6] Installing Docker & Docker Compose..."

  apt install -y ca-certificates curl gnupg lsb-release

  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl enable docker
  systemctl start docker

  echo "  Docker: $(docker --version)"
  echo "  Compose: $(docker compose version)"
fi

usermod -a -G docker $USERNAME

# ─────────────────────────────────────────────
# 3. AUTO-LOGIN (LightDM)
# ─────────────────────────────────────────────
echo ""
echo "[3/6] Configuring auto-login (no password on boot)..."

mkdir -p /etc/lightdm/lightdm.conf.d

tee /etc/lightdm/lightdm.conf.d/50-autologin.conf > /dev/null <<EOF
[Seat:*]
autologin-user=$USERNAME
autologin-user-timeout=0
autologin-session=xubuntu
EOF

# ─────────────────────────────────────────────
# 4. HIDE CURSOR & DISABLE SCREEN OFF
# ─────────────────────────────────────────────
echo ""
echo "[4/6] Configuring cursor hide & screen always on..."

apt install -y unclutter

mkdir -p "$HOME_DIR/.config/autostart"

# unclutter: hides cursor after 0.1s of inactivity
cat > "$HOME_DIR/.config/autostart/unclutter.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Unclutter
Comment=Hide cursor when idle
Exec=unclutter -idle 0.1 -root
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# xset: disable DPMS and screen blanking
cat > "$HOME_DIR/.config/autostart/disable-dpms.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Disable DPMS
Comment=Disable screen blanking and power management
Exec=sh -c "xset s off && xset -dpms && xset s noblank"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

chown -R $USERNAME:$USERNAME "$HOME_DIR/.config/autostart"

# ─────────────────────────────────────────────
# 5. DISABLE LOCK SCREEN & SCREENSAVER
# ─────────────────────────────────────────────
echo ""
echo "[5/6] Disabling lock screen, screensaver, and power management..."

XFCONF_DIR="$HOME_DIR/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$XFCONF_DIR"

# Power manager: disable all screen blanking and DPMS
cat > "$XFCONF_DIR/xfce4-power-manager.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-power-manager" version="1.0">
  <property name="xfce4-power-manager" type="empty">
    <property name="dpms-enabled" type="bool" value="false"/>
    <property name="blank-on-ac" type="int" value="0"/>
    <property name="blank-on-battery" type="int" value="0"/>
    <property name="dpms-on-ac-sleep" type="uint" value="0"/>
    <property name="dpms-on-ac-off" type="uint" value="0"/>
    <property name="dpms-on-battery-sleep" type="uint" value="0"/>
    <property name="dpms-on-battery-off" type="uint" value="0"/>
    <property name="lock-screen-suspend-hibernate" type="bool" value="false"/>
    <property name="dpms-sleep-mode" type="string" value=""/>
  </property>
</channel>
EOF

# Screensaver: disable completely
cat > "$XFCONF_DIR/xfce4-screensaver.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-screensaver" version="1.0">
  <property name="saver" type="empty">
    <property name="enabled" type="bool" value="false"/>
    <property name="mode" type="int" value="0"/>
  </property>
  <property name="lock" type="empty">
    <property name="enabled" type="bool" value="false"/>
    <property name="saver-activation" type="bool" value="false"/>
  </property>
</channel>
EOF

chown -R $USERNAME:$USERNAME "$XFCONF_DIR"

# Mask screensaver service so it cannot start
systemctl mask xfce4-screensaver.service 2>/dev/null || true

# Also remove xfce4-screensaver package if installed
apt remove -y xfce4-screensaver 2>/dev/null || true

# ─────────────────────────────────────────────
# 6. USB-TTL SERIAL PORT (Arduino / CH340)
# ─────────────────────────────────────────────
echo ""
echo "[6/6] Configuring USB-TTL serial port for Arduino..."

# Remove brltty (it grabs the serial port)
systemctl stop brltty-udev.service 2>/dev/null || true
systemctl mask brltty-udev.service 2>/dev/null || true
systemctl stop brltty.service 2>/dev/null || true
systemctl disable brltty.service 2>/dev/null || true
apt remove -y brltty 2>/dev/null || true
apt autoremove -y

# Add user to serial groups
usermod -a -G dialout $USERNAME
usermod -a -G tty $USERNAME

# Auto-load USB serial drivers on boot
tee /etc/modules-load.d/usb-serial.conf > /dev/null <<EOF
usbserial
ch341
ftdi_sio
cp210x
pl2303
EOF

# Load drivers now
modprobe usbserial 2>/dev/null || true
modprobe ch341 2>/dev/null || true
modprobe ftdi_sio 2>/dev/null || true
modprobe cp210x 2>/dev/null || true
modprobe pl2303 2>/dev/null || true

# Udev rules for serial port permissions
tee /etc/udev/rules.d/50-usb-serial.rules > /dev/null <<'EOF'
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

# Generic serial ports
SUBSYSTEM=="tty", GROUP="dialout", MODE="0660"
KERNEL=="ttyUSB[0-9]*", MODE="0666"
KERNEL=="ttyACM[0-9]*", MODE="0666"
EOF

udevadm control --reload-rules
udevadm trigger

# ─────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────
echo ""
echo "========================================="
echo "  Setup completed successfully!"
echo "========================================="
echo ""
echo "  [x] Docker & Docker Compose installed"
echo "  [x] Auto-login enabled (no password)"
echo "  [x] Cursor auto-hide enabled"
echo "  [x] Screen will never turn off"
echo "  [x] Lock screen disabled"
echo "  [x] USB-TTL serial port configured"
echo ""
echo "  REBOOT REQUIRED: sudo reboot"
echo ""
echo "  After reboot, verify:"
echo "    docker run hello-world"
echo "    ls -la /dev/ttyUSB*"
echo "========================================="
