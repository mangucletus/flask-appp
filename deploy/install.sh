#!/bin/bash
set -e
# Make sure python3-venv is present (CodeDeploy may run on a fresh AMI)
apt update -y
apt install -y python3 python3-venv python3-pip
cd /home/ubuntu/flask-app
# (Re)create the venv and install dependencies
python3 -m venv venv
./venv/bin/pip install -r requirements.txt
chown -R ubuntu:ubuntu /home/ubuntu/flask-app
# Make sure the systemd service file exists
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
systemctl daemon-reload