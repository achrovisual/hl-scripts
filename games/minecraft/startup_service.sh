#!/bin/bash

SERVICE_NAME="minecraft.service"
SYSTEMD_DIR="/etc/systemd/system"
MAX_MEMORY="8192M"
MIN_MEMORY="2048M"

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <SERVER_PATH> <JAR_FILE_NAME> <USER_NAME>"
    echo ""
    echo "Example:"
    echo "  $0 /mnt/ssd/services/minecraft/server fabric-server-mc.1.20.4-loader.0.17.2-launcher.1.1.0.jar achrovisual"
    exit 1
fi

SERVER_PATH="$1"
JAR_FILE_NAME="$2"
SERVICE_USER="$3"

SERVICE_CONTENT=$(cat << EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=$SERVICE_USER
WorkingDirectory=$SERVER_PATH
ExecStart=/usr/bin/java -Xmx$MAX_MEMORY -Xms$MIN_MEMORY -jar $JAR_FILE_NAME nogui
Restart=always
RestartSec=10
ProtectSystem=full
ProtectHome=true
PrivateDevices=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
)

echo "========================================================================"
echo "Systemd Service File Content Generated for $SERVICE_NAME:"
echo "========================================================================"
echo "$SERVICE_CONTENT"
echo "========================================================================"
echo ""
echo "To install the service on your system, follow these steps:"
echo ""
echo "1. Save the content above into the systemd directory (requires sudo):"
echo "   sudo tee $SYSTEMD_DIR/$SERVICE_NAME <<< \"$SERVICE_CONTENT\""
echo ""
echo "2. Reload the systemd daemon to recognize the new file:"
echo "   sudo systemctl daemon-reload"
echo ""
echo "3. Enable the service to start automatically at boot and start it now:"
echo "   sudo systemctl enable $SERVICE_NAME"
echo "   sudo systemctl start $SERVICE_NAME"
echo ""
echo "4. Check the server status and monitor logs:"
echo "   sudo systemctl status $SERVICE_NAME"
echo "   journalctl -u $SERVICE_NAME -f"
