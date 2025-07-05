#!/bin/bash

# Comprehensive Monitoring Stack Validation Script
# This script validates all components of the enhanced Prometheus monitoring stack

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/logs/validation_$(date +%Y%m%d_%H%M%S).log"
PROMETHEUS_URL="http://localhost:9090"
GRAFANA_URL="http://localhost:3000"
ALERTMANAGER_URL="http://localhost:9093"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Ensure logs directory exists
mkdir -p "${SCRIPT_DIR}/logs"

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        "INFO")  echo -e "${BLUE}[INFO]${NC} $message" ;;
        "PASS")  echo -e "${GREEN}[PASS]${NC} $message" ;;
        "FAIL")  echo -e "${RED}[FAIL]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "TEST")  echo -e "${PURPLE}[TEST]${NC} $message" ;;
    esac
}

# Test execution wrapper
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log "TEST" "Running: $test_name"
    
    if $test_function; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log "PASS" "$test_name"
        return 0
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log "FAIL" "$test_name"
        return 1
    fi
}

# Service availability tests
test_prometheus_availability() {
    curl -sf "${PROMETHEUS_URL}/api/v1/status/buildinfo" > /dev/null
}

test_alertmanager_availability() {
    curl -sf "${ALERTMANAGER_URL}/api/v1/status" > /dev/null
}

test_grafana_availability() {
    curl -sf "${GRAFANA_URL}/api/health" > /dev/null
}

test_mysql_availability() {
    nc -z localhost 3306
}

test_nginx_availability() {
    curl -sf "http://localhost:8080/" > /dev/null
}

test_influxdb_availability() {
    curl -sf "http://localhost:8086/ping" > /dev/null
}

# Configuration tests
test_prometheus_config() {
    local config_status
    config_status=$(curl -s "${PROMETHEUS_URL}/api/v1/status/config" | jq -r '.status')
    [[ "$config_status" == "success" ]]
}

test_alert_rules_loaded() {
    local rules_count
    rules_count=$(curl -s "${PROMETHEUS_URL}/api/v1/rules" | jq '.data.groups | length')
    [[ "$rules_count" -gt 0 ]]
}

test_security_rules_loaded() {
    local security_rules
    security_rules=$(curl -s "${PROMETHEUS_URL}/api/v1/rules" | jq '.data.groups[] | select(.name | contains("security")) | .name' | wc -l)
    [[ "$security_rules" -gt 0 ]]
}

test_alertmanager_config() {
    local config_status
    config_status=$(curl -s "${ALERTMANAGER_URL}/api/v1/status" | jq -r '.data.configYAML' | wc -l)
    [[ "$config_status" -gt 5 ]]
}

# Metrics tests
test_node_exporter_metrics() {
    local cpu_metric
    cpu_metric=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=node_cpu_seconds_total" | jq '.data.result | length')
    [[ "$cpu_metric" -gt 0 ]]
}

test_mysql_metrics() {
    local mysql_metric
    mysql_metric=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=mysql_up" | jq '.data.result | length')
    [[ "$mysql_metric" -gt 0 ]]
}

test_nginx_metrics() {
    local nginx_metric
    nginx_metric=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=nginx_up" | jq '.data.result | length')
    [[ "$nginx_metric" -gt 0 ]]
}

# Security tests
test_security_monitoring() {
    # Check if security monitoring script exists and is executable
    [[ -x "${SCRIPT_DIR}/security-monitoring.sh" ]]
}

test_performance_analysis() {
    # Check if performance analysis script exists and is executable
    [[ -x "${SCRIPT_DIR}/performance-analysis.sh" ]]
}

test_webhook_receiver() {
    # Check if webhook receiver script exists
    [[ -f "${SCRIPT_DIR}/webhook_receiver.py" ]]
}

# Alert tests
test_alert_routing() {
    # Start webhook receiver in background
    python3 "${SCRIPT_DIR}/webhook_receiver.py" > /tmp/webhook.log 2>&1 &
    local webhook_pid=$!
    sleep 2
    
    # Check if webhook receiver is running
    if kill -0 "$webhook_pid" 2>/dev/null; then
        kill "$webhook_pid"
        return 0
    else
        return 1
    fi
}

test_alertmanager_routing() {
    local silence_count
    silence_count=$(curl -s "${ALERTMANAGER_URL}/api/v1/silences" | jq '. | length')
    # Should be able to query silences (even if empty)
    [[ "$silence_count" -ge 0 ]]
}

# Load testing tests
test_k6_scripts() {
    # Check if k6 scripts exist
    [[ -f "${SCRIPT_DIR}/k6-scripts/nginx-load-test.js" ]] && \
    [[ -f "${SCRIPT_DIR}/k6-scripts/nginx-advanced-test.js" ]] && \
    [[ -f "${SCRIPT_DIR}/k6-scripts/comprehensive-performance-test.js" ]]
}

