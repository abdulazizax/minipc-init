# MiniPC Init — Turnstile Setup Scripts

Xubuntu Linux bilan ishlaydigan MiniPC ni turniket tizimi uchun sozlash scriptlari.

## Setup nima qiladi

| # | Sozlama | Tavsif |
|---|---------|--------|
| 1 | Docker & Docker Compose | MiniPC kodlari Docker orqali ishlaydi |
| 2 | Auto-login | Yoqilganda parol so'ramaydi |
| 3 | Cursor yashirish | Kursor 0.1s harakatsiz bo'lsa yashirinadi |
| 4 | Ekran o'chmaslik | DPMS, screensaver, screen blanking o'chiriladi |
| 5 | Lock screen o'chirish | Ekran qulflanmaydi, Win+L ishlamaydi |
| 6 | USB-TTL serial port | Arduino uchun CH340 driver, brltty o'chiriladi |

## Ishlatish

```bash
# MiniPC ni to'liq sozlash
chmod +x setup.sh
sudo ./setup.sh

# So'ng qayta yuklash
sudo reboot
```

## Docker ni o'chirish (kerak bo'lsa)

```bash
chmod +x cancel-docker-init.sh
sudo ./cancel-docker-init.sh
```

## Fayllar

| Fayl | Tavsif |
|------|--------|
| `setup.sh` | Asosiy setup script — barcha sozlamalar |
| `cancel-docker-init.sh` | Docker ni butunlay o'chirish |
