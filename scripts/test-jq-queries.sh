#!/bin/bash
# Test script to validate jq queries for alerting APIs

echo "🧪 Testing jq queries for alerting APIs..."

# Mock Prometheus alerts API response
PROM_RESPONSE='{"status":"success","data":[{"labels":{"alertname":"InstanceDown","instance":"localhost:9100","job":"node"},"state":"firing","value":"1","activeAt":"2025-07-05T19:00:00Z"}]}'

# Mock Alertmanager v2 API response
AM_RESPONSE='[{"labels":{"alertname":"InstanceDown","instance":"localhost:9100","job":"node"},"status":{"state":"active","silencedBy":[],"inhibitedBy":[]},"receivers":["default"],"fingerprint":"abc123"}]'

echo "📈 Testing Prometheus API queries..."

# Test filtering firing alerts
echo "🔍 Filtering firing InstanceDown alerts:"
echo "$PROM_RESPONSE" | jq '[.data[] | select(.labels.alertname == "InstanceDown" and .state == "firing")]'

# Test counting alerts
echo "🔢 Counting alerts:"
echo "$PROM_RESPONSE" | jq '[.data[] | select(.labels.alertname == "InstanceDown" and .state == "firing")] | length'

echo ""
echo "🚨 Testing Alertmanager v2 API queries..."

# Test filtering active alerts
echo "🔍 Filtering active alerts:"
echo "$AM_RESPONSE" | jq '[.[] | select(.status.state == "active")]'

# Test counting active alerts
echo "🔢 Counting active alerts:"
echo "$AM_RESPONSE" | jq '[.[] | select(.status.state == "active")] | length'

# Test safe extraction of alert names
echo "📋 Extracting alert names safely:"
echo "$AM_RESPONSE" | jq -r '.[] | "\(.labels.alertname // "Unknown") (\(.status.state // "unknown"))"'

echo ""
echo "✅ All jq queries executed successfully!"