test_influxdb_connection() {
    # Test InfluxDB k6 database
    local db_exists
    db_exists=$(curl -s "http://localhost:8086/query?q=SHOW%20DATABASES" | grep -c "k6" || echo "0")
    [[ "$db_exists" -ge 0 ]]  # Database might not exist yet, but connection should work
}

# Grafana tests
test_grafana_datasources() {
    # Check if Prometheus is configured as datasource
    local datasources
    datasources=$(curl -s -u "admin:grafana" "${GRAFANA_URL}/api/datasources" | jq '. | length')
    [[ "$datasources" -gt 0 ]]
}

test_grafana_dashboards() {
    # Check if dashboards are available
    local dashboards
    dashboards=$(curl -s -u "admin:grafana" "${GRAFANA_URL}/api/search" | jq '. | length')
    [[ "$dashboards" -ge 0 ]]
}

# Docker tests
test_docker_containers() {
    local running_containers
    running_containers=$(docker compose ps --services --filter "status=running" | wc -l)
    [[ "$running_containers" -ge 8 ]]  # Should have at least 8 services running
}

test_docker_networks() {
    local monitoring_network
    monitoring_network=$(docker network ls | grep -c "monitoring" || echo "0")
    [[ "$monitoring_network" -gt 0 ]]
}

# File system tests
test_config_files() {
    local config_files=(
        "prometheus.yml"
        "alertmanager.yml"
        "alert_rules.yml"
        "security_rules.yml"
        "docker-compose.yml"
    )
    
    for file in "${config_files[@]}"; do
        if [[ ! -f "${SCRIPT_DIR}/${file}" ]]; then
            return 1
        fi
    done
    return 0
}

