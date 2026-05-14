#!/bin/bash
# CodeDeploy ApplicationStart hook — enables the unit on boot and starts it now.
systemctl enable flaskapp
systemctl start flaskapp
