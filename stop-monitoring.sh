#!/bin/bash

# Stop Grafana Monitoring Stack

set -e

echo "🛑 Stopping Grafana Monitoring Stack..."
echo ""

docker compose down

echo ""
echo "✅ All services stopped!"
echo ""
echo "Note: Data is preserved in Docker volumes."
echo "To remove all data, run: docker compose down -v"
