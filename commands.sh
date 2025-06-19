#!/bin/bash
# 🚀 Common Commands for Prometheus Monitoring Stack 📊
# This file contains useful commands for managing the monitoring stack

# ---------------------
# 🐳 Docker Compose Commands
# ---------------------

# Start all services
start_all() {
    echo "▶️  Starting all services..."
    docker-compose up -d
}

# Stop all services
stop_all() {
    echo "⏹️  Stopping all services..."
    docker-compose down
}

# Delete all services including volumes
delete_stack() {
    echo "🗑️ Deleting the entire Docker Compose stack (including volumes)..."
    docker-compose down -v
    echo "✅ Stack and all associated volumes have been deleted."
}

# Restart all services
restart_all() {
    echo "🔄 Restarting all services..."
    docker-compose down && docker-compose up -d
}

# View running containers
show_services() {
    echo "📋 Showing services status..."
    docker-compose ps
}

# ---------------------
# 🗄️ MySQL Load Generation
# ---------------------

# Generate light SQL load (10 queries)
light_load() {
    echo "🔸 Generating light load (10 queries)..."
    for i in {1..10}; do
        docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', $i), FLOOR(RAND()*1000), 'This is a generated item for load testing');"
    done
    echo "✅ Load generation completed!"
}

# Generate medium SQL load (100 queries)
medium_load() {
    echo "🔶 Generating medium load (100 queries)..."
    for i in {1..100}; do
        docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', $i), FLOOR(RAND()*1000), 'This is a generated item for load testing');" &> /dev/null
        if [ $(($i % 10)) -eq 0 ]; then
            echo -ne "🔄 Progress: $i/100\r"
        fi
    done
    echo -e "\n✅ Load generation completed!"
}

# Generate heavy SQL load (1000 queries)
heavy_load() {
    echo "🔥 Generating heavy load (1000 queries)..."
    for i in {1..1000}; do
        docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; SELECT * FROM sample_table WHERE id=FLOOR(1 + RAND() * 5); INSERT INTO sample_table (name, value, description) VALUES (CONCAT('Generated Item ', $i), FLOOR(RAND()*1000), 'This is a generated item for load testing');" &> /dev/null
        if [ $(($i % 100)) -eq 0 ]; then
            echo -ne "🔄 Progress: $i/1000\r"
        fi
    done
    echo -e "\n✅ Load generation completed!"
}

# ---------------------
# 🗄️ MySQL Data Operations
# ---------------------

# Connect to MySQL CLI
mysql_cli() {
    echo "💻 Connecting to MySQL CLI..."
    docker exec -it mysql mysql -u mysqluser -pmysqlpassword sample_db
}

# Show sample table data
show_data() {
    echo "📋 Showing data in sample_table:"
    docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; SELECT * FROM sample_table LIMIT 10;"
}

# Count rows in sample table
count_rows() {
    echo "🔢 Counting rows in sample_table:"
    docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; SELECT COUNT(*) AS 'Total Rows' FROM sample_table;"
}

# Reset sample data (clear and reload)
reset_data() {
    echo "🔁 Resetting sample data..."
    docker exec -i mysql mysql -u mysqluser -pmysqlpassword -e "USE sample_db; DELETE FROM sample_table; DELETE FROM metrics_test;"
    docker exec -i mysql mysql -u mysqluser -pmysqlpassword sample_db < /Users/kasunrajapakse/Desktop/Prometheus/mysql-init/init.sql
    echo "✅ Sample data reset completed!"
}

# ---------------------
# 📊 View Service Logs
# ---------------------

# View MySQL logs
mysql_logs() {
    echo "📜 Viewing MySQL logs:"
    docker logs mysql
}

# View Prometheus logs
prometheus_logs() {
    echo "📜 Viewing Prometheus logs:"
    docker logs prometheus
}

# View MySQL Exporter logs
mysql_exporter_logs() {
    echo "📜 Viewing MySQL Exporter logs:"
    docker logs mysql-exporter
}

# View Grafana logs
grafana_logs() {
    echo "📜 Viewing Grafana logs:"
    docker logs grafana
}

# View Ubuntu logs
ubuntu_logs() {
    echo "📜 Viewing Ubuntu logs:"
    docker logs ubuntu
}

# View Nginx logs
nginx_logs() {
    echo "📜 Viewing Nginx logs:"
    docker logs nginx
}

# View Nginx Exporter logs
nginx_exporter_logs() {
    echo "📜 Viewing Nginx Exporter logs:"
    docker logs nginx-exporter
}

