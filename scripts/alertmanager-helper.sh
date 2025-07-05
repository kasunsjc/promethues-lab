#!/bin/bash

# Alertmanager Helper Script
# This script provides useful commands for managing Alertmanager

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}🚨 Alertmanager Helper${NC}"
    echo "=================================="
}

show_help() {
    print_header
    echo "Available commands:"
    echo ""
    echo -e "${GREEN}status${NC}          - Show Alertmanager status"
    echo -e "${GREEN}alerts${NC}          - Show active alerts"
    echo -e "${GREEN}silences${NC}        - Show active silences"
    echo -e "${GREEN}test-webhook${NC}    - Start webhook receiver for testing"
    echo -e "${GREEN}test-alerts${NC}     - Trigger test alerts by stopping services"
    echo -e "${GREEN}validate-config${NC} - Validate Alertmanager configuration"
    echo -e "${GREEN}reload-config${NC}   - Reload Alertmanager configuration"
    echo -e "${GREEN}logs${NC}            - Show Alertmanager logs"
    echo -e "${GREEN}ui${NC}              - Open Alertmanager UI in browser"
    echo -e "${GREEN}help${NC}            - Show this help message"
    echo ""
}

check_alertmanager() {
    if ! docker-compose ps alertmanager | grep -q "Up"; then
        echo -e "${RED}❌ Alertmanager is not running${NC}"
        echo "Start it with: docker-compose up -d alertmanager"
        exit 1
    fi
}

show_status() {
    print_header
    echo "Alertmanager Status:"
    docker-compose ps alertmanager
    echo ""
    echo "Checking connectivity..."
    if curl -s http://localhost:9093/-/healthy > /dev/null; then
        echo -e "${GREEN}✅ Alertmanager is healthy${NC}"
    else
        echo -e "${RED}❌ Alertmanager is not responding${NC}"
    fi
}

show_alerts() {
    print_header
    check_alertmanager
    echo "Active Alerts:"
    echo ""
    curl -s http://localhost:9093/api/v1/alerts | jq '.data[] | {alertname: .labels.alertname, instance: .labels.instance, status: .status.state, startsAt: .startsAt}' || echo "No active alerts or jq not installed"
}

show_silences() {
    print_header
    check_alertmanager
    echo "Active Silences:"
    echo ""
    curl -s http://localhost:9093/api/v1/silences | jq '.data[] | {id: .id, status: .status.state, matchers: .matchers, comment: .comment}' || echo "No active silences or jq not installed"
}

start_webhook() {
    print_header
    echo "Starting webhook receiver for testing alerts..."
    echo "Press Ctrl+C to stop"
    echo ""
    if [ -f "./webhook_receiver.py" ]; then
        python3 ./webhook_receiver.py
    else
        echo -e "${RED}❌ webhook_receiver.py not found${NC}"
        echo "Make sure you're in the correct directory"
    fi
}

test_alerts() {
    print_header
    echo "🔥 Triggering test alerts by stopping services..."
    echo ""
    
    echo "Stopping MySQL to trigger MySQLDown alert..."
    docker-compose stop mysql
    echo -e "${YELLOW}⏱️  Waiting 2 minutes for alert to trigger...${NC}"
    sleep 120
    
    echo ""
    echo "Checking for alerts..."
    show_alerts
    
    echo ""
    echo -e "${BLUE}💡 To restore service: docker-compose start mysql${NC}"
}

validate_config() {
    print_header
    echo "Validating Alertmanager configuration..."
    
    if [ -f "./alertmanager.yml" ]; then
        docker run --rm -v "$(pwd)/alertmanager.yml:/etc/alertmanager/alertmanager.yml" prom/alertmanager:latest amtool check-config /etc/alertmanager/alertmanager.yml
    else
        echo -e "${RED}❌ alertmanager.yml not found${NC}"
    fi
}

reload_config() {
    print_header
    check_alertmanager
    echo "Reloading Alertmanager configuration..."
    
    if curl -X POST http://localhost:9093/-/reload; then
        echo -e "${GREEN}✅ Configuration reloaded successfully${NC}"
    else
        echo -e "${RED}❌ Failed to reload configuration${NC}"
    fi
}

show_logs() {
    print_header
    echo "Alertmanager Logs (last 50 lines):"
    echo ""
    docker-compose logs --tail=50 alertmanager
}

open_ui() {
    print_header
    echo "Opening Alertmanager UI in browser..."
    
    # Try different commands based on OS
    if command -v open > /dev/null; then
        open http://localhost:9093  # macOS
    elif command -v xdg-open > /dev/null; then
        xdg-open http://localhost:9093  # Linux
    elif command -v start > /dev/null; then
        start http://localhost:9093  # Windows
    else
        echo "Please open http://localhost:9093 in your browser"
    fi
}

# Main script logic
case "${1:-help}" in
    "status")
        show_status
        ;;
    "alerts")
        show_alerts
        ;;
    "silences")
        show_silences
        ;;
    "test-webhook")
        start_webhook
        ;;
    "test-alerts")
        test_alerts
        ;;
    "validate-config")
        validate_config
        ;;
    "reload-config")
        reload_config
        ;;
    "logs")
        show_logs
        ;;
    "ui")
        open_ui
        ;;
    "help"|*)
        show_help
        ;;
esac
