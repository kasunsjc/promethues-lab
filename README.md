# 🔭 Prometheus Mo## 🧩 Components

- **📈 Prometheus**: Time series database for storing metrics
- **🖥️ Node Exporter**: Provides system metrics like CPU, memory, disk usage
- **🗄️ MySQL**: Sample database with test data
- **📡 MySQL Exporter**: Collects metrics from MySQL
- **📊 Grafana**: Visualizes metrics from Prometheus
- **🖥️ Ubuntu**: Simulated Ubuntu server with Node Exporter for monitoring
- **🌐 Nginx**: Web server for serving static content
- **📊 Nginx Exporter**: Collects metrics from Nginx
- **🔥 k6**: Modern load testing tool for performance testing
- **📦 InfluxDB**: Time series database for storing k6 resultsComponents

- **📈 Prometheus**: - **📡 MySQL Exporter**: [http://localhost:9104/metrics](http://localhost:9104/metrics)
- **🖥️ Ubuntu**:
  - Node Exporter metrics: [http://localhost:9101/metrics](http://localhost:9101/metrics)
- **🌐 Nginx**: series database for storing metrics
- **🖥️ Node Exporter**: Provides system metrics like CPU, memory, disk usage
- **🗄️ MySQL**: Sample database with test data
- **📡 MySQL Exporter**: Collects metrics from MySQL
- **📊 Grafana**: Visualizes metrics from Prometheus
- **🖥️ Ubuntu**: Simulated Ubuntu server with Node Exporter for monitoring
- **🌐 Nginx**: Web server for serving static content
- **📊 Nginx Exporter**: Collects metrics from Nginx Monitoring Stack �

This repository contains a Docker Compose setup for monitoring with Prometheus, Node Exporter, MySQL, MySQL Exporter, Grafana, Ubuntu, Nginx, and Nginx Exporter.

This repository contains a Docker Compose setup for monitoring with Prometheus, Node Exporter, MySQL, MySQL Exporter, Grafana, Ubuntu, Nginx, and Nginx Exporter.

## 🧩 Components

- **📈 Prometheus**: Time series database for storing metrics
- **🖥️ Node Exporter**: Provides system metrics like CPU, memory, disk usage
- **🗄️ MySQL**: Sample database with test data
- **📡 MySQL Exporter**: Collects metrics from MySQL
- **📊 Grafana**: Visualizes metrics from Prometheus
- **�️ Ubuntu**: Simulated Ubuntu server with Node Exporter for monitoring
- **🌐 Nginx**: Web server for serving static content

## 🚀 Quick Start

Start the monitoring stack:

```bash
docker-compose up -d
```

## 🔗 Access Services

- **📈 Prometheus**: [http://localhost:9090](http://localhost:9090)
- **📊 Grafana**: [http://localhost:3000](http://localhost:3000)
  - Username: admin
  - Password: grafana
- **🗄️ MySQL**:
  - Host: localhost
  - Port: 3306
  - Username: mysqluser
  - Password: mysqlpassword
  - Database: sample_db
- **📡 MySQL Exporter**: [http://localhost:9104/metrics](http://localhost:9104/metrics)
- **�️ Ubuntu**:
  - Node Exporter metrics: [http://localhost:9101/metrics](http://localhost:9101/metrics)
- **🌐 Nginx**:
  - Web server: [http://localhost:8080](http://localhost:8080)
- **📊 Nginx Exporter**:
  - Metrics: [http://localhost:9113/metrics](http://localhost:9113/metrics)
- **📦 InfluxDB**:
  - URL: [http://localhost:8086](http://localhost:8086)
  - Database: k6

## 🛠️ Helper Scripts

Two helper scripts are provided to simplify common operations:

### 🧙‍♂️ Interactive Helper

Run the interactive helper with:

```bash
./monitoring-helper.sh
```

This script provides an interactive menu for common operations.

### ⌨️ Command Line Helper

For non-interactive usage, you can use:

```bash
./commands.sh [COMMAND]
```

Available commands:

- `start` - ▶️ Start all services
- `stop` - ⏹️ Stop all services
- `restart` - 🔄 Restart all services
- `status` - ℹ️ Show status of all services
- `light-load` - 🔸 Generate light SQL load (10 queries)
- `medium-load` - 🔶 Generate medium SQL load (100 queries)
- `heavy-load` - 🔥 Generate heavy SQL load (1000 queries)
- `mysql-cli` - 💻 Connect to MySQL CLI
- `show-data` - 📋 Show sample table data
- `count-rows` - 🔢 Count rows in sample table
- `reset-data` - 🔁 Reset sample data (clear and reload)
- `mysql-logs` - 📜 View MySQL logs
- `prom-logs` - 📜 View Prometheus logs
- `exporter-logs` - 📜 View MySQL Exporter logs
- `grafana-logs` - 📜 View Grafana logs
- `ubuntu-logs` - 📜 View Ubuntu logs
- `nginx-logs` - 📜 View Nginx logs
- `nginx-exporter-logs` - 📜 View Nginx Exporter logs
- `access` - 🔑 Show access information
- `help` - ❓ Show help message

Examples:

```bash
# Start the stack
./commands.sh start

# Generate test load
./commands.sh medium-load

# Reset sample data
./commands.sh reset-data
```

## 📊 Grafana Dashboards

A pre-configured MySQL monitoring dashboard is included. You can access it in Grafana after logging in.

## � k6 Load Testing

For load testing Nginx, a k6 integration has been provided. This allows you to perform realistic load testing and visualize the results in Grafana.

### 🚀 Running Load Tests

To run load tests, use the provided script:

```bash
./k6-load-test.sh
```

This script provides options to:

1. Run a basic load test against Nginx (default endpoint)
2. Run an advanced load test (multiple endpoints, spike test)
3. View results in Grafana

### 📊 Test Scripts

Two k6 test scripts are provided in the `k6-scripts` directory:

- **nginx-load-test.js**: Basic load test with a simple ramp-up, plateau, and ramp-down pattern
- **nginx-advanced-test.js**: More complex test with multiple user scenarios, spike tests, and advanced metrics

### 📈 Viewing Results

Load test results are stored in InfluxDB and can be visualized in Grafana using the official k6 dashboard. To import the official k6 dashboard from Grafana.com into your Grafana instance, run:

```bash
./import-k6-dashboard.sh
```

This script will:

1. Download the official k6 dashboard (ID: 2587) from Grafana.com
2. Create a k6 Dashboards folder in Grafana
3. Import the dashboard with proper InfluxDB data source configuration

To view the results:

1. Go to Grafana at [http://localhost:3000](http://localhost:3000)
2. Login with username `admin` and password `grafana`
3. Navigate to Dashboards -> k6 Dashboards -> k6 Load Testing Results

## �📂 Directory Structure

- `mysql-init/`: 🗄️ SQL initialization scripts for MySQL
- `mysqld-exporter/`: 📡 Configuration for MySQL Exporter
- `grafana/`: 📊 Grafana provisioning files and dashboards
- `nginx-html/`: 🌐 HTML files for the Nginx web server
- `k6-scripts/`: 🔥 Load testing scripts for k6
- `prometheus.yml`: 📈 Prometheus configuration
