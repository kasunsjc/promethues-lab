#!/bin/bash
# Common Commands for Prometheus Monitoring Stack
# This file contains useful commands for managing the monitoring stack

# ---------------------
# Docker Compose Commands
# ---------------------

# Start all services
start_all() {
    echo "Starting all services..."
    docker-compose up -d
}

# Stop all services
stop_all() {
    echo "Stopping all services..."
    docker-compose down
}

# Restart all services
restart_all() {
    echo "Restarting all services..."
    docker-compose down && docker-compose up -d
}

# View running containers
show_services() {
    docker-compose ps
}

# ---------------------
# MySQL Load Generation
# ---------------------

# Generate light SQL load (10 queries)
light_load() {
    echo "Generating light load (10 queries)..."
    for i in {1..10}; do
        docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', $i), FLOOR(RAND()*1000), 'This is a generated item for load testing');"
    done
    echo "Load generation completed!"
}

# Generate medium SQL load (100 queries)
medium_load() {
    echo "Generating medium load (100 queries)..."
    for i in {1..100}; do
        docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', $i), FLOOR(RAND()*1000), 'This is a generated item for load testing');" &> /dev/null
        if [ $(($i % 10)) -eq 0 ]; then
            echo -ne "Progress: $i/100\r"
        fi
    done
    echo -e "\nLoad generation completed!"
}

# Generate heavy SQL load (1000 queries)
heavy_load() {
    echo "Generating heavy load (1000 queries)..."
    for i in {1..1000}; do
        docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', $i), FLOOR(RAND()*1000), 'This is a generated item for load testing');" &> /dev/null
        if [ $(($i % 100)) -eq 0 ]; then
            echo -ne "Progress: $i/1000\r"
        fi
    done
    echo -e "\nLoad generation completed!"
}

# ---------------------
# MySQL Data Operations
# ---------------------

# Connect to MySQL CLI
mysql_cli() {
    docker exec -it mysql mysql -u mysqluser -pmysqlpassword sample_db
}

# Show sample table data
show_data() {
    echo "Showing data in sample_table:"
    docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; SELECT * FROM sample_table LIMIT 10;"
}

# Count rows in sample table
count_rows() {
    echo "Counting rows in sample_table:"
    docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; SELECT COUNT(*) AS 'Total Rows' FROM sample_table;"
}

# Reset sample data (clear and reload)
reset_data() {
    echo "Resetting sample data..."
    docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; DELETE FROM sample_table; DELETE FROM metrics_test;"
    docker exec -i mysql mysql -u mysqluser -pmysqlpassword sample_db < /Users/kasunrajapakse/Desktop/Prometheus/mysql-init/init.sql
    echo "Sample data reset completed!"
}

# ---------------------
# View Service Logs
# ---------------------

# View MySQL logs
mysql_logs() {
    docker logs mysql
}

# View Prometheus logs
prometheus_logs() {
    docker logs prometheus
}

# View MySQL Exporter logs
mysql_exporter_logs() {
    docker logs mysql-exporter
}

# View Grafana logs
grafana_logs() {
    docker logs grafana
}

# ---------------------
# Access Information
# ---------------------

# Show access information
show_access() {
    echo "=== Access Information ==="
    echo "Prometheus:"
    echo "  URL: http://localhost:9090"
    echo
    echo "Grafana:"
    echo "  URL: http://localhost:3000"
    echo "  Username: admin"
    echo "  Password: grafana"
    echo
    echo "MySQL:"
    echo "  Host: localhost"
    echo "  Port: 3306"
    echo "  Username: mysqluser"
    echo "  Password: mysqlpassword"
    echo "  Database: sample_db"
    echo
    echo "MySQL Exporter:"
    echo "  URL: http://localhost:9104/metrics"
}

# Display usage instructions
usage() {
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Available commands:"
    echo "  start         - Start all services"
    echo "  stop          - Stop all services"
    echo "  restart       - Restart all services"
    echo "  status        - Show status of all services"
    echo "  light-load    - Generate light SQL load (10 queries)"
    echo "  medium-load   - Generate medium SQL load (100 queries)"
    echo "  heavy-load    - Generate heavy SQL load (1000 queries)"
    echo "  mysql-cli     - Connect to MySQL CLI"
    echo "  show-data     - Show sample table data"
    echo "  count-rows    - Count rows in sample table"
    echo "  reset-data    - Reset sample data (clear and reload)"
    echo "  mysql-logs    - View MySQL logs"
    echo "  prom-logs     - View Prometheus logs"
    echo "  exporter-logs - View MySQL Exporter logs"
    echo "  grafana-logs  - View Grafana logs"
    echo "  access        - Show access information"
    echo "  help          - Show this help message"
    echo
    echo "Example: $0 start"
}

# Process command line arguments
case "$1" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    status)
        show_services
        ;;
    light-load)
        light_load
        ;;
    medium-load)
        medium_load
        ;;
    heavy-load)
        heavy_load
        ;;
    mysql-cli)
        mysql_cli
        ;;
    show-data)
        show_data
        ;;
    count-rows)
        count_rows
        ;;
    reset-data)
        reset_data
        ;;
    mysql-logs)
        mysql_logs
        ;;
    prom-logs)
        prometheus_logs
        ;;
    exporter-logs)
        mysql_exporter_logs
        ;;
    grafana-logs)
        grafana_logs
        ;;
    access)
        show_access
        ;;
    help|*)
        usage
        ;;
esac
