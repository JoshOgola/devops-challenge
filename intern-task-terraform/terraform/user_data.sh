#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/user-data.log) 2>&1

# Create a non-root administrator with passwordless sudo.
useradd --create-home --shell /bin/bash --groups wheel appadmin
echo "appadmin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/appadmin
chmod 0440 /etc/sudoers.d/appadmin
visudo -cf /etc/sudoers.d/appadmin

# Install Docker and the host firewall.
yum update -y
yum install -y docker firewalld git
systemctl enable --now docker
systemctl enable --now firewalld

# Permit only SSH and the application's actual port at the host firewall.
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-port=5000/tcp
firewall-cmd --reload

# Fetch the challenge repository and build the actual Task 1 application.
mkdir -p /opt/intern-task-app
git clone --branch intern-task-app-solution --depth 1 https://github.com/JoshOgola/devops-challenge.git /opt/challenge
cd /opt/challenge/intern-task-app
docker build -t intern-task-app:local .

# Run the app on port 5000 and restart it if Docker restarts.
docker run -d \
  --name intern-task-app \
  --restart unless-stopped \
  -p 5000:5000 \
  intern-task-app:local
