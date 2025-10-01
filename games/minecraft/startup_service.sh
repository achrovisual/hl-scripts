#!/bin/bash

SERVICE_NAME="minecraft.service"
SYSTEMD_DIR="/etc/systemd/system"

DEFAULT_MEMORY="1024M"

if [ "$#" -lt 3 ] || [ "$#" -gt 5 ]; then
    echo "Usage: $0 <SERVER_PATH> <JAR_FILE_NAME> <USER_NAME> [MAX_MEMORY] [MIN_MEMORY]"
    echo ""
    echo "  <SERVER_PATH>: Path to the Minecraft server directory."
    echo "  <JAR_FILE_NAME>: Name of the server JAR file."
    echo "  <USER_NAME>: System user to run the service as."
    echo "  [MAX_MEMORY]: Optional. Max Java heap memory (e.g., 8192M). Default is 1024M."
    echo "  [MIN_MEMORY]: Optional. Min Java heap memory (e.g., 2048M). Default is 1024M."
    echo ""
    echo "Example 1 (Default Memory):"
    echo "  $0 /mnt/ssd/services/minecraft/server fabric-server-mc.1.20.4-loader.0.17.2-launcher.1.1.0.jar achrovisual"
    echo ""
    echo "Example 2 (Custom Memory):"
    echo "  $0 /mnt/ssd/services/minecraft/server fabric-server-mc.1.20.4-loader.0.17.2-launcher.1.1.0.jar achrovisual 8192M 2048M"
    exit 1
fi

SERVER_PATH="$1"
JAR_FILE_NAME="$2"
SERVICE_USER="$3"

if [ -n "$4" ]; then
    MAX_MEMORY="$4"
else
    MAX_MEMORY="$DEFAULT_MEMORY"
fi

if [ -n "$5" ]; then
    MIN_MEMORY="$5"
else
    MIN_MEMORY="$DEFAULT_MEMORY"
fi

echo "Configuration Summary:"
echo "  Server Path: $SERVER_PATH"
echo "  JAR File: $JAR_FILE_NAME"
echo "  Service User: $SERVICE_USER"
echo "  Max Memory (-Xmx): $MAX_MEMORY"
echo "  Min Memory (-Xms): $MIN_MEMORY"
echo "------------------------------------------------------------------------"

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