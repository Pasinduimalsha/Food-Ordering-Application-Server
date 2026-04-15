#!/bin/bash
# Install docker-compose if not present
if ! command -v docker-compose &> /dev/null; then
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true
fi

# Run the application in detached mode
echo "Starting application with image: $1"
export DOCKER_IMAGE=$1
sudo -E docker-compose -f /home/ubuntu/docker-compose.yml up -d
docker-compose --version