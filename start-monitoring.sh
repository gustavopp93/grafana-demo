#!/bin/bash

# Start Grafana Monitoring Stack
# Includes: InfluxDB, Prometheus, Loki, and Grafana

set -e

# Load environment variables if .env exists
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

echo "🚀 Starting Grafana Monitoring Stack..."
echo ""
echo "Starting services:"
echo "  - InfluxDB (k6 metrics database) on port 8086"
echo "  - Prometheus (metrics collection) on port 9090"
echo "  - Loki (log aggregation) on port 3100"
echo "  - Grafana (visualization dashboard) on port 3000"
echo ""

docker compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 15

echo ""
echo "✅ Monitoring stack is ready!"
echo ""
echo "📊 Grafana: http://localhost:3000"
echo "   Username: ${GRAFANA_ADMIN_USER:-admin}"
echo "   Password: ${GRAFANA_ADMIN_PASSWORD:-admin}"
echo ""
echo "🗄️  InfluxDB: http://localhost:8086"
echo "   Org: ${INFLUXDB_ORG:-k6-org}"
echo "   Bucket: ${INFLUXDB_BUCKET:-k6-metrics}"
echo ""
echo "📈 Prometheus: http://localhost:9090"
echo ""
echo "📝 Loki: http://localhost:3100"
echo ""
echo "Now you can run k6 tests from the k6-demo repository!"
