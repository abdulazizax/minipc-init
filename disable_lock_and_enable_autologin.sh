#!/bin/bash

USER_NAME=$(whoami)

echo ">>> LightDM auto-login sozlanmoqda..."

sudo mkdir -p /etc/lightdm/lightdm.conf.d

sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf > /dev/null <<EOF
[Seat:*]
autologin-user=$USER_NAME
autologin-user-timeout=0
EOF

echo ">>> XFCE lock screen o‘chirilmoqda..."

# Screensaver lock o‘chadi
xfconf-query -c xfce4-screensaver -p /lock/enabled -n -t bool -s false
xfconf-query -c xfce4-screensaver -p /lock/saver-activation -n -t bool -s false

# Sleep / suspend lock o‘chadi
xfconf-query -c xfce4-power-manager \
  -p /xfce4-power-manager/lock-screen-suspend-hibernate \
  -n -t bool -s false

echo ">>> Win+L (xflock4) shortcut o‘chirilmoqda..."

# Win+L shortcut olib tashlanadi
xfconf-query -c xfce4-keyboard-shortcuts \
  -p "/commands/custom/<Super>l" -r 2>/dev/null

echo ">>> Screensaver qayta ishga tushirilmoqda..."
xfce4-screensaver-command --exit 2>/dev/null

echo "======================================"
echo "TAYYOR ✅"
echo "Kompyuterni qayta yuklang (reboot)"
echo "======================================"
