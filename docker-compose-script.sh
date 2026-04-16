#!/bin/bash

# 1. Setup Permissions (Add user to docker group if not already there)
if ! groups $USER | grep &>/dev/null "\bdocker\b"; then
  echo "Adding user $USER to docker group..."
  sudo usermod -aG docker $USER
  echo "Permissions updated. You may need to restart your session or run 'newgrp docker'."
fi

# 2. Install docker-compose if not present
if ! command -v docker-compose &> /dev/null; then
  echo "Installing docker-compose..."
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true
fi

# 3. Clean Redeploy
# We use 'down -v' to ensure the database volume is wiped and recreated.
# This guarantees that 'MYSQL_USER' and 'MYSQL_DATABASE' are created fresh.
echo "Performing clean redeploy with image: $1"
export DOCKER_IMAGE=$1

# We use sudo here just in case the group change hasn't kicked in yet for the current process
sudo -E docker-compose -f /home/ubuntu/docker-compose.yml pull app
sudo -E docker-compose -f /home/ubuntu/docker-compose.yml down -v
sudo -E docker-compose -f /home/ubuntu/docker-compose.yml up -d

echo "Application started. Waiting for database to stabilize..."
sleep 15
sudo docker ps