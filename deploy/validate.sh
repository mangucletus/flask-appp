#!/bin/bash
# CodeDeploy ValidateService hook — confirms the app is actually responding post-deploy.

# Poll /health for up to 30 seconds (gunicorn workers take a moment to come up).
for i in {1..30}; do
  if curl -fs http://localhost/health > /dev/null; then
    echo "Service is healthy"
    exit 0
  fi
  sleep 1
done

# Still not responding — fail the deployment so CodeDeploy rolls back.
echo "Service did not become healthy in time"
exit 1
