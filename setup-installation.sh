#!/bin/bash

USER_NAME=$(whoami)

echo ">>> LightDM auto-login sozlanmoqda..."

sudo mkdir -p /etc/lightdm/lightdm.conf.d

sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf > /dev/null <<EOF
[Seat:*]
autologin-user=$USER_NAME
autologin-user-timeout=0
EOF

echo ">>> XFCE lock screen o'chirilmoqda..."

# Screensaver lock o'chadi
xfconf-query -c xfce4-screensaver -p /lock/enabled -n -t bool -s false
xfconf-query -c xfce4-screensaver -p /lock/saver-activation -n -t bool -s false

# Sleep / suspend lock o'chadi
xfconf-query -c xfce4-power-manager \
  -p /xfce4-power-manager/lock-screen-suspend-hibernate \
  -n -t bool -s false

echo ">>> Win+L (xflock4) shortcut o'chirilmoqda..."

# Win+L shortcut olib tashlanadi
xfconf-query -c xfce4-keyboard-shortcuts \
  -p "/commands/custom/<Super>l" -r 2>/dev/null

echo ">>> Screensaver qayta ishga tushirilmoqda..."
xfce4-screensaver-command --exit 2>/dev/null

echo ">>> Sichqoncha kursorini burchakga ko'chirish scripti yaratilmoqda..."

# xdotool o'rnatish (agar o'rnatilmagan bo'lsa)
sudo apt install -y xdotool

# Autostart uchun directory yaratish
mkdir -p ~/.config/autostart

# Sichqoncha kursorini burchakga ko'chirish scripti
mkdir -p ~/scripts
tee ~/scripts/move_cursor_corner.sh > /dev/null <<'SCRIPT'
#!/bin/bash

# 2 soniya kutish (desktop to'liq yuklangandan keyin)
sleep 2

# Sichqoncha kursorini ekranning chap yuqori burchagiga ko'chirish (0,0)
# Yoki o'ng pastki burchakka: xdotool mousemove 9999 9999
xdotool mousemove 0 0
SCRIPT

chmod +x ~/scripts/move_cursor_corner.sh

# Autostart yaratish
tee ~/.config/autostart/move-cursor.desktop > /dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Move Cursor to Corner
Exec=$HOME/scripts/move_cursor_corner.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Moves mouse cursor to corner on startup
EOF

echo "======================================"
echo "TAYYOR ✅"
echo ""
echo "Sozlamalar:"
echo "  - Auto-login yoqildi"
echo "  - Lock screen o'chirildi"
echo "  - Win+L shortcut o'chirildi"
echo "  - Sichqoncha kursorini avtomatik ko'chirish yoqildi"
echo ""
echo "Sichqoncha joylashuvi:"
echo "  - Chap yuqori burchak (0,0)"
echo ""
echo "Boshqa burchakka o'zgartirish uchun:"
echo "  nano ~/scripts/move_cursor_corner.sh"
echo "  (0 0 = chap yuqori, 9999 9999 = o'ng pastki)"
echo ""
echo "Kompyuterni qayta yuklang (reboot)"
echo "======================================"
