#!/bin/bash
#
# Xubuntu MiniPC kiosk: USB/xHCI "uxlash" va tizim uyqusini minimallashtirish.
# Ishlatish: sudo bash scripts/xubuntu-minipc-kiosk-usb-hardening.sh
#
# Nima qiladi:
#   - systemd-logind: idle/suspend tugmalari va qopqoq hodisalarini e'tiborsiz qoldirish (kiosk)
#   - GRUB: usbcore.autosuspend, usbhid.autosuspend, pcie_aspm=off (dublikat qo'shilmaydi)
#   - modprobe: usbcore autosuspend=-1
#   - minipc-usb-pci-power-on.sh + systemd service + timer (5 daqiqada qayta)
#   - sleep.target va suspend targetlarni mask (faqat kiosk; server emas)
#
set -euo pipefail

if [ "${EUID:-0}" -ne 0 ]; then
  echo "Root kerak: sudo $0" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRUB_FILE="/etc/default/grub"

echo "=== Xubuntu MiniPC kiosk USB / power hardening ==="

# ── 1) logind: hech qachon idle suspend qilmasin (XFCE bilan birga) ─────────
mkdir -p /etc/systemd/logind.conf.d
tee /etc/systemd/logind.conf.d/80-kiosk-no-suspend.conf >/dev/null <<'EOF'
[Login]
# Kiosk: ekran XFCE orqali boshqariladi; logind global suspend qilmasin
IdleAction=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF

systemctl restart systemd-logind.service || true

# ── 2) GRUB: kernel parametrlar (bir marta, dublikatsiyasiz) ─────────────────
append_grub_default_if_missing() {
  local param="$1"
  if [ ! -f "$GRUB_FILE" ]; then
    return 0
  fi
  local line
  line=$(grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE" | head -1 || true)
  if [ -z "$line" ]; then
    return 0
  fi
  if echo "$line" | grep -qF -- "$param"; then
    return 0
  fi
  # Qo'shtirnoq ichidagi oxirgi " oldidan param qo'shamiz
  sed -i 's|^\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"|\1 '"$param"'"|' "$GRUB_FILE"
  echo "  GRUB: qo'shildi: $param"
}

if [ -f "$GRUB_FILE" ]; then
  append_grub_default_if_missing "usbcore.autosuspend=-1"
  append_grub_default_if_missing "usbhid.autosuspend=-1"
  append_grub_default_if_missing "pcie_aspm=off"
  if command -v update-grub >/dev/null 2>&1; then
    update-grub
  fi
fi

# ── 3) modprobe: modul yuklanganda ham autosuspend o'chiq bo'lsin ────────────
tee /etc/modprobe.d/zz-kiosk-usbcore.conf >/dev/null <<'EOF'
# Kiosk: USB core autosuspend o'chiq (GRUB bilan bir xil maqsad)
options usbcore autosuspend=-1
EOF

# ── 4) USB + PCI power on skripti va systemd ─────────────────────────────────
install -m 0755 "$SCRIPT_DIR/minipc-usb-pci-power-on.sh" /usr/local/bin/minipc-usb-pci-power-on.sh

tee /etc/systemd/system/minipc-usb-pci-power-on.service >/dev/null <<'EOF'
[Unit]
Description=USB + PCI runtime PM off (Xubuntu kiosk)
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/minipc-usb-pci-power-on.sh

[Install]
WantedBy=multi-user.target
EOF

tee /etc/systemd/system/minipc-usb-pci-power-on.timer >/dev/null <<'EOF'
[Unit]
Description=Periodic USB + PCI power-on refresh

[Timer]
OnBootSec=2min
OnUnitInactiveSec=5min
Unit=minipc-usb-pci-power-on.service
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now minipc-usb-pci-power-on.service
systemctl enable --now minipc-usb-pci-power-on.timer

# Eski setup.sh dagi oddiy usb-power-on.service bilan ikki marta bir xil ish bajarilmasin
if systemctl is-enabled usb-power-on.service &>/dev/null; then
  systemctl disable --now usb-power-on.service 2>/dev/null || true
  echo "  Eski usb-power-on.service o'chirildi (minipc-usb-pci-power-on bilan almashtirildi)"
fi

# ── 5) Tizim uyqusini bloklash (kiosk; masofadan boshqarilmaydigan stend) ─────
# Agar masofadan suspend kerak bo'lsa, bu qatorlarni o'chirib qo'ying.
for t in sleep.target suspend.target hibernate.target hybrid-sleep.target; do
  if systemctl list-unit-files "$t" &>/dev/null; then
    systemctl mask --now "$t" 2>/dev/null || true
  fi
done

# ── 6) TLP o'rnatilgan bo'lsa, USB autosuspend o'chiq bo'lsin ─────────────────
if [ -f /etc/tlp.conf ]; then
  if ! grep -q '^USB_AUTOSUSPEND=0' /etc/tlp.conf; then
    echo "" >> /etc/tlp.conf
    echo "# kiosk: added by xubuntu-minipc-kiosk-usb-hardening.sh" >> /etc/tlp.conf
    echo "USB_AUTOSUSPEND=0" >> /etc/tlp.conf
    systemctl restart tlp.service 2>/dev/null || true
    echo "  TLP: USB_AUTOSUSPEND=0 qo'shildi"
  fi
fi

echo ""
echo "=== Tayyor ==="
echo "  - logind: /etc/systemd/logind.conf.d/80-kiosk-no-suspend.conf"
echo "  - GRUB + modprobe: qayta yuklangandan keyin to'liq kuchga kiradi"
echo "  - minipc-usb-pci-power-on: service + timer faol"
echo "  - sleep/suspend targetlar mask qilindi (kiosk)"
echo ""
echo "  REBOOT tavsiya: sudo reboot"
echo ""
