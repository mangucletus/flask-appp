#!/bin/bash
# Wait up to 30 seconds for the app to respond on /health
for i in {1..30}; do
if curl -fs http://localhost/health > /dev/null; then
echo "Service is healthy"
exit 0
fi
sleep 1
done
echo "Service did not become healthy in time"
exit 1