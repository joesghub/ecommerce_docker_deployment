#!/bin/bash

#############################################
######## INSTALLING NODE EXPORTER ###########
#############################################

# Install wget if not already installed
sudo apt install wget -y

# Download and install Node Exporter
NODE_EXPORTER_VERSION="1.5.0"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

# Create a Node Exporter user
sudo useradd --no-create-home --shell /bin/false node_exporter

# Create a Node Exporter service file
cat << EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, start and enable Node Exporter service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Print the public IP address and Node Exporter port
echo "Node Exporter installation complete. It's accessible at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9100/metrics"

# Add Node Exporter job to Prometheus config
cat << EOF | sudo tee -a /opt/prometheus/prometheus.yml

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Restart Prometheus to apply the new configuration
#sudo systemctl restart prometheus

echo "Node Exporter job added to Prometheus configuration."  #Prometheus has been restarted.

#############################################
### INSTALLING DOCKER AND DOCKER COMPOSE ####
#############################################

# Step 1: Update system and install prerequisites
echo "Updating system and installing prerequisites..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl lsb-release

# Step 2: Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Step 3: Add the Docker repository to Apt sources
echo "Adding Docker repository to Apt sources..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 4: Update apt repository list
echo "Updating apt package list..."
sudo apt-get update -y

# Step 5: Install Docker
echo "Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 6: Create the docker group (if not already created)
echo "Creating the docker group (if not exists)..."
if ! getent group docker > /dev/null 2>&1; then
  sudo groupadd docker
else
  echo "Docker group already exists."
fi

# Step 7: Add user to the Docker group
echo "Adding user $USER to the docker group..."
sudo usermod -aG docker $USER

# Step 8: Apply group changes
echo "Applying group changes (newgrp)..."
newgrp docker

# Step 9: Verify Docker installation
echo "Verifying Docker installation with hello-world image..."
docker run hello-world

# Step 10: Final verification of the installation and group membership
echo "Verifying user is in the Docker group..."
groups $USER
id -nG $USER

# Step 11: Final message
echo "Docker installation complete. Please log out and log back in for group changes to fully take effect."


#############################################
########### LOG IN TO DOCKER HUB ############
#############################################

echo "Logging into DockerHub..."
echo "${docker_pass}" | docker login --username "${docker_user}" --password-stdin || {
  echo "Docker login failed!" >&2
  exit 1
}

##############################################
# BUILD, DEPLOY, AND CLEAN UP DOCKER COMPOSE #
##############################################


echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating app directory..."
mkdir -p /app
cd /app
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Created and moved to /app"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating docker-compose.yml..."
cat > docker-compose.yml <<EOF
${docker_compose}
EOF
echo "[$(date '+%Y-%m-%d %H:%M:%S')] docker-compose.yml created"

docker compose pull
docker compose up -d --force-recreate
echo "Docker Compose services deployed."

# Cleanup
docker logout
docker system prune -f

echo "Cleanup complete."