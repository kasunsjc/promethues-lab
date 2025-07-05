#!/bin/bash

# Local Validation Script
# This script runs the same validations as GitHub Actions locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}🔍 Local Validation Script${NC}"
    echo "==============================="
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_info() {
    echo -e "${BLUE}🔍 $1${NC}"
}

validate_docker_compose() {
    print_info "Validating Docker Compose configuration..."
    if docker-compose config --quiet; then
        print_success "Docker Compose configuration is valid"
    else
        print_error "Docker Compose configuration is invalid"
        return 1
    fi
}

validate_prometheus_config() {
    print_info "Validating Prometheus configuration..."
    if docker run --rm -v "$(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml" \
        prom/prometheus:latest \
        promtool check config /etc/prometheus/prometheus.yml > /dev/null 2>&1; then
        print_success "Prometheus configuration is valid"
    else
        print_error "Prometheus configuration is invalid"
        return 1
    fi
}

validate_alert_rules() {
    print_info "Validating alert rules..."
    if docker run --rm -v "$(pwd)/alert_rules.yml:/etc/prometheus/alert_rules.yml" \
        prom/prometheus:latest \
        promtool check rules /etc/prometheus/alert_rules.yml > /dev/null 2>&1; then
        print_success "Alert rules are valid"
    else
        print_error "Alert rules are invalid"
        return 1
    fi
}

validate_alertmanager_config() {
    print_info "Validating Alertmanager configuration..."
    if docker run --rm -v "$(pwd)/alertmanager.yml:/etc/alertmanager/alertmanager.yml" \
        prom/alertmanager:latest \
        amtool check-config /etc/alertmanager/alertmanager.yml > /dev/null 2>&1; then
        print_success "Alertmanager configuration is valid"
    else
        print_error "Alertmanager configuration is invalid"
        return 1
    fi
}

validate_shell_scripts() {
    print_info "Validating shell script syntax..."
    local scripts=("monitoring-helper.sh" "commands.sh" "alertmanager-helper.sh" "k6-load-test.sh" "import-k6-dashboard.sh")
    local all_valid=true
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if bash -n "$script" 2>/dev/null; then
                print_success "Shell script $script syntax is valid"
            else
                print_error "Shell script $script has syntax errors"
                all_valid=false
            fi
        else
            print_warning "Shell script $script not found"
        fi
    done
    
    if [[ "$all_valid" == true ]]; then
        return 0
    else
        return 1
    fi
}

validate_python_scripts() {
    print_info "Validating Python script syntax..."
    if [[ -f "webhook_receiver.py" ]]; then
        if python3 -m py_compile webhook_receiver.py 2>/dev/null; then
            print_success "Python script syntax is valid"
        else
            print_error "Python script has syntax errors"
            return 1
        fi
    else
        print_warning "webhook_receiver.py not found"
    fi
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    local deps=("docker" "docker-compose" "python3")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" > /dev/null 2>&1; then
            print_success "$dep is installed"
        else
            print_error "$dep is not installed"
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo ""
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo "Please install the missing dependencies and try again."
        return 1
    fi
}

run_quick_validation() {
    print_header
    echo "Running quick validation (same as GitHub Actions quick-validate.yml)..."
    echo ""
    
    local failed=0
    
    check_dependencies || ((failed++))
    echo ""
    
    validate_docker_compose || ((failed++))
    echo ""
    
    validate_prometheus_config || ((failed++))
    echo ""
    
    validate_alert_rules || ((failed++))
    echo ""
    
    validate_alertmanager_config || ((failed++))
    echo ""
    
    validate_shell_scripts || ((failed++))
    echo ""
    
    validate_python_scripts || ((failed++))
    echo ""
    
    if [[ $failed -eq 0 ]]; then
        print_success "🎉 All validations passed! Your changes are ready for commit."
        return 0
    else
        print_error "❌ $failed validation(s) failed. Please fix the issues before committing."
        return 1
    fi
}

test_stack_startup() {
    print_info "Testing stack startup (this may take a few minutes)..."
    
    print_info "Starting services..."
    if docker-compose up -d; then
        print_success "Services started"
    else
        print_error "Failed to start services"
        return 1
    fi
    
    print_info "Waiting for services to be ready..."
    sleep 30
    
    # Check key services
    local services=("prometheus:9090/-/ready" "alertmanager:9093/-/ready" "grafana:3000/api/health")
    for service_check in "${services[@]}"; do
        local service_name=$(echo "$service_check" | cut -d: -f1)
        local endpoint="http://localhost:${service_check#*:}"
        
        print_info "Checking $service_name..."
        if curl -sf "$endpoint" > /dev/null 2>&1; then
            print_success "$service_name is healthy"
        else
            print_warning "$service_name is not ready (this might be normal during startup)"
        fi
    done
    
    print_info "Stopping services..."
    docker-compose down -v
    print_success "Services stopped and cleaned up"
}

show_help() {
    print_header
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  quick      - Run quick validation (default)"
    echo "  full       - Run quick validation + test stack startup"
    echo "  stack      - Only test stack startup"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                # Run quick validation"
    echo "  $0 quick          # Run quick validation"
    echo "  $0 full           # Run all validations including stack test"
    echo "  $0 stack          # Only test if stack can start"
    echo ""
}

# Main script logic
case "${1:-quick}" in
    "quick")
        run_quick_validation
        ;;
    "full")
        if run_quick_validation; then
            echo ""
            test_stack_startup
        else
            print_error "Quick validation failed. Skipping stack test."
            exit 1
        fi
        ;;
    "stack")
        test_stack_startup
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
