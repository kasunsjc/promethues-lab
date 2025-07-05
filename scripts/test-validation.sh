#!/bin/bash

# Simple test to validate the promtool command works

set -e

echo "🔍 Testing promtool validation..."

# Test 1: Validate just prometheus.yml without rule files first
echo "Testing prometheus.yml validation without rule files..."
docker run --rm --entrypoint="" \
  -v "$(pwd)/prometheus.yml:/tmp/prometheus.yml:ro" \
  prom/prometheus:latest \
  promtool check config /tmp/prometheus.yml || echo "Failed without rules (expected)"

echo ""

# Test 2: Copy files to a tmp directory and validate
echo "Creating temporary directory structure..."
mkdir -p /tmp/prometheus-test
cp prometheus.yml /tmp/prometheus-test/
cp alert_rules.yml /tmp/prometheus-test/
cp security_rules.yml /tmp/prometheus-test/

echo "Testing with complete directory structure..."
docker run --rm --entrypoint="" \
  -v "/tmp/prometheus-test:/etc/prometheus:ro" \
  prom/prometheus:latest \
  promtool check config /etc/prometheus/prometheus.yml

echo "✅ Validation successful!"

# Cleanup
rm -rf /tmp/prometheus-test
