#!/bin/bash
# Stop the running Flask service if it exists
if systemctl is-active --quiet flaskapp; then
systemctl stop flaskapp
fi
exit 0