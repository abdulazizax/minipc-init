#!/bin/bash

# Xubuntu MiniPC sozlash skripti
# 1. Avtomatik login
# 2. Kursorni yashirish
# 3. Ekran o'chishini o'chirish

echo "=== Xubuntu MiniPC sozlash boshlandi ==="

# Foydalanuvchi nomini aniqlash
USERNAME=$(whoami)
echo "Joriy foydalanuvchi: $USERNAME"

# 1. AVTOMATIK LOGIN (LightDM uchun)
echo ""
echo "1. Avtomatik login sozlanmoqda..."

# LightDM konfiguratsiya faylini yaratish/tahrirlash
sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf > /dev/null <<EOF
[Seat:*]
autologin-user=$USERNAME
autologin-user-timeout=0
autologin-session=xubuntu
EOF

echo "✓ Avtomatik login sozlandi"

# 2. KURSORNI YASHIRISH
echo ""
echo "2. Kursorni yashirish sozlanmoqda..."

# unclutter dasturini o'rnatish (kursor yashirish uchun)
if ! command -v unclutter &> /dev/null; then
    echo "unclutter o'rnatilmoqda..."
    sudo apt-get update
    sudo apt-get install -y unclutter
fi

# Autostart papkasini yaratish
mkdir -p ~/.config/autostart

# unclutter uchun autostart fayli yaratish
cat > ~/.config/autostart/unclutter.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Unclutter
Comment=Hide cursor when idle
Exec=unclutter -idle 0.1 -root
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

echo "✓ Kursor yashirish sozlandi"

# 3. EKRAN O'CHISHINI O'CHIRISH
echo ""
echo "3. Ekran o'chishini o'chirish sozlanmoqda..."

# XFCE quvvat boshqaruvini o'chirish
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-battery -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-off -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-battery-sleep -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-battery-off -s 0

# Screensaver ni o'chirish
xfconf-query -c xfce4-screensaver -p /saver/enabled -s false
xfconf-query -c xfce4-screensaver -p /lock/enabled -s false

# X server DPMS ni o'chirish
cat > ~/.config/autostart/disable-dpms.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Disable DPMS
Comment=Disable screen blanking
Exec=sh -c "xset s off && xset -dpms && xset s noblank"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Hoziroq qo'llash
xset s off
xset -dpms
xset s noblank

echo "✓ Ekran o'chishi o'chirildi"

# 4. QO'SHIMCHA SOZLAMALAR
echo ""
echo "4. Qo'shimcha sozlamalar..."

# Screensaver paketini o'chirish (agar o'rnatilgan bo'lsa)
if dpkg -l | grep -q xfce4-screensaver; then
    sudo systemctl mask xfce4-screensaver.service 2>/dev/null
fi

echo "✓ Qo'shimcha sozlamalar bajarildi"

echo ""
echo "=== Barcha sozlamalar muvaffaqiyatli bajarildi ==="
echo ""
echo "ESLATMA:"
echo "1. Avtomatik login ishlashi uchun kompyuterni qayta ishga tushiring"
echo "2. Kursor avtomatik ravishda yashirinadi (harakatlanmasa)"
echo "3. Ekran hech qachon o'chmaydi"
echo ""
echo "Qayta ishga tushirish: sudo reboot"
