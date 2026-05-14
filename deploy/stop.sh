#!/bin/bash
# CodeDeploy ApplicationStop hook — stops the running service before new code lands.

# Only stop if the unit is currently active (avoids non-zero exit on first deploy).
if systemctl is-active --quiet flaskapp; then
  systemctl stop flaskapp
fi

exit 0
