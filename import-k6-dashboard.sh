#!/bin/bash
# 📊 Import k6 Dashboard to Grafana

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Display header
echo -e "${BOLD}${BLUE}=== 📊 Import Official k6 Dashboard to Grafana ===${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo -e "${RED}⚠️ Docker is not running. Please start Docker first.${NC}"
  exit 1
fi

# Check if Grafana is running
if ! curl -s -I http://localhost:3000 > /dev/null 2>&1; then
  echo -e "${RED}⚠️ Grafana is not running. Please start the stack first.${NC}"
  exit 1
fi

# Check if InfluxDB is properly set up as a data source in Grafana
echo -e "${YELLOW}📊 Checking if InfluxDB datasource is configured...${NC}"
DATASOURCE_CHECK=$(curl -s -H "Content-Type: application/json" http://admin:grafana@localhost:3000/api/datasources/name/InfluxDB)
if echo "$DATASOURCE_CHECK" | grep -q "Data source not found"; then
  echo -e "${YELLOW}⚠️ InfluxDB datasource not found. Adding it now...${NC}"
  curl -s -X POST -H "Content-Type: application/json" -d '{
    "name": "InfluxDB",
    "type": "influxdb",
    "url": "http://influxdb:8086",
    "access": "proxy",
    "basicAuth": false,
    "database": "k6"
  }' http://admin:grafana@localhost:3000/api/datasources > /dev/null
  echo -e "${GREEN}✅ InfluxDB datasource added!${NC}"
else
  echo -e "${GREEN}✅ InfluxDB datasource is already configured.${NC}"
fi

# Import the dashboard
echo -e "${YELLOW}📊 Importing official k6 dashboard to Grafana...${NC}"

# Create dashboards directory if it doesn't exist
mkdir -p grafana/dashboards/k6

# Check if we already have the dashboard JSON
if [ ! -s grafana/dashboards/k6/k6-official-dashboard.json ]; then
  echo -e "${YELLOW}📊 Downloading official k6 dashboard from Grafana.com (ID: 2587)...${NC}"
  curl -s -L https://grafana.com/grafana/dashboards/2587/revisions/8/download > grafana/dashboards/k6/k6-official-dashboard.json
  
  # Check if download was successful
  if [ ! -s grafana/dashboards/k6/k6-official-dashboard.json ]; then
    echo -e "${RED}⚠️ Failed to download dashboard from Grafana.com.${NC}"
    exit 1
  else
    echo -e "${GREEN}✅ Dashboard downloaded successfully!${NC}"
  fi
else
  echo -e "${GREEN}✅ Using existing dashboard file.${NC}"
fi

# Import the dashboard directly from the file
echo -e "${YELLOW}📊 Importing k6 dashboard to Grafana from local file...${NC}"

# Create a folder first if it doesn't exist
echo -e "${YELLOW}📊 Creating dashboard folder in Grafana...${NC}"
FOLDER_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"title":"k6 Dashboards"}' http://admin:grafana@localhost:3000/api/folders)
FOLDER_ID=$(echo "$FOLDER_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$FOLDER_ID" ]; then
  echo -e "${YELLOW}⚠️ Could not create or determine folder ID. Using default folder.${NC}"
  FOLDER_ID=0
fi

# Extract the dashboard model from the downloaded file
DASHBOARD_JSON=$(cat grafana/dashboards/k6/k6-official-dashboard.json)

# Create the import payload
echo -e "${YELLOW}� Preparing dashboard for import...${NC}"
echo '{
  "dashboard": '$DASHBOARD_JSON',
  "overwrite": true,
  "folderId": '$FOLDER_ID',
  "inputs": [
    {
      "name": "DS_K6",
      "type": "datasource",
      "pluginId": "influxdb",
      "value": "InfluxDB"
    }
  ]
}' > grafana/dashboards/k6/import-payload.json

# Import the dashboard using the Grafana API
echo -e "${YELLOW}📊 Importing dashboard to Grafana...${NC}"
IMPORT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d @grafana/dashboards/k6/import-payload.json http://admin:grafana@localhost:3000/api/dashboards/import)

# Check if import was successful
if echo "$IMPORT_RESPONSE" | grep -q "success"; then
  echo -e "${GREEN}✅ Dashboard imported successfully!${NC}"
elif echo "$IMPORT_RESPONSE" | grep -q "uid"; then
  echo -e "${GREEN}✅ Dashboard imported successfully!${NC}"
  DASHBOARD_UID=$(echo "$IMPORT_RESPONSE" | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)
  echo -e "${GREEN}📊 Dashboard UID: $DASHBOARD_UID${NC}"
else
  echo -e "${RED}⚠️ Dashboard import might have failed. Response: ${NC}"
  echo "$IMPORT_RESPONSE"
fi

# Display information about accessing the dashboard
echo -e "${GREEN}✅ Dashboard import process completed!${NC}"
echo -e "${YELLOW}📊 To view the dashboard:${NC}"
echo -e "   1. Go to Grafana at: ${GREEN}http://localhost:3000${NC}"
echo -e "   2. Login with username: ${GREEN}admin${NC} and password: ${GREEN}grafana${NC}"
echo -e "   3. Navigate to Dashboards -> k6 Dashboards -> k6 Load Testing Results"

# Try to open the URL if on Mac
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo -e "${YELLOW}🔗 Attempting to open Grafana...${NC}"
  open "http://localhost:3000/dashboards"
fi
