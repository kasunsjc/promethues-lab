#!/bin/bash
# Script to validate recording rules and show examples

echo "🔍 Validating Recording Rules Configuration..."

# Check if recording rules file exists
if [[ ! -f "config/recording_rules.yml" ]]; then
    echo "❌ Recording rules file not found"
    exit 1
fi

# Validate YAML syntax
if ! yq eval . config/recording_rules.yml > /dev/null 2>&1; then
    echo "❌ Invalid YAML syntax in recording_rules.yml"
    exit 1
else
    echo "✅ YAML syntax is valid"
fi

# Validate Prometheus rules syntax using Docker
echo "🔍 Validating Prometheus recording rules syntax..."
if docker run --rm \
    --entrypoint="" \
    -v "$(pwd)/config:/etc/prometheus:ro" \
    prom/prometheus:latest \
    promtool check rules /etc/prometheus/recording_rules.yml; then
    echo "✅ Recording rules syntax is valid"
else
    echo "❌ Recording rules syntax validation failed"
    exit 1
fi

echo ""
echo "📊 Recording Rules Summary:"
echo "=========================="

# Count rules by group
echo "📋 Rule Groups:"
yq eval '.groups[] | .name + " (" + (.rules | length | tostring) + " rules)"' config/recording_rules.yml

echo ""
echo "📋 Sample Recording Rules:"
echo ""

echo "🖥️  System Metrics:"
echo "   - node:cpu_utilization:rate5m"
echo "   - node:memory_utilization:percent" 
echo "   - node:disk_utilization:percent"
echo ""

echo "🗄️  MySQL Metrics:"
echo "   - mysql:connection_utilization:percent"
echo "   - mysql:queries:rate5m"
echo "   - mysql:slow_queries:rate5m"
echo ""

echo "🌐 Nginx Metrics:"
echo "   - nginx:requests:rate5m"
echo "   - nginx:error_rate:percent"
echo "   - nginx:server_errors:rate5m"
echo ""

echo "📈 Prometheus Metrics:"
echo "   - prometheus:samples_ingested:rate5m"
echo "   - prometheus:query_duration:p95"
echo "   - prometheus:targets_up:count"
echo ""

echo "🎯 Overview Metrics:"
echo "   - stack:health_score:percent"
echo "   - stack:critical_services_down:count"
echo "   - sla:availability_24h:percent"

echo ""
echo "💡 Usage Examples:"
echo "=================="
echo ""
echo "# Query CPU utilization across all nodes:"
echo "node:cpu_utilization:rate5m"
echo ""
echo "# Query MySQL connection usage:"
echo "mysql:connection_utilization:percent"
echo ""
echo "# Query overall stack health:"
echo "stack:health_score:percent"
echo ""
echo "# Query service availability:"
echo "sla:availability_24h:percent{service=\"mysql\"}"
echo ""

echo "✅ Recording rules validation completed!"

if docker compose ps prometheus | grep -q "Up"; then
    echo ""
    echo "🔄 Prometheus is running. Recording rules will be available after reload."
    echo "   You can reload with: docker compose restart prometheus"
    echo "   Or trigger reload: curl -X POST http://localhost:9090/-/reload"
else
    echo ""
    echo "ℹ️  Start the monitoring stack to begin using recording rules:"
    echo "   docker compose up -d"
fi
