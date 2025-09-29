#!/bin/bash

# --- Configuration ---

# Minecraft server directory (to be zipped)
SERVER_DIR="PLACEHOLDER_SERVER_MINECRAFT_PATH" 

# Temporary space for the zip file
TEMP_DIR="/tmp/minecraft_backups" 
DATE=$(date +%Y-%m-%d_%H%M%S)
BACKUP_FILENAME="minecraft_backup_$DATE.zip"
LOG_FILE="/var/log/minecraft_scp_backup.log"

# Remote machine (Client) details for SCP
REMOTE_USER="PLACEHOLDER_REMOTE_USERNAME" 
REMOTE_HOST="PLACEHOLDER_REMOTE_HOST_IP_OR_HOSTNAME" 
# Destination folder on the remote machine
REMOTE_PATH="/home/$REMOTE_USER/backups/minecraft/" 

# --- Functions ---

# Function to write messages to terminal and log file
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --- Script Start ---

log "--- Starting Minecraft Server Backup (SCP Push) ---"

# Check if the Minecraft directory exists
if [ ! -d "$SERVER_DIR" ]; then
    log "ERROR: Minecraft directory not found. Exiting."
    exit 1
fi

# 1. Prepare temporary directory
mkdir -p "$TEMP_DIR"

# Full path for the local zip file
ZIP_PATH="$TEMP_DIR/$BACKUP_FILENAME"

# 2. Create the ZIP archive
log "Creating ZIP archive: $BACKUP_FILENAME"
if ! zip -r -q "$ZIP_PATH" "$SERVER_DIR" &>> "$LOG_FILE"; then
    log "ERROR: ZIP creation failed."
    exit 1
fi
log "ZIP created successfully."

# 3. Upload to remote client using SCP
log "Uploading to $REMOTE_HOST"

# Requires passwordless SSH (keys)
if ! scp -o BatchMode=yes "$ZIP_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" &>> "$LOG_FILE"; then
    log "ERROR: SCP upload failed. Check keys and network."
fi
SCP_STATUS=$?

if [ $SCP_STATUS -eq 0 ]; then
    log "Upload successful."
else
    log "Upload failed with status code $SCP_STATUS."
fi

# 4. Clean up local zip file
log "Cleaning up local temporary file."
rm -f "$ZIP_PATH"

log "--- Backup Finished ---"

exit $SCP_STATUS