# View InfluxDB logs
influxdb_logs() {
    echo "📜 Viewing InfluxDB logs:"
    docker logs influxdb
}

# Run k6 basic load test
run_k6_basic() {
    echo "🔥 Running basic k6 load test on Nginx..."
    docker-compose run --rm k6 run /scripts/nginx-load-test.js
}

# Run k6 advanced load test
run_k6_advanced() {
    echo "🔥 Running advanced k6 load test on Nginx..."
    docker-compose run --rm k6 run /scripts/nginx-advanced-test.js
}

# Import k6 dashboard to Grafana
import_k6_dashboard() {
    echo "📊 Importing k6 dashboard to Grafana..."
    ./import-k6-dashboard.sh
}

# ---------------------
# 🔐 Access Information
# ---------------------

# Show access information
show_access() {
    echo "=== 🔐 Access Information ==="
    echo "📈 Prometheus:"
    echo "  🔗 URL: http://localhost:9090"
    echo
    echo "📊 Grafana:"
    echo "  🔗 URL: http://localhost:3000"
    echo "  👤 Username: admin"
    echo "  🔑 Password: grafana"
    echo
    echo "🗄️ MySQL:"
    echo "  🖥️ Host: localhost"
    echo "  🔌 Port: 3306"
    echo "  👤 Username: mysqluser"
    echo "  🔑 Password: mysqlpassword"
    echo "  📂 Database: sample_db"
    echo
    echo "📡 MySQL Exporter:"
    echo "  🔗 URL: http://localhost:9104/metrics"
    echo
    echo "🖥️ Ubuntu:"
    echo "  🔗 Node Exporter URL: http://localhost:9101/metrics"
    echo
    echo "🌐 Nginx:"
    echo "  🔗 URL: http://localhost:8080"
    echo
    echo "📊 Nginx Exporter:"
    echo "  🔗 URL: http://localhost:9113/metrics"
    echo
    echo "📦 InfluxDB:"
    echo "  🔗 URL: http://localhost:8086"
    echo "  📂 Database: k6"
}

# Display usage instructions
usage() {
    echo "📚 Usage: $0 [COMMAND]"
    echo
    echo "🛠️ Available commands:"
    echo "  start         - ▶️  Start all services"
    echo "  stop          - ⏹️  Stop all services"
    echo "  delete        - 🗑️  Delete stack and volumes"
    echo "  restart       - 🔄 Restart all services"
    echo "  status        - ℹ️  Show status of all services"
    echo "  light-load    - 🔸 Generate light SQL load (10 queries)"
    echo "  medium-load   - 🔶 Generate medium SQL load (100 queries)"
    echo "  heavy-load    - 🔥 Generate heavy SQL load (1000 queries)"
    echo "  mysql-cli     - 💻 Connect to MySQL CLI"
    echo "  show-data     - 📋 Show sample table data"
    echo "  count-rows    - 🔢 Count rows in sample table"
    echo "  reset-data    - 🔁 Reset sample data (clear and reload)"
    echo "  mysql-logs    - 📜 View MySQL logs"
    echo "  prom-logs     - 📜 View Prometheus logs"
    echo "  exporter-logs - 📜 View MySQL Exporter logs"
    echo "  grafana-logs  - 📜 View Grafana logs"
    echo "  ubuntu-logs   - 📜 View Ubuntu logs"
    echo "  nginx-logs    - 📜 View Nginx logs"
    echo "  nginx-exporter-logs - 📜 View Nginx Exporter logs"
    echo "  influxdb-logs - 📜 View InfluxDB logs"
    echo "  k6-basic      - 🔥 Run basic k6 load test"
    echo "  k6-advanced   - 🔥 Run advanced k6 load test"
    echo "  k6-dashboard  - 📊 Import k6 dashboard to Grafana"
    echo "  access        - 🔑 Show access information"
    echo "  help          - ❓ Show this help message"
    echo
    echo "🚀 Example: $0 start"
}

# Process command line arguments
case "$1" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    delete)
        delete_stack
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
    ubuntu-logs)
        ubuntu_logs
        ;;
    nginx-logs)
        nginx_logs
        ;;
    nginx-exporter-logs)
        nginx_exporter_logs
        ;;
    influxdb-logs)
        influxdb_logs
        ;;
    k6-basic)
        run_k6_basic
        ;;
    k6-advanced)
        run_k6_advanced
        ;;
    k6-dashboard)
        import_k6_dashboard
        ;;
    access)
        show_access
        ;;
    help|*)
        usage
        ;;
esac
