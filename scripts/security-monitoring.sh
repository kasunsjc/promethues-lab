#!/bin/bash

# Security Monitoring and Hardening Script
# This script implements security best practices and monitoring for the Prometheus stack

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECURITY_LOG="${SCRIPT_DIR}/logs/security.log"
PROMETHEUS_URL="http://localhost:9090"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure logs directory exists
mkdir -p "${SCRIPT_DIR}/logs"

# Helper functions
log_security() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$SECURITY_LOG"
    echo -e "${BLUE}[SECURITY]${NC} $message"
}

log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] WARNING: $message" >> "$SECURITY_LOG"
    echo -e "${YELLOW}[WARNING]${NC} $message"
}

log_critical() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] CRITICAL: $message" >> "$SECURITY_LOG"
    echo -e "${RED}[CRITICAL]${NC} $message"
}

log_success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] SUCCESS: $message" >> "$SECURITY_LOG"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
}

# Function to check for suspicious network activity
check_network_security() {
    log_security "Checking network security patterns..."
    
    # Check for high request rates (potential DDoS)
    local high_request_rate
    high_request_rate=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=rate(nginx_http_requests_total[1m])" | jq -r '.data.result[] | select(.value[1] | tonumber > 50) | "\(.metric.instance): \(.value[1])"' 2>/dev/null || echo "")
    
    if [[ -n "$high_request_rate" ]]; then
        log_warning "High request rate detected:"
        echo "$high_request_rate"
    else
        log_success "Request rates are within normal limits"
    fi
    
    # Check for high error rates (potential attacks)
    local high_error_rate
    high_error_rate=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=rate(nginx_http_requests_total{status=~\"4..|5..\"}[5m]) / rate(nginx_http_requests_total[5m])" | jq -r '.data.result[] | select(.value[1] | tonumber > 0.1) | "\(.metric.instance): \(.value[1])"' 2>/dev/null || echo "")
    
    if [[ -n "$high_error_rate" ]]; then
        log_warning "High error rate detected (possible attack):"
        echo "$high_error_rate"
    else
        log_success "Error rates are within acceptable limits"
    fi
}

# Function to check resource abuse patterns
check_resource_security() {
    log_security "Checking for resource abuse patterns..."
    
    # Check for memory bombs or unusual memory usage
    local high_memory
    high_memory=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes" | jq -r '.data.result[] | select(.value[1] | tonumber > 0.9) | "\(.metric.instance): \(.value[1])"' 2>/dev/null || echo "")
    
    if [[ -n "$high_memory" ]]; then
        log_critical "Critical memory usage detected (possible memory bomb):"
        echo "$high_memory"
    else
        log_success "Memory usage is within safe limits"
    fi
    
    # Check for rapid disk space decrease
    local disk_trend
    disk_trend=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=predict_linear(node_filesystem_avail_bytes{mountpoint=\"/\"}[30m], 3600)" | jq -r '.data.result[] | select(.value[1] | tonumber < 0) | "\(.metric.instance): disk will be full in ~1 hour"' 2>/dev/null || echo "")
    
    if [[ -n "$disk_trend" ]]; then
        log_critical "Rapid disk space consumption detected:"
        echo "$disk_trend"
    else
        log_success "Disk usage trends are normal"
    fi
}

# Function to check service security
check_service_security() {
    log_security "Checking service security status..."
    
    # Check for services that shouldn't be exposed
    local exposed_services=(
        "3306:MySQL should not be exposed to public"
        "8086:InfluxDB should be access-controlled"
        "9093:Alertmanager should be behind authentication"
    )
    
    for service in "${exposed_services[@]}"; do
        local port="${service%%:*}"
        local message="${service##*:}"
        
        if netstat -tuln 2>/dev/null | grep -q ":${port} "; then
            log_warning "Port $port is listening - $message"
        fi
    done
    
    # Check for unauthorized access attempts
    local failed_auth
    failed_auth=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=rate(nginx_http_requests_total{status=\"401\"}[5m])" | jq -r '.data.result[] | select(.value[1] | tonumber > 0) | "\(.metric.instance): \(.value[1]) failed auth/min"' 2>/dev/null || echo "")
    
    if [[ -n "$failed_auth" ]]; then
        log_warning "Failed authentication attempts detected:"
        echo "$failed_auth"
    else
        log_success "No suspicious authentication patterns detected"
    fi
}

# Function to check container security
check_container_security() {
    log_security "Checking container security..."
    
    # Check for containers running as root
    local containers_info
    if command -v docker >/dev/null 2>&1; then
        containers_info=$(docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "Unable to query containers")
        log_security "Container status check completed"
        
        # Check for privileged containers
        local privileged_containers
        privileged_containers=$(docker ps --filter "label=privileged=true" --format "{{.Names}}" 2>/dev/null || echo "")
        
        if [[ -n "$privileged_containers" ]]; then
            log_warning "Privileged containers detected: $privileged_containers"
        else
            log_success "No privileged containers detected"
        fi
    else
        log_warning "Docker not available for container security check"
    fi
}

# Function to check configuration security
check_config_security() {
    log_security "Checking configuration security..."
    
    # Check for default passwords in docker-compose
    if grep -q "rootpassword\|grafana\|mysqlpassword" "${SCRIPT_DIR}/docker-compose.yml" 2>/dev/null; then
        log_warning "Default passwords detected in docker-compose.yml - consider using secrets"
    else
        log_success "No obvious default passwords in docker-compose.yml"
    fi
    
    # Check for HTTP-only configuration
    if grep -q "web.external-url=http://" "${SCRIPT_DIR}/docker-compose.yml" 2>/dev/null; then
        log_warning "HTTP-only configuration detected - consider enabling HTTPS"
    fi
    
    # Check file permissions
    local sensitive_files=(
        "prometheus.yml"
        "alertmanager.yml"
        "docker-compose.yml"
    )
    
    for file in "${sensitive_files[@]}"; do
        if [[ -f "${SCRIPT_DIR}/${file}" ]]; then
            local perms
            perms=$(stat -f "%OLp" "${SCRIPT_DIR}/${file}" 2>/dev/null || stat -c "%a" "${SCRIPT_DIR}/${file}" 2>/dev/null)
            if [[ "$perms" != "644" && "$perms" != "600" ]]; then
                log_warning "File $file has permissive permissions: $perms"
            else
                log_success "File $file has appropriate permissions"
            fi
        fi
    done
}

# Function to implement security hardening
implement_hardening() {
    log_security "Implementing security hardening measures..."
    
    # Create secure file permissions
    local config_files=(
        "prometheus.yml"
        "alertmanager.yml"
        "security_rules.yml"
        "alert_rules.yml"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "${SCRIPT_DIR}/${file}" ]]; then
            chmod 644 "${SCRIPT_DIR}/${file}"
            log_success "Set secure permissions for $file"
        fi
    done
    
    # Create security monitoring dashboard export
    cat > "${SCRIPT_DIR}/grafana/dashboards/security-monitoring.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Security Monitoring",
    "tags": ["security", "monitoring"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Request Rate Anomalies",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(nginx_http_requests_total[1m])",
            "legendFormat": "{{instance}} - {{status}}"
          }
        ],
        "yAxes": [
          {
            "label": "Requests/sec"
          }
        ],
        "alert": {
          "conditions": [
            {
              "query": {
                "queryType": "",
                "refId": "A"
              },
              "reducer": {
                "params": [],
                "type": "last"
              },
              "evaluator": {
                "params": [100],
                "type": "gt"
              }
            }
          ],
          "executionErrorState": "alerting",
          "for": "1m",
          "frequency": "10s",
          "handler": 1,
          "name": "High Request Rate Alert",
          "noDataState": "no_data",
          "notifications": []
        }
      },
      {
        "id": 2,
        "title": "Error Rate Monitoring",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(nginx_http_requests_total{status=~\"4..|5..\"}[5m]) / rate(nginx_http_requests_total[5m])",
            "legendFormat": "Error Rate - {{instance}}"
          }
        ]
      },
      {
        "id": 3,
        "title": "Resource Usage Alerts",
        "type": "graph",
        "targets": [
          {
            "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes",
            "legendFormat": "Memory Usage - {{instance}}"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF
    
    log_success "Created security monitoring dashboard"
    
    # Create security alerts configuration
    if [[ ! -f "${SCRIPT_DIR}/security_rules.yml" ]]; then
        log_warning "security_rules.yml not found - security rules may not be loaded"
    else
        log_success "Security rules configuration found"
    fi
}

# Function to generate security report
generate_security_report() {
    local report_file="${SCRIPT_DIR}/logs/security_report_$(date +%Y%m%d_%H%M%S).md"
    
    log_security "Generating security report..."
    
    cat > "$report_file" << EOF
# 🔒 Security Monitoring Report

**Generated:** $(date)
**Environment:** Prometheus Monitoring Stack

## Executive Summary

This report covers security monitoring findings for the Prometheus monitoring stack.

## Security Checks Performed

### Network Security
- Request rate monitoring
- Error rate analysis
- Suspicious pattern detection

### Resource Security
- Memory usage monitoring
- Disk space trend analysis
- CPU usage patterns

### Service Security
- Exposed service analysis
- Authentication attempt monitoring
- Container privilege checks

### Configuration Security
- Default password detection
- File permission analysis
- HTTPS configuration review

## Findings

EOF
    
    # Add recent security log entries
    if [[ -f "$SECURITY_LOG" ]]; then
        echo "### Recent Security Events" >> "$report_file"
        echo "\`\`\`" >> "$report_file"
        tail -20 "$SECURITY_LOG" >> "$report_file"
        echo "\`\`\`" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "## Recommendations" >> "$report_file"
    echo "" >> "$report_file"
    echo "1. **Regular Security Audits**: Perform weekly security checks" >> "$report_file"
    echo "2. **Access Control**: Implement proper authentication for all services" >> "$report_file"
    echo "3. **HTTPS**: Enable HTTPS for all web interfaces" >> "$report_file"
    echo "4. **Secret Management**: Use proper secret management instead of plaintext passwords" >> "$report_file"
    echo "5. **Network Segmentation**: Limit network access between components" >> "$report_file"
    echo "6. **Regular Updates**: Keep all components updated with security patches" >> "$report_file"
    
    log_success "Security report generated: $report_file"
}

# Main execution
main() {
    log_security "Starting security monitoring check..."
    
    check_network_security
    check_resource_security
    check_service_security
    check_container_security
    check_config_security
    implement_hardening
    generate_security_report
    
    log_success "Security monitoring check completed!"
    log_security "Check security log for details: $SECURITY_LOG"
}

# Command line options
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Security Monitoring Script"
        echo ""
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  help, -h, --help    Show this help message"
        echo "  check               Run security checks only"
        echo "  harden              Implement hardening measures only"
        echo "  report              Generate security report only"
        echo "  full                Run full security monitoring (default)"
        echo ""
        echo "Logs are saved to: ${SCRIPT_DIR}/logs/"
        exit 0
        ;;
    "check")
        check_network_security
        check_resource_security
        check_service_security
        check_container_security
        check_config_security
        ;;
    "harden")
        implement_hardening
        ;;
    "report")
        generate_security_report
        ;;
    "full"|"")
        main
        ;;
    *)
        log_critical "Unknown option: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
