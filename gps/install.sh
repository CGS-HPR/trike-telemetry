#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing HPR trike GPS telemetry system"

# --- Dependencies ---
echo "==> Installing system dependencies"
sudo apt-get update -qq
sudo apt-get install -y gpsd gpsd-clients python3-pip

echo "==> Installing Python dependencies"
pip3 install --quiet paho-mqtt gps

# --- Deploy script ---
echo "==> Deploying GPS script"
sudo mkdir -p /opt/hpr
sudo cp "$SCRIPT_DIR/hpr_gps.py" /opt/hpr/hpr_gps.py
sudo chmod +x /opt/hpr/hpr_gps.py

# --- Systemd service ---
echo "==> Installing systemd service"
sudo cp "$SCRIPT_DIR/hpr-gps.service" /etc/systemd/system/hpr-gps.service
sudo systemctl daemon-reload
sudo systemctl enable hpr-gps.service
sudo systemctl restart hpr-gps.service

echo ""
echo "==> Done. Validate:"
echo "    systemctl status hpr-gps.service"
echo "    mosquitto_sub -h 100.109.71.98 -u mqtt_hpv -P mqtt_hpv -t hpr/trike1/nav"
