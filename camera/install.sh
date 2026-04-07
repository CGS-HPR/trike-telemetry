#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing HPR trike camera system"

# --- Dependencies ---
echo "==> Installing system dependencies"
sudo apt-get update -qq
sudo apt-get install -y ffmpeg v4l-utils

# --- go2rtc ---
echo "==> Installing go2rtc"
cd /tmp
wget -q https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_linux_arm64
chmod +x go2rtc_linux_arm64
sudo mv go2rtc_linux_arm64 /usr/local/bin/go2rtc
echo "    go2rtc version: $(go2rtc --version)"

# --- Config ---
echo "==> Deploying config"
sudo mkdir -p /opt/go2rtc
sudo cp "$SCRIPT_DIR/go2rtc.yaml" /opt/go2rtc/go2rtc.yaml

# --- Recordings directory ---
sudo mkdir -p /opt/hpr/trike1/cameras/recordings

# --- Systemd service ---
echo "==> Installing systemd service"
sudo tee /etc/systemd/system/go2rtc.service > /dev/null <<'EOF'
[Unit]
Description=go2rtc camera streaming
After=network-online.target

[Service]
ExecStart=/usr/local/bin/go2rtc -config /opt/go2rtc/go2rtc.yaml
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable go2rtc
sudo systemctl restart go2rtc

echo ""
echo "==> Done. Verify cameras are detected:"
echo "    ls -l /dev/v4l/by-path/"
echo ""
echo "==> go2rtc web UI: http://$(hostname -I | awk '{print $1}'):1984"
