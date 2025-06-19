#!/bin/bash
# 🔭 Prometheus Monitoring Stack - k6 Load Testing Script 🚀

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display header
echo -e "${BOLD}${BLUE}=== 🔭 k6 Load Testing for Nginx 🚀 ===${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo -e "${YELLOW}⚠️ Docker is not running. Please start Docker first.${NC}"
  exit 1
fi

# Function to show the menu
show_menu() {
  echo -e "\n${BOLD}Choose a load test to run:${NC}"
  echo -e "  ${GREEN}1.${NC} 🔄 Basic load test (default Nginx endpoint)"
  echo -e "  ${GREEN}2.${NC} 🔥 Advanced load test (multiple endpoints, spike test)"
  echo -e "  ${GREEN}3.${NC} 📊 View results in Grafana"
  echo -e "  ${GREEN}0.${NC} 👋 Exit"
}

# Function to run the basic load test
run_basic_test() {
  echo -e "\n${YELLOW}🚀 Running basic load test...${NC}"
  docker-compose run --rm k6 run /scripts/nginx-load-test.js
}

# Function to run the advanced load test
run_advanced_test() {
  echo -e "\n${YELLOW}🔥 Running advanced load test...${NC}"
  docker-compose run --rm k6 run /scripts/nginx-advanced-test.js
}

# Function to open Grafana
open_grafana() {
  echo -e "\n${YELLOW}📊 Opening Grafana...${NC}"
  echo -e "${GREEN}✅ Grafana is available at: http://localhost:3000${NC}"
  echo -e "  👤 Username: admin"
  echo -e "  🔑 Password: grafana"
  echo -e "\n${YELLOW}Import the InfluxDB datasource:${NC}"
  echo -e "  URL: http://influxdb:8086"
  echo -e "  Database: k6"
  echo -e "${YELLOW}You should see the official k6 dashboard from Grafana.com (ID: 2587) in your dashboards.${NC}"
  echo -e "${YELLOW}If not, run the import script: ./import-k6-dashboard.sh${NC}"
  
  # Try to open the URL if on Mac
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open http://localhost:3000
  fi
}

# Show the menu and get user input
show_menu
while true; do
  read -p "Enter your choice [0-3]: " choice
  case $choice in
    1)
      run_basic_test
      show_menu
      ;;
    2)
      run_advanced_test
      show_menu
      ;;
    3)
      open_grafana
      show_menu
      ;;
    0)
      echo -e "${BLUE}👋 Exiting. Goodbye!${NC}"
      exit 0
      ;;
    *)
      echo -e "${YELLOW}⚠️ Invalid choice. Please enter a number between 0 and 3.${NC}"
      ;;
  esac
done
