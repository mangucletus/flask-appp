#!/bin/bash
# CodeDeploy AfterInstall hook — rebuilds the venv and (re)installs the systemd unit.
set -e

# Ensure Python tooling is present (handles a fresh AMI with no prior bootstrap).
apt update -y
apt install -y python3 python3-venv python3-pip

cd /home/ubuntu/flask-app

# (Re)create the venv and install dependencies.
python3 -m venv venv
./venv/bin/pip install -r requirements.txt

# Fix ownership in case CodeDeploy unpacked files as root.
chown -R ubuntu:ubuntu /home/ubuntu/flask-app

# Write/refresh the systemd unit so future restarts use the latest config.
cat > /etc/systemd/system/flaskapp.service <<EOF
[Unit]
Description=Flask App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/flask-app
ExecStart=/home/ubuntu/flask-app/venv/bin/gunicorn \\
  --workers 3 --bind 0.0.0.0:80 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd so it picks up any changes to the unit file above.
systemctl daemon-reload
