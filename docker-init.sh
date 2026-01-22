# Sistemani yangilash
sudo apt update
sudo apt upgrade -y

# Kerakli paketlarni o‘rnatish
sudo apt install -y ca-certificates curl gnupg lsb-release

# Docker GPG kalitini qo‘shish
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker repository qo‘shish
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Paketlar ro‘yxatini yangilash
sudo apt update

# Docker va Docker Compose plugin o‘rnatish
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
