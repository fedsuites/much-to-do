#!/bin/bash
set -euo pipefail

# Health check against the ALB
# Usage: ./health-check.sh <alb-dns-name>

ALB_DNS=${1:-$ALB_DNS_NAME}
MAX_RETRIES=10
RETRY_INTERVAL=15
HEALTH_ENDPOINT="http://$ALB_DNS/health"

if [ -z "$ALB_DNS" ]; then
  echo "Usage: $0 <alb-dns-name>"
  exit 1
fi

echo " Running health check against $HEALTH_ENDPOINT"

for i in $(seq 1 $MAX_RETRIES); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --connect-timeout 5 --max-time 10 \
    "$HEALTH_ENDPOINT" || echo "000")

  if [ "$HTTP_CODE" = "200" ]; then
    echo " Health check passed (attempt $i/$MAX_RETRIES) — HTTP $HTTP_CODE"
    exit 0
  fi

  echo " Attempt $i/$MAX_RETRIES — HTTP $HTTP_CODE — retrying in ${RETRY_INTERVAL}s..."
  sleep $RETRY_INTERVAL
done

echo " Health check failed after $MAX_RETRIES attempts"
exit 1