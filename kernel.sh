echo 'options usbcore autosuspend=-1' | sudo tee /etc/modprobe.d/usb-autosuspend.conf

echo 'options xhci_hcd quirks=0x80' | sudo tee /etc/modprobe.d/xhci.conf

sudo update-initramfs -u