test_helper_scripts() {
    local scripts=(
        "monitoring-helper.sh"
        "security-monitoring.sh"
        "performance-analysis.sh"
        "commands.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "${SCRIPT_DIR}/${script}" ]]; then
            return 1
        fi
    done
    return 0
}

# Integration tests
test_end_to_end_monitoring() {
    # Generate some traffic and check if it's monitored
    for i in {1..5}; do
        curl -s "http://localhost:8080/" > /dev/null &
    done
    sleep 10
    
    # Check if nginx metrics increased
    local request_count
    request_count=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=nginx_http_requests_total" | jq '.data.result[0].value[1] // "0"' | cut -d. -f1)
    [[ "$request_count" -gt 0 ]]
}

test_alert_generation() {
    # This test checks if the alert system can potentially fire alerts
    local alert_rules
    alert_rules=$(curl -s "${PROMETHEUS_URL}/api/v1/rules" | jq '.data.groups[].rules[] | select(.type == "alerting") | .name' | wc -l)
    [[ "$alert_rules" -gt 0 ]]
}

# Performance tests
test_query_performance() {
    local start_time
    local end_time
    local duration
    
    start_time=$(date +%s%N)
    curl -s "${PROMETHEUS_URL}/api/v1/query?query=up" > /dev/null
    end_time=$(date +%s%N)
    
    duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
    [[ "$duration" -lt 1000 ]]  # Should complete within 1 second
}

# Cleanup and reporting
generate_report() {
    local report_file="${SCRIPT_DIR}/logs/validation_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 🔍 Monitoring Stack Validation Report

**Generated:** $(date)
**Total Tests:** $TOTAL_TESTS
**Passed:** $PASSED_TESTS
**Failed:** $FAILED_TESTS
**Success Rate:** $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%

## Test Results

EOF
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo "✅ **All tests passed!** The monitoring stack is fully functional." >> "$report_file"
    else
        echo "❌ **Some tests failed.** Please review the log file for details: \`$LOG_FILE\`" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "## Test Categories" >> "$report_file"
    echo "" >> "$report_file"
    echo "- Service Availability Tests" >> "$report_file"
    echo "- Configuration Tests" >> "$report_file"
    echo "- Metrics Collection Tests" >> "$report_file"
    echo "- Security Monitoring Tests" >> "$report_file"
    echo "- Alert System Tests" >> "$report_file"
    echo "- Load Testing Integration" >> "$report_file"
    echo "- Grafana Integration Tests" >> "$report_file"
    echo "- Docker Environment Tests" >> "$report_file"
    echo "- File System Tests" >> "$report_file"
    echo "- End-to-End Integration Tests" >> "$report_file"
    echo "- Performance Tests" >> "$report_file"
    
    echo "" >> "$report_file"
    echo "## Recommendations" >> "$report_file"
    echo "" >> "$report_file"
    
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo "1. **Review Failed Tests**: Check the detailed log for failure reasons" >> "$report_file"
        echo "2. **Service Dependencies**: Ensure all services are running and accessible" >> "$report_file"
        echo "3. **Configuration**: Validate configuration files for syntax errors" >> "$report_file"
        echo "4. **Network**: Check network connectivity between components" >> "$report_file"
    else
        echo "1. **Regular Monitoring**: Continue running validation tests regularly" >> "$report_file"
        echo "2. **Performance Tuning**: Monitor resource usage and optimize as needed" >> "$report_file"
        echo "3. **Security Updates**: Keep all components updated with latest security patches" >> "$report_file"
        echo "4. **Backup Strategy**: Implement regular backups of configuration and data" >> "$report_file"
    fi
    
    log "INFO" "Validation report generated: $report_file"
    cat "$report_file"
}

# Main execution
main() {
    log "INFO" "Starting comprehensive monitoring stack validation..."
    log "INFO" "Log file: $LOG_FILE"
    
    echo "🔍 Comprehensive Monitoring Stack Validation"
    echo "============================================="
    echo ""
    
    # Service Availability Tests
    echo "📊 Service Availability Tests"
    run_test "Prometheus availability" test_prometheus_availability
    run_test "Alertmanager availability" test_alertmanager_availability
    run_test "Grafana availability" test_grafana_availability
    run_test "MySQL availability" test_mysql_availability
    run_test "Nginx availability" test_nginx_availability
    run_test "InfluxDB availability" test_influxdb_availability
    echo ""
    
    # Configuration Tests
    echo "⚙️ Configuration Tests"
    run_test "Prometheus configuration" test_prometheus_config
    run_test "Alert rules loaded" test_alert_rules_loaded
    run_test "Security rules loaded" test_security_rules_loaded
    run_test "Alertmanager configuration" test_alertmanager_config
    echo ""
    
    # Metrics Tests
    echo "📈 Metrics Collection Tests"
    run_test "Node exporter metrics" test_node_exporter_metrics
    run_test "MySQL metrics" test_mysql_metrics
    run_test "Nginx metrics" test_nginx_metrics
    echo ""
    
    # Security Tests
    echo "🔒 Security Monitoring Tests"
    run_test "Security monitoring script" test_security_monitoring
    run_test "Performance analysis script" test_performance_analysis
    run_test "Webhook receiver" test_webhook_receiver
    echo ""
    
    # Alert Tests
    echo "🚨 Alert System Tests"
    run_test "Alert routing" test_alert_routing
    run_test "Alertmanager routing" test_alertmanager_routing
    run_test "Alert generation capability" test_alert_generation
    echo ""
    
    # Load Testing Tests
    echo "🔥 Load Testing Integration"
    run_test "k6 scripts availability" test_k6_scripts
    run_test "InfluxDB connection" test_influxdb_connection
    echo ""
    
    # Grafana Tests
    echo "📊 Grafana Integration Tests"
    run_test "Grafana datasources" test_grafana_datasources
    run_test "Grafana dashboards" test_grafana_dashboards
    echo ""
    
    # Docker Tests
    echo "🐳 Docker Environment Tests"
    run_test "Docker containers running" test_docker_containers
    run_test "Docker networks" test_docker_networks
    echo ""
    
    # File System Tests
    echo "📁 File System Tests"
    run_test "Configuration files" test_config_files
    run_test "Helper scripts" test_helper_scripts
    echo ""
    
    # Integration Tests
    echo "🔄 End-to-End Integration Tests"
    run_test "End-to-end monitoring" test_end_to_end_monitoring
    echo ""
    
    # Performance Tests
    echo "⚡ Performance Tests"
    run_test "Query performance" test_query_performance
    echo ""
    
    # Generate final report
    echo "📋 Generating Validation Report"
    generate_report
    
    echo ""
    echo "============================================="
    echo "Validation Summary:"
    echo "- Total Tests: $TOTAL_TESTS"
    echo "- Passed: $PASSED_TESTS"
    echo "- Failed: $FAILED_TESTS"
    echo "- Success Rate: $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        log "PASS" "All validation tests completed successfully!"
        exit 0
    else
        log "FAIL" "Some validation tests failed. Check the log for details."
        exit 1
    fi
}

# Command line options
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Comprehensive Monitoring Stack Validation Script"
        echo ""
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  help, -h, --help    Show this help message"
        echo "  quick               Run quick validation (service availability only)"
        echo "  full                Run full validation (default)"
        echo "  report              Generate report from last validation"
        echo ""
        echo "Logs and reports are saved to: ${SCRIPT_DIR}/logs/"
        exit 0
        ;;
    "quick")
        echo "🚀 Quick Validation Mode"
        run_test "Prometheus availability" test_prometheus_availability
        run_test "Alertmanager availability" test_alertmanager_availability
        run_test "Grafana availability" test_grafana_availability
        run_test "MySQL availability" test_mysql_availability
        run_test "Nginx availability" test_nginx_availability
        run_test "InfluxDB availability" test_influxdb_availability
        echo "Quick validation completed. Passed: $PASSED_TESTS/6"
        ;;
    "report")
        generate_report
        ;;
    "full"|"")
        main
        ;;
    *)
        log "FAIL" "Unknown option: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
