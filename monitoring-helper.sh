#!/bin/bash
# Monitoring Stack Helper Script
# This script provides common commands for managing the Prometheus monitoring stack

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display the header
echo -e "${BOLD}${BLUE}=== Prometheus Monitoring Stack Helper ===${NC}"
echo -e "${YELLOW}Choose a command to run:${NC}"
echo

# Define the commands
display_menu() {
  echo -e "${BOLD}Docker Compose Management:${NC}"
  echo -e "  ${GREEN}1.${NC} Start all services"
  echo -e "  ${GREEN}2.${NC} Stop all services"
  echo -e "  ${GREEN}3.${NC} Restart all services"
  echo -e "  ${GREEN}4.${NC} View running services"
  echo
  echo -e "${BOLD}MySQL Operations:${NC}"
  echo -e "  ${GREEN}5.${NC} Connect to MySQL CLI"
  echo -e "  ${GREEN}6.${NC} Generate light load (10 queries)"
  echo -e "  ${GREEN}7.${NC} Generate medium load (100 queries)"
  echo -e "  ${GREEN}8.${NC} Generate heavy load (1000 queries)"
  echo
  echo -e "${BOLD}Logs & Monitoring:${NC}"
  echo -e "  ${GREEN}9.${NC} View MySQL logs"
  echo -e "  ${GREEN}10.${NC} View Prometheus logs"
  echo -e "  ${GREEN}11.${NC} View MySQL Exporter logs"
  echo -e "  ${GREEN}12.${NC} View Grafana logs"
  echo
  echo -e "${BOLD}Access Information:${NC}"
  echo -e "  ${GREEN}13.${NC} Display access URLs and credentials"
  echo -e "  ${GREEN}0.${NC} Exit"
  echo
}

# Function to run a command and pause
run_command() {
  echo -e "${YELLOW}Running: ${BOLD}$1${NC}"
  eval $1
  echo
  echo -e "${GREEN}Command completed!${NC}"
  echo -e "Press Enter to continue..."
  read
  clear
  display_menu
}

# Display the initial menu
display_menu

# Wait for user input
while true; do
  read -p "Enter your choice [0-13]: " choice
  case $choice in
    0)
      echo -e "${BLUE}Exiting. Goodbye!${NC}"
      exit 0
      ;;
    1)
      run_command "docker-compose up -d"
      ;;
    2)
      run_command "docker-compose down"
      ;;
    3)
      run_command "docker-compose down && docker-compose up -d"
      ;;
    4)
      run_command "docker-compose ps"
      ;;
    5)
      run_command "docker exec -it mysql mysql -u mysqluser -pmysqlpassword sample_db"
      ;;
    6)
      run_command "for i in {1..10}; do docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e \"USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', \$i), FLOOR(RAND()*1000), 'This is a generated item for load testing');\"; done"
      ;;
    7)
      run_command "for i in {1..100}; do docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e \"USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', \$i), FLOOR(RAND()*1000), 'This is a generated item for load testing');\" &> /dev/null; echo -ne \"Progress: \$i/100\\r\"; done; echo"
      ;;
    8)
      run_command "for i in {1..1000}; do docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e \"USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', \$i), FLOOR(RAND()*1000), 'This is a generated item for load testing');\" &> /dev/null; if [ \$((\$i % 10)) -eq 0 ]; then echo -ne \"Progress: \$i/1000\\r\"; fi; done; echo"
      ;;
    9)
      run_command "docker logs mysql"
      ;;
    10)
      run_command "docker logs prometheus"
      ;;
    11)
      run_command "docker logs mysql-exporter"
      ;;
    12)
      run_command "docker logs grafana"
      ;;
    13)
      echo -e "${BOLD}${BLUE}=== Access Information ===${NC}"
      echo -e "${BOLD}Prometheus:${NC}"
      echo -e "  URL: http://localhost:9090"
      echo
      echo -e "${BOLD}Grafana:${NC}"
      echo -e "  URL: http://localhost:3000"
      echo -e "  Username: admin"
      echo -e "  Password: grafana"
      echo
      echo -e "${BOLD}MySQL:${NC}"
      echo -e "  Host: localhost"
      echo -e "  Port: 3306"
      echo -e "  Username: mysqluser"
      echo -e "  Password: mysqlpassword"
      echo -e "  Database: sample_db"
      echo
      echo -e "${BOLD}MySQL Exporter:${NC}"
      echo -e "  URL: http://localhost:9104/metrics"
      echo
      echo -e "Press Enter to continue..."
      read
      clear
      display_menu
      ;;
    *)
      echo -e "${YELLOW}Invalid choice. Please enter a number between 0 and 13.${NC}"
      ;;
  esac
done
