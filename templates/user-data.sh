#!/bin/bash
# EC2 user-data: runs once on first boot, as root.

# Exit on error, treat unset vars as errors, and print each command before running it.
set -eux

# Redirect all output to a log file for post-boot debugging via SSH.
exec > /var/log/user-data.log 2>&1

# Install system dependencies: Python, venv support, pip, and git.
apt update -y
apt install -y python3 python3-venv python3-pip git

# Clone the app into the ubuntu user's home (skip if already present, so re-runs are safe).
cd /home/ubuntu
[ -d flask-app ] || git clone https://github.com/mangucletus/flask-app.git
chown -R ubuntu:ubuntu flask-app

# Create an isolated virtualenv and install Python dependencies into it.
cd flask-app
[ -d venv ] || python3 -m venv venv
./venv/bin/pip install -r requirement.txt

# Write a systemd unit so gunicorn starts on boot and restarts on crash.
cat > /etc/systemd/system/flaskapp.service <<'EOF'
[Unit]
Description=Flask App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/flask-app
ExecStart=/home/ubuntu/flask-app/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Load the new unit and start it now (also enables it for future boots).
systemctl daemon-reload
systemctl enable --now flaskapp


# Install the CodeDeploy agent so this instance can receive deployments.
apt install -y ruby-full wget
cd /tmp
# Region-specific installer — change the bucket region if your deployments live elsewhere.
wget https://aws-codedeploy-eu-west-1.s3.eu-west-1.amazonaws.com/latest/install
chmod +x ./install
./install auto > /tmp/codedeploy-install.log 2>&1

# Enable on boot + start now so the agent picks up future deployments.
systemctl enable codedeploy-agent
systemctl start codedeploy-agent