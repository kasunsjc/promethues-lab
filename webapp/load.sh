#!/usr/bin/env bash
# Generate a steady stream of traffic against the sample webapp so traces,
# metrics, and logs flow through the OpenTelemetry Collector to Loki/Prometheus.
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:5000}"
INTERVAL="${INTERVAL:-1}"
ENDPOINTS=("/" "/work" "/chain" "/error")

echo "Generating traffic against $BASE_URL (Ctrl+C to stop)"
while true; do
  ep="${ENDPOINTS[$RANDOM % ${#ENDPOINTS[@]}]}"
  code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$ep" || echo "ERR")
  printf '%s  %-8s -> %s\n' "$(date +%T)" "$ep" "$code"
  sleep "$INTERVAL"
done
