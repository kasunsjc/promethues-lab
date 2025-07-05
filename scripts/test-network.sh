#!/bin/bash

# Test script to determine the correct Docker network name
# This helps debug the k6 network connectivity issues

echo "🔍 Determining Docker network name for k6 tests..."

# Start a minimal stack to check network name
echo "🚀 Starting minimal services..."
docker compose up -d nginx influxdb

sleep 10

echo "📊 Listing Docker networks:"
docker network ls | grep prometheus

echo ""
echo "🔍 Checking network details:"
NETWORK_NAME=$(docker network ls --format "table {{.Name}}" | grep prometheus | head -1)

if [[ -n "$NETWORK_NAME" ]]; then
    echo "✅ Found network: $NETWORK_NAME"
    echo ""
    echo "🧪 Testing k6 connectivity..."
    
    # Test k6 with the found network
    docker run --rm --network "$NETWORK_NAME" \
        -e K6_OUT=influxdb=http://influxdb:8086/k6 \
        grafana/k6:latest run - <<'EOF'
import http from 'k6/http';
export default function () {
  // Test if we can reach nginx through the network
  let response = http.get('http://nginx:80');
  console.log('nginx response status:', response.status);
}
export let options = {
  vus: 1,
  iterations: 1,
};
EOF

    echo "✅ k6 network test completed"
else
    echo "❌ No prometheus network found"
fi

echo ""
echo "🛑 Cleaning up..."
docker compose down

echo "✅ Network test completed"
