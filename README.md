# 🔭 Prometheus Monitoring Stack

![Quick Validation](https://github.com/kasunsjc/promethues-lab/actions/workflows/quick-validate.yml/badge.svg)
![Full Stack Test](https://github.com/kasunsjc/promethues-lab/actions/workflows/validate-demos.yml/badge.svg)
![Alert System Test](https://github.com/kasunsjc/promethues-lab/actions/workflows/test-alerts.yml/badge.svg)
![Load Test Validation](https://github.com/kasunsjc/promethues-lab/actions/workflows/load-test-validation.yml/badge.svg)

This repository contains a comprehensive Docker Compose setup for monitoring with Prometheus, Alertmanager, Grafana, and various exporters including k6 load testing integration.

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
- **� Alertmanager**: [http://localhost:9093](http://localhost:9093)
- **�📊 Grafana**: [http://localhost:3000](http://localhost:3000)
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
- `delete` - 🗑️ Delete stack and volumes
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
./scripts/import-k6-dashboard.sh
```

This script will:

1. Download the official k6 dashboard (ID: 2587) from Grafana.com
2. Create a k6 Dashboards folder in Grafana
3. Import the dashboard with proper InfluxDB data source configuration

To view the results:

1. Go to Grafana at [http://localhost:3000](http://localhost:3000)
2. Login with username `admin` and password `grafana`
3. Navigate to Dashboards -> k6 Dashboards -> k6 Load Testing Results

## 📂 Directory Structure

- `config/`: ⚙️ Configuration files (prometheus.yml, alertmanager.yml, alert rules)
- `scripts/`: 🛠️ Helper scripts for validation, testing, and monitoring operations
- `mysql-init/`: 🗄️ SQL initialization scripts for MySQL
- `mysqld-exporter/`: 📡 Configuration for MySQL Exporter
- `grafana/`: 📊 Grafana provisioning files and dashboards
- `nginx-html/`: 🌐 HTML files for the Nginx web server
- `k6-scripts/`: 🔥 Load testing scripts for k6
- `.github/workflows/`: 🤖 CI/CD workflows for automated validation

## 🚨 Alertmanager & Alert Rules

### Overview
Alertmanager handles alerts sent by Prometheus server. It takes care of deduplicating, grouping, and routing them to the correct receiver integrations such as email, PagerDuty, or chat platforms.

### Configuration Files

- **`alertmanager.yml`**: Main Alertmanager configuration file
  - Defines routing rules for different types of alerts
  - Configures receivers (email, webhook, etc.)
  - Sets up inhibition rules to suppress redundant alerts

- **`alert_rules.yml`**: Prometheus alert rules
  - Defines when alerts should be triggered
  - Includes rules for system metrics, MySQL, and Nginx monitoring
  - Customizable thresholds and conditions

### Available Alert Rules

#### System Alerts
- **InstanceDown**: Triggered when any monitored instance is down
- **HighCpuUsage**: CPU usage above 80% for 2 minutes
- **HighMemoryUsage**: Memory usage above 85% for 2 minutes
- **DiskSpaceLow**: Disk space below 10%

#### MySQL Alerts
- **MySQLDown**: MySQL service is unavailable
- **MySQLTooManyConnections**: Connection usage above 80% of max
- **MySQLSlowQueries**: Slow queries detected

#### Nginx Alerts
- **NginxDown**: Nginx service is unavailable
- **NginxHighRequestRate**: Request rate above 100/second
- **NginxHighErrorRate**: Error rate above 10%

### Testing Alerts

1. **Start the webhook receiver** (for testing):
   ```bash
   python3 scripts/webhook_receiver.py
   ```

2. **Trigger test alerts** by stopping services:
   ```bash
   docker-compose stop mysql
   # Wait a minute for alert to trigger
   ```

3. **View alerts in Alertmanager UI**: [http://localhost:9093](http://localhost:9093)

4. **Check webhook logs** to see alert notifications

### Customizing Alerts

#### Modifying Alert Rules
Edit `alert_rules.yml` to:
- Change alert thresholds
- Add new alert conditions
- Modify alert labels and annotations

#### Configuring Notifications
Edit `alertmanager.yml` to:
- Add email recipients
- Configure Slack/Discord webhooks
- Set up PagerDuty integration
- Customize routing rules

#### Example: Adding Slack Integration
```yaml
receivers:
  - name: 'slack-alerts'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts'
        title: 'Alert: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

### Silencing Alerts
Use the Alertmanager UI to:
- Temporarily silence specific alerts
- Create silence rules based on labels
- Manage active and expired silences

After making changes to configuration files, restart the services:
```bash
docker-compose restart prometheus alertmanager
```

## 🚀 GitHub Actions Validation

This repository includes comprehensive GitHub Actions workflows to validate the monitoring stack:

### 🔄 Continuous Integration Workflows

#### **Quick Validation** (`quick-validate.yml`)
- **Triggers**: Every push and pull request
- **Duration**: ~2 minutes
- **Validates**: 
  - Docker Compose configuration
  - Prometheus configuration syntax
  - Alert rules syntax
  - Alertmanager configuration
  - Shell script syntax
  - Python script syntax

#### **Full Stack Validation** (`validate-demos.yml`)
- **Triggers**: Push to main/develop, PRs to main, manual trigger, daily schedule
- **Duration**: ~15 minutes
- **Tests**:
  - Complete stack deployment
  - Service health checks
  - Metrics collection verification
  - End-to-end alerting pipeline
  - k6 load testing functionality
  - Grafana dashboard accessibility
  - Helper script functionality
  - Security scanning
  - Documentation checks

#### **Alert System Test** (`test-alerts.yml`)
- **Triggers**: Daily schedule, manual trigger
- **Duration**: ~10 minutes
- **Tests**:
  - MySQLDown alert triggering and resolution
  - InstanceDown alert triggering
  - Webhook notification delivery
  - Alert routing to correct receivers
  - Complete alerting pipeline validation

#### **Load Test Validation** (`load-test-validation.yml`)
- **Triggers**: Weekly schedule, manual trigger
- **Duration**: ~8 minutes
- **Tests**:
  - k6 load testing scripts
  - InfluxDB integration
  - Nginx performance under load
  - Load-induced alert triggering
  - Metrics collection during load tests

### 📊 Status Badges

The status badges at the top of this README show the current validation status of the monitoring stack across different workflows.

### 🔧 Manual Workflow Triggers

You can manually trigger workflows from the GitHub Actions tab:

1. **Full Stack Validation**: Test the complete monitoring setup
2. **Alert System Test**: Validate alerting with custom duration
3. **Load Test Validation**: Run load tests with different intensities

### 📋 Workflow Artifacts

Each workflow generates artifacts for debugging:

- **Alert Test Results**: Alert logs and webhook activity
- **Load Test Reports**: Performance metrics and test summaries
- **Security Scan Results**: Vulnerability assessments

### 🛠️ Local Development

Before pushing changes, you can validate locally:

```bash
# Validate configurations
docker compose config --quiet
docker run --rm -v "$(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml" prom/prometheus:latest promtool check config /etc/prometheus/prometheus.yml
docker run --rm -v "$(pwd)/alertmanager.yml:/etc/alertmanager/alertmanager.yml" prom/alertmanager:latest amtool check-config /etc/alertmanager/alertmanager.yml

# Test shell scripts
bash -n *.sh

# Test Python syntax
python3 -m py_compile scripts/webhook_receiver.py
```

The workflows ensure that:
- All configurations are syntactically correct
- Services start and communicate properly
- Alerts trigger and route correctly
- Load testing works as expected
- Security best practices are followed
- Documentation stays up to date

This provides confidence that the monitoring stack will work reliably in any environment! 🎯
