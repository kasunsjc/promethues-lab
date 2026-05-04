#!/bin/bash
# 🔭 Prometheus Monitoring Helper Script 🚀
# This script provides common commands for managing the Prometheus monitoring stack

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Detect OS for opening URLs. Returns non-zero if no opener is found or opener fails.
open_url() {
  local url="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$url"
  elif grep -qi microsoft /proc/version 2>/dev/null && command -v wslview &> /dev/null; then
    wslview "$url"
  elif command -v xdg-open &> /dev/null; then
    xdg-open "$url"
  elif command -v wslview &> /dev/null; then
    wslview "$url"
  else
    echo -e "${YELLOW}⚠️  Cannot detect browser. Please open manually: ${url}${NC}"
    return 1
  fi
}

open_portals() {
  local failed=0
  echo -e "${BOLD}${BLUE}=== 🌐 Opening Service Portals ===${NC}"
  echo -e "  🔗 Opening Prometheus...     http://localhost:9090"
  open_url "http://localhost:9090" || failed=1
  sleep 1
  echo -e "  🔗 Opening Grafana...        http://localhost:3000"
  open_url "http://localhost:3000" || failed=1
  sleep 1
  echo -e "  🔗 Opening Alertmanager...   http://localhost:9093"
  open_url "http://localhost:9093" || failed=1
  sleep 1
  echo -e "  🔗 Opening Nginx...          http://localhost:8080"
  open_url "http://localhost:8080" || failed=1
  echo
  if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}✅ All portals opened in your default browser!${NC}"
  else
    echo -e "${YELLOW}⚠️  Some portals could not be opened automatically. Please open them manually.${NC}"
  fi
}

# Display the header
echo -e "${BOLD}${BLUE}=== 🔭 Prometheus Monitoring Stack Helper 🚀 ===${NC}"
echo -e "${YELLOW}Choose a command to run:${NC}"
echo

# Define the commands
display_menu() {
  echo -e "${BOLD}🐳 Docker Compose Management:${NC}"
  echo -e "  ${GREEN}1.${NC} ▶️  Start all services"
  echo -e "  ${GREEN}2.${NC} ⏹️  Stop all services"
  echo -e "  ${GREEN}3.${NC} 🔄 Restart all services"
  echo -e "  ${GREEN}4.${NC} 📋 View running services"
  echo -e "  ${GREEN}5.${NC} 🗑️  Delete stack and volumes"
  echo
  echo -e "${BOLD}🗄️  MySQL Operations:${NC}"
  echo -e "  ${GREEN}6.${NC} 💻 Connect to MySQL CLI"
  echo -e "  ${GREEN}7.${NC} 🔸 Generate light load (10 queries)"
  echo -e "  ${GREEN}8.${NC} 🔶 Generate medium load (100 queries)"
  echo -e "  ${GREEN}9.${NC} 🔥 Generate heavy load (1000 queries)"
  echo
  echo -e "${BOLD}📊 Logs & Monitoring:${NC}"
  echo -e "  ${GREEN}10.${NC} 📜 View MySQL logs"
  echo -e "  ${GREEN}11.${NC} 📜 View Prometheus logs"
  echo -e "  ${GREEN}12.${NC} 📜 View MySQL Exporter logs"
  echo -e "  ${GREEN}13.${NC} 📜 View Grafana logs"
  echo -e "  ${GREEN}14.${NC} 📜 View Ubuntu logs"
  echo -e "  ${GREEN}15.${NC} 📜 View Nginx logs"
  echo -e "  ${GREEN}16.${NC} 📜 View Nginx Exporter logs"
  echo
  echo -e "${BOLD}🔐 Access Information:${NC}"
  echo -e "  ${GREEN}17.${NC} 📜 View InfluxDB logs"
  echo -e "  ${GREEN}18.${NC} 🔑 Display access URLs and credentials"
  echo -e "  ${GREEN}19.${NC} 🔥 Run k6 Load Tests"
  echo -e "  ${GREEN}20.${NC} 📊 Import Official k6 Dashboard to Grafana"
  echo -e "  ${GREEN}21.${NC} 🌐 Open all service portals in browser"
  echo -e "  ${GREEN}0.${NC} 👋 Exit"
  echo
}

# Function to run a command and pause
run_command() {
  echo -e "${YELLOW}🚀 Running: ${BOLD}$1${NC}"
  eval $1
  echo
  echo -e "${GREEN}✅ Command completed!${NC}"
  pause_and_return
}

# Helper: pause for Enter, then redraw menu
pause_and_return() {
  echo -e "Press Enter to continue..."
  read
  clear
  display_menu
}

# Display the initial menu
display_menu

