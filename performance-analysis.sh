#!/bin/bash

# Enhanced Performance Analysis Script for Prometheus Monitoring Stack
# This script provides comprehensive performance analysis and recommendations

set -euo pipefail

PROMETHEUS_URL="http://localhost:9090"
GRAFANA_URL="http://localhost:3000"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${SCRIPT_DIR}/reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${REPORT_DIR}/performance_analysis_${TIMESTAMP}.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure reports directory exists
mkdir -p "$REPORT_DIR"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if services are running
check_services() {
    log_info "Checking service availability..."
    
    local services=(
        "prometheus:9090"
        "grafana:3000"
        "alertmanager:9093"
        "mysql:3306"
        "nginx:8080"
        "influxdb:8086"
    )
    
    for service in "${services[@]}"; do
        local name="${service%%:*}"
        local port="${service##*:}"
        
        if curl -sf "http://localhost:${port}" > /dev/null 2>&1 || \
           curl -sf "http://localhost:${port}/api/v1/status/buildinfo" > /dev/null 2>&1 || \
           nc -z localhost "$port" 2>/dev/null; then
            log_success "$name is running on port $port"
        else
            log_error "$name is not accessible on port $port"
        fi
    done
}

# Function to analyze Prometheus metrics
analyze_prometheus_metrics() {
    log_info "Analyzing Prometheus metrics..."
    
    local queries=(
        "up"
        "rate(prometheus_tsdb_symbol_table_size_bytes[5m])"
        "prometheus_tsdb_head_series"
        "rate(prometheus_http_requests_total[5m])"
        "prometheus_config_last_reload_successful"
    )
    
    echo "## Prometheus Health Analysis" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    for query in "${queries[@]}"; do
        local result
        result=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=${query}" | jq -r '.data.result[] | "\(.metric.instance // .metric.job // "prometheus"): \(.value[1])"' 2>/dev/null || echo "No data")
        echo "**Query:** \`${query}\`" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$result" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    done
}

# Function to analyze system performance
analyze_system_performance() {
    log_info "Analyzing system performance..."
    
    echo "## System Performance Analysis" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # CPU Analysis
    local cpu_usage
    cpu_usage=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=100-(avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)" | jq -r '.data.result[] | "\(.metric.instance): \(.value[1])%"' 2>/dev/null || echo "No data")
    
    echo "### CPU Usage" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$cpu_usage" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Memory Analysis
    local memory_usage
    memory_usage=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100" | jq -r '.data.result[] | "\(.metric.instance): \(.value[1])%"' 2>/dev/null || echo "No data")
    
    echo "### Memory Usage" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$memory_usage" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Disk Usage
    local disk_usage
    disk_usage=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=(1 - (node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"})) * 100" | jq -r '.data.result[] | "\(.metric.instance): \(.value[1])%"' 2>/dev/null || echo "No data")
    
    echo "### Disk Usage" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$disk_usage" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# Function to analyze application metrics
analyze_application_metrics() {
    log_info "Analyzing application metrics..."
    
    echo "## Application Metrics Analysis" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Nginx metrics
    local nginx_requests
    nginx_requests=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=rate(nginx_http_requests_total[5m])" | jq -r '.data.result[] | "\(.metric.instance): \(.value[1]) req/s"' 2>/dev/null || echo "No data")
    
    echo "### Nginx Request Rate" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$nginx_requests" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # MySQL metrics
    local mysql_connections
    mysql_connections=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=mysql_global_status_threads_connected" | jq -r '.data.result[] | "\(.metric.instance): \(.value[1]) connections"' 2>/dev/null || echo "No data")
    
    echo "### MySQL Connections" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$mysql_connections" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# Function to analyze alerts
analyze_alerts() {
    log_info "Analyzing current alerts..."
    
    echo "## Alert Analysis" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    local active_alerts
    active_alerts=$(curl -s "${PROMETHEUS_URL}/api/v1/alerts" | jq -r '.data[] | "**\(.labels.alertname)** - \(.state) - \(.labels.severity // "unknown") - \(.annotations.summary // "No summary")"' 2>/dev/null || echo "No active alerts")
    
    echo "### Active Alerts" >> "$REPORT_FILE"
    echo "$active_alerts" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Alert trends
    local alert_history
    alert_history=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=ALERTS{alertstate=\"firing\"}" | jq -r '.data.result | length' 2>/dev/null || echo "0")
    
    echo "### Alert Statistics" >> "$REPORT_FILE"
    echo "- Currently firing alerts: $alert_history" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# Function to analyze load test results
analyze_load_test_results() {
    log_info "Analyzing load test results from InfluxDB..."
    
    echo "## Load Test Results Analysis" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Check if InfluxDB is accessible
    if ! curl -sf "http://localhost:8086/ping" > /dev/null 2>&1; then
        echo "InfluxDB not accessible - skipping load test analysis" >> "$REPORT_FILE"
        return
    fi
    
    # Get k6 measurements
    local measurements
    measurements=$(curl -s "http://localhost:8086/query?db=k6&q=SHOW%20MEASUREMENTS" | jq -r '.results[0].series[0].values[][]' 2>/dev/null || echo "No measurements found")
    
    echo "### Available Measurements" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$measurements" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Get HTTP request statistics
    local http_stats
    http_stats=$(curl -s "http://localhost:8086/query?db=k6&q=SELECT%20COUNT(value)%20FROM%20http_reqs%20WHERE%20time%20%3E%20now()%20-%201h" 2>/dev/null || echo "No recent data")
    
    echo "### Recent HTTP Requests (Last Hour)" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$http_stats" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# Function to generate recommendations
generate_recommendations() {
    log_info "Generating performance recommendations..."
    
    echo "## Performance Recommendations" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    local recommendations=()
    
    # Check high CPU usage
    local cpu_check
    cpu_check=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=100-(avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)" | jq -r '.data.result[] | .value[1]' 2>/dev/null | head -1)
    
    if [[ -n "$cpu_check" && $(echo "$cpu_check > 80" | bc -l 2>/dev/null || echo 0) -eq 1 ]]; then
        recommendations+=("🔴 **High CPU Usage**: CPU usage is above 80%. Consider scaling horizontally or optimizing application performance.")
    fi
    
    # Check memory usage
    local mem_check
    mem_check=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100" | jq -r '.data.result[] | .value[1]' 2>/dev/null | head -1)
    
    if [[ -n "$mem_check" && $(echo "$mem_check > 85" | bc -l 2>/dev/null || echo 0) -eq 1 ]]; then
        recommendations+=("🔴 **High Memory Usage**: Memory usage is above 85%. Consider increasing memory allocation or optimizing memory usage.")
    fi
    
    # Check for alerts
    local alert_count
    alert_count=$(curl -s "${PROMETHEUS_URL}/api/v1/alerts" | jq '.data | length' 2>/dev/null || echo 0)
    
    if [[ "$alert_count" -gt 0 ]]; then
        recommendations+=("🟡 **Active Alerts**: There are $alert_count active alerts. Review and address them promptly.")
    fi
    
    # Add general recommendations
    recommendations+=("✅ **Regular Monitoring**: Implement regular monitoring reviews and performance optimization cycles.")
    recommendations+=("✅ **Capacity Planning**: Use trending data to plan for future capacity needs.")
    recommendations+=("✅ **Load Testing**: Perform regular load testing to understand system limits.")
    recommendations+=("✅ **Security Monitoring**: Monitor for suspicious patterns and implement security alerts.")
    
    if [[ ${#recommendations[@]} -eq 0 ]]; then
        echo "🎉 **All systems operating normally!** No immediate recommendations." >> "$REPORT_FILE"
    else
        for rec in "${recommendations[@]}"; do
            echo "- $rec" >> "$REPORT_FILE"
        done
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Function to generate summary dashboard
generate_summary() {
    log_info "Generating performance summary..."
    
    echo "# 📊 Performance Analysis Report" > "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "**Generated:** $(date)" >> "$REPORT_FILE"
    echo "**Analysis Period:** Last 5 minutes" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## 🎯 Executive Summary" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    local summary_items=()
    
    # Service availability
    local up_services
    up_services=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=up" | jq '.data.result | length' 2>/dev/null || echo 0)
    summary_items+=("**Services Monitored:** $up_services")
    
    # Active alerts
    local active_alerts
    active_alerts=$(curl -s "${PROMETHEUS_URL}/api/v1/alerts" | jq '.data | length' 2>/dev/null || echo 0)
    summary_items+=("**Active Alerts:** $active_alerts")
    
    # Request rate
    local req_rate
    req_rate=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=sum(rate(nginx_http_requests_total[5m]))" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    summary_items+=("**Request Rate:** ${req_rate} req/s")
    
    for item in "${summary_items[@]}"; do
        echo "- $item" >> "$REPORT_FILE"
    done
    
    echo "" >> "$REPORT_FILE"
}

# Main execution
main() {
    log_info "Starting performance analysis..."
    
    generate_summary
    check_services
    analyze_prometheus_metrics
    analyze_system_performance
    analyze_application_metrics
    analyze_alerts
    analyze_load_test_results
    generate_recommendations
    
    echo "---" >> "$REPORT_FILE"
    echo "*Report generated by Enhanced Performance Analysis Script*" >> "$REPORT_FILE"
    
    log_success "Performance analysis completed!"
    log_info "Report saved to: $REPORT_FILE"
    
    # Display key findings
    echo ""
    echo "=== KEY FINDINGS ==="
    if [[ -f "$REPORT_FILE" ]]; then
        grep -E "🔴|🟡|✅" "$REPORT_FILE" || echo "No critical findings detected."
    fi
    
    echo ""
    log_info "To view the full report: cat '$REPORT_FILE'"
    log_info "To open in browser: open '$REPORT_FILE' (if HTML viewer available)"
}

# Command line options
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Enhanced Performance Analysis Script"
        echo ""
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  help, -h, --help    Show this help message"
        echo "  check               Only check service availability"
        echo "  analyze             Run full analysis (default)"
        echo ""
        echo "Reports are saved to: $REPORT_DIR"
        exit 0
        ;;
    "check")
        check_services
        exit 0
        ;;
    "analyze"|"")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        log_info "Use '$0 help' for usage information"
        exit 1
        ;;
esac
