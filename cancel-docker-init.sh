#!/bin/bash

# Docker complete removal script
# Removes Docker, containers, images, volumes, and configurations

set -e

echo "========================================="
echo "Docker Complete Removal Script"
echo "========================================="
echo ""

# 1. Docker containerlarni to'xtatish
echo "[1/7] Stopping all Docker containers..."
sudo docker stop $(sudo docker ps -aq) 2>/dev/null || echo "No running containers"

# 2. Barcha containerlarni o'chirish
echo "[2/7] Removing all Docker containers..."
sudo docker rm $(sudo docker ps -aq) 2>/dev/null || echo "No containers to remove"

# 3. Barcha imagelarni o'chirish
echo "[3/7] Removing all Docker images..."
sudo docker rmi $(sudo docker images -q) -f 2>/dev/null || echo "No images to remove"

# 4. Barcha volumelarni o'chirish
echo "[4/7] Removing all Docker volumes..."
sudo docker volume rm $(sudo docker volume ls -q) 2>/dev/null || echo "No volumes to remove"

# 5. Barcha networklar o'chirish (default'lardan tashqari)
echo "[5/7] Removing all Docker networks..."
sudo docker network rm $(sudo docker network ls -q) 2>/dev/null || echo "No custom networks to remove"

# 6. Docker xizmatini to'xtatish
echo "[6/7] Stopping Docker service..."
sudo systemctl stop docker.socket 2>/dev/null || true
sudo systemctl stop docker 2>/dev/null || true

# 7. Docker paketlarini butunlay o'chirish
echo "[7/7] Removing Docker packages..."
sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
sudo apt autoremove -y

# 8. Docker fayllarini o'chirish
echo "[8/8] Removing Docker files and directories..."
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker
sudo rm -rf /var/run/docker.sock
sudo rm -rf /usr/local/bin/docker-compose
sudo rm -rf ~/.docker

# 9. Docker guruhini o'chirish
sudo groupdel docker 2>/dev/null || true

# 10. Docker repository o'chirish
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.gpg

echo ""
echo "========================================="
echo "✅ Docker completely removed!"
echo "========================================="
echo ""
echo "You can now run the installation script."
echo ""