# Wait for user input
while true; do
  read -p "Enter your choice [0-21]: " choice
  case $choice in
    0)
      echo -e "${BLUE}👋 Exiting. Goodbye!${NC}"
      exit 0
      ;;
    1)
      echo -e "${YELLOW}🚀 Running: ${BOLD}docker-compose up -d${NC}"
      if docker-compose up -d; then
        echo
        echo -e "${GREEN}✅ Stack is up!${NC}"
        echo
        read -p "🌐 Open service portals in browser? [y/N]: " open_choice
        if [[ "$open_choice" =~ ^[Yy]$ ]]; then
          open_portals
        fi
      else
        echo
        echo -e "${RED}❌ Failed to start the stack. Please check the output above.${NC}"
      fi
      pause_and_return
      ;;
    2)
      run_command "docker-compose down"
      ;;
    3)
      run_command "docker-compose restart"
      ;;
    4)
      run_command "docker-compose ps"
      ;;
    5)
      run_command "docker-compose down -v"
      ;;
    6)
      run_command "docker exec -it mysql mysql -u mysqluser -pmysqlpassword sample_db"
      ;;
    7)
      run_command "for i in {1..10}; do docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e \"USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', \$i), FLOOR(RAND()*1000), 'This is a generated item for load testing');\"; done"
      ;;
    8)
      run_command "for i in {1..100}; do docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e \"USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', \$i), FLOOR(RAND()*1000), 'This is a generated item for load testing');\" &> /dev/null; echo -ne \"🔄 Progress: \$i/100\\r\"; done; echo"
      ;;
    9)
      run_command "for i in {1..1000}; do docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e \"USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', \$i), FLOOR(RAND()*1000), 'This is a generated item for load testing');\" &> /dev/null; if [ \$((\$i % 10)) -eq 0 ]; then echo -ne \"🔄 Progress: \$i/1000\\r\"; fi; done; echo"
      ;;
    10)
      run_command "docker logs mysql"
      ;;
    11)
      run_command "docker logs prometheus"
      ;;
    12)
      run_command "docker logs mysql-exporter"
      ;;
    13)
      run_command "docker logs grafana"
      ;;
    14)
      run_command "docker logs ubuntu"
      ;;
    15)
      run_command "docker logs nginx"
      ;;
    16)
      run_command "docker logs nginx-exporter"
      ;;
    17)
      run_command "docker logs influxdb"
      ;;
    18)
      echo -e "${BOLD}${BLUE}=== 🔐 Access Information ===${NC}"
      echo -e "${BOLD}📈 Prometheus:${NC}"
      echo -e "  🔗 URL: http://localhost:9090"
      echo
      echo -e "${BOLD}📊 Grafana:${NC}"
      echo -e "  🔗 URL: http://localhost:3000"
      echo -e "  👤 Username: admin"
      echo -e "  🔑 Password: grafana"
      echo
      echo -e "${BOLD}🗄️ MySQL:${NC}"
      echo -e "  🖥️ Host: localhost"
      echo -e "  🔌 Port: 3306"
      echo -e "  👤 Username: mysqluser"
      echo -e "  🔑 Password: mysqlpassword"
      echo -e "  📂 Database: sample_db"
      echo
      echo -e "${BOLD}📡 MySQL Exporter:${NC}"
      echo -e "  🔗 URL: http://localhost:9104/metrics"
      echo
      echo -e "${BOLD}🖥️ Ubuntu:${NC}"
      echo -e "  🔗 Node Exporter URL: http://localhost:9101/metrics"
      echo
      echo -e "${BOLD}🌐 Nginx:${NC}"
      echo -e "  🔗 URL: http://localhost:8080"
      echo
      echo -e "${BOLD}📊 Nginx Exporter:${NC}"
      echo -e "  🔗 URL: http://localhost:9113/metrics"
      echo
      echo -e "${BOLD}📦 InfluxDB:${NC}"
      echo -e "  🔗 URL: http://localhost:8086"
      echo -e "  📂 Database: k6"
      echo
      pause_and_return
      ;;
    19)
      clear
      echo -e "${BOLD}${BLUE}=== 🔥 k6 Load Testing ===${NC}"
      echo -e "${YELLOW}Choose a load test to run:${NC}"
      echo -e "  ${GREEN}1.${NC} 🔄 Basic load test (default Nginx endpoint)"
      echo -e "  ${GREEN}2.${NC} 🔥 Advanced load test (multiple endpoints, spike test)"
      echo -e "  ${GREEN}0.${NC} 🔙 Back to main menu"
      echo
      read -p "Enter your choice [0-2]: " k6_choice
      case $k6_choice in
        1)
          run_command "docker-compose run --rm k6 run /scripts/nginx-load-test.js"
          ;;
        2)
          run_command "docker-compose run --rm k6 run /scripts/nginx-advanced-test.js"
          ;;
        0)
          clear
          display_menu
          ;;
        *)
          echo -e "${YELLOW}⚠️ Invalid choice.${NC}"
          sleep 2
          clear
          display_menu
          ;;
      esac
      ;;
    20)
      run_command "./scripts/import-k6-dashboard.sh"
      ;;
    21)
      open_portals
      pause_and_return
      ;;
    *)
      echo -e "${YELLOW}⚠️ Invalid choice. Please enter a number between 0 and 21.${NC}"
      ;;
  esac
